<?php
/**
 * Data Synchronization Controller
 * Provides REST endpoint for offline Hive data syncing to the dedicated server.
 */

class SyncController {
    private array $config;
    private PDO $db;

    public function __construct(array $config) {
        $this->config = $config;
        $this->db = Database::getConnection();
    }

    /**
     * POST /api/sync
     * Input: { collection: "crops", records: [ { id: "1", ... }, ... ] }
     */
    public function sync(array $auth): void {
        $input = json_decode(file_get_contents('php://input'), true);
        $userId = $auth['user_id'];
        $collection = trim($input['collection'] ?? 'general');
        $records = $input['records'] ?? [];

        if (!is_array($records)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Records must be an array.',
            ], JSON_UNESCAPED_UNICODE);
            return;
        }

        $now = date('Y-m-d H:i:s');
        $savedCount = 0;

        $stmt = $this->db->prepare("
            INSERT INTO app_records (user_id, collection_name, record_id, payload, updated_at)
            VALUES (:user_id, :collection_name, :record_id, :payload, :updated_at)
            ON CONFLICT(user_id, collection_name, record_id) DO UPDATE SET
                payload = :payload,
                updated_at = :updated_at
        ");

        foreach ($records as $r) {
            $recordId = (string)($r['id'] ?? uniqid('rec_'));
            try {
                $stmt->execute([
                    ':user_id' => $userId,
                    ':collection_name' => $collection,
                    ':record_id' => $recordId,
                    ':payload' => json_encode($r, JSON_UNESCAPED_UNICODE),
                    ':updated_at' => $now,
                ]);
                $savedCount++;
            } catch (Exception $e) {
                error_log("[Sync Error] " . $e->getMessage());
            }
        }

        echo json_encode([
            'success' => true,
            'collection' => $collection,
            'saved_count' => $savedCount,
            'timestamp' => $now,
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * GET /api/sync/fetch?collection=...
     */
    public function fetch(array $auth): void {
        $userId = $auth['user_id'];
        $collection = trim($_GET['collection'] ?? 'general');

        $stmt = $this->db->prepare('
            SELECT record_id, payload, updated_at 
            FROM app_records 
            WHERE user_id = :u AND collection_name = :c
            ORDER BY updated_at DESC
        ');
        $stmt->execute([':u' => $userId, ':c' => $collection]);
        $rows = $stmt->fetchAll();

        $records = [];
        foreach ($rows as $row) {
            $decoded = json_decode($row['payload'], true);
            if ($decoded !== null) {
                $records[] = $decoded;
            }
        }

        echo json_encode([
            'success' => true,
            'collection' => $collection,
            'count' => count($records),
            'records' => $records,
        ], JSON_UNESCAPED_UNICODE);
    }
}
