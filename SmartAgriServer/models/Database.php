<?php
/**
 * Smart Agri Database Manager
 * Supports SQLite (default, zero-configuration on cPanel) and MySQL.
 * Automatically provisions tables on first launch.
 */

class Database {
    private static ?PDO $instance = null;
    private static array $config = [];

    public static function init(array $config): void {
        self::$config = $config;
    }

    public static function getConnection(): PDO {
        if (self::$instance !== null) {
            return self::$instance;
        }

        $dbConfig = self::$config['database'] ?? [];
        $type = $dbConfig['type'] ?? 'sqlite';

        if ($type === 'mysql') {
            $mysql = $dbConfig['mysql'] ?? [];
            $dsn = sprintf(
                'mysql:host=%s;dbname=%s;charset=%s',
                $mysql['host'] ?? 'localhost',
                $mysql['database'] ?? '',
                $mysql['charset'] ?? 'utf8mb4'
            );
            $user = $mysql['username'] ?? '';
            $pass = $mysql['password'] ?? '';
            $pdo = new PDO($dsn, $user, $pass, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
        } else {
            // Default: SQLite file-based database
            $dbPath = $dbConfig['sqlite_path'] ?? (__DIR__ . '/../storage/smartagri.db');
            $dir = dirname($dbPath);
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
            }
            $pdo = new PDO('sqlite:' . $dbPath);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
            // Enable WAL mode for concurrent write performance
            $pdo->exec('PRAGMA journal_mode = WAL;');
        }

        self::$instance = $pdo;
        self::migrateIfNeeded($pdo, $type);
        return self::$instance;
    }

    private static function migrateIfNeeded(PDO $pdo, string $type): void {
        try {
            if ($type === 'sqlite') {
                // Disease scans table (tracks daily limitation: 2 per user per day)
                $pdo->exec("
                    CREATE TABLE IF NOT EXISTS disease_scans (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        user_id TEXT NOT NULL,
                        scan_date TEXT NOT NULL,
                        image_hash TEXT,
                        crop_name_en TEXT,
                        crop_name_bn TEXT,
                        disease_name_en TEXT NOT NULL,
                        disease_name_bn TEXT NOT NULL,
                        confidence REAL DEFAULT 0.0,
                        severity TEXT,
                        symptoms_steps TEXT,
                        treatment_steps TEXT,
                        prevention_steps TEXT,
                        medicines TEXT,
                        raw_response TEXT,
                        client_ip TEXT,
                        created_at TEXT NOT NULL
                    );
                    CREATE INDEX IF NOT EXISTS idx_user_date ON disease_scans (user_id, scan_date);
                ");

                // Users registry & device token tracking
                $pdo->exec("
                    CREATE TABLE IF NOT EXISTS users (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        user_id TEXT UNIQUE NOT NULL,
                        device_id TEXT,
                        client_ip TEXT,
                        total_scans INTEGER DEFAULT 0,
                        created_at TEXT NOT NULL,
                        last_active_at TEXT NOT NULL
                    );
                ");

                // Farmer Chat logs
                $pdo->exec("
                    CREATE TABLE IF NOT EXISTS chat_logs (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        user_id TEXT NOT NULL,
                        prompt TEXT NOT NULL,
                        reply TEXT NOT NULL,
                        model_used TEXT,
                        created_at TEXT NOT NULL
                    );
                    CREATE INDEX IF NOT EXISTS idx_chat_user ON chat_logs (user_id);
                ");

                // Offline-to-Server Sync storage table
                $pdo->exec("
                    CREATE TABLE IF NOT EXISTS app_records (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        user_id TEXT NOT NULL,
                        collection_name TEXT NOT NULL,
                        record_id TEXT NOT NULL,
                        payload TEXT NOT NULL,
                        updated_at TEXT NOT NULL,
                        UNIQUE(user_id, collection_name, record_id)
                    );
                ");
            } else {
                // MySQL tables
                $pdo->exec("
                    CREATE TABLE IF NOT EXISTS disease_scans (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        user_id VARCHAR(128) NOT NULL,
                        scan_date DATE NOT NULL,
                        image_hash VARCHAR(64),
                        crop_name_en VARCHAR(100),
                        crop_name_bn VARCHAR(100),
                        disease_name_en VARCHAR(200) NOT NULL,
                        disease_name_bn VARCHAR(200) NOT NULL,
                        confidence FLOAT DEFAULT 0.0,
                        severity VARCHAR(50),
                        symptoms_steps MEDIUMTEXT,
                        treatment_steps MEDIUMTEXT,
                        prevention_steps MEDIUMTEXT,
                        medicines MEDIUMTEXT,
                        raw_response MEDIUMTEXT,
                        client_ip VARCHAR(45),
                        created_at DATETIME NOT NULL,
                        INDEX idx_user_date (user_id, scan_date)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
                ");

                $pdo->exec("
                    CREATE TABLE IF NOT EXISTS users (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        user_id VARCHAR(128) UNIQUE NOT NULL,
                        device_id VARCHAR(128),
                        client_ip VARCHAR(45),
                        total_scans INT DEFAULT 0,
                        created_at DATETIME NOT NULL,
                        last_active_at DATETIME NOT NULL
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
                ");

                $pdo->exec("
                    CREATE TABLE IF NOT EXISTS chat_logs (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        user_id VARCHAR(128) NOT NULL,
                        prompt MEDIUMTEXT NOT NULL,
                        reply MEDIUMTEXT NOT NULL,
                        model_used VARCHAR(64),
                        created_at DATETIME NOT NULL,
                        INDEX idx_chat_user (user_id)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
                ");

                $pdo->exec("
                    CREATE TABLE IF NOT EXISTS app_records (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        user_id VARCHAR(128) NOT NULL,
                        collection_name VARCHAR(64) NOT NULL,
                        record_id VARCHAR(128) NOT NULL,
                        payload LONGTEXT NOT NULL,
                        updated_at DATETIME NOT NULL,
                        UNIQUE KEY uq_record (user_id, collection_name, record_id)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
                ");
            }
        } catch (Exception $e) {
            error_log("[Database Migration Error] " . $e->getMessage());
        }
    }
}
