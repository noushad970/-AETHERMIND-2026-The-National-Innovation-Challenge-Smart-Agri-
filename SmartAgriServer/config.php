<?php
/**
 * Smart Agri Backend Configuration
 * 
 * Keep this file on your server inside public_html/SmartAgriServer/
 * All sensitive API keys and secrets stay securely on this server
 * and are never exposed to the public or client APK/AAB files.
 */

// Prevent direct execution outside app
if (!defined('SMART_AGRI_APP')) {
    define('SMART_AGRI_APP', true);
}

// Timezone (Bangladesh Standard Time UTC+6)
date_default_timezone_set('Asia/Dhaka');

return [
    // App Environment
    'app_name' => 'Smart Agri Backend',
    'app_version' => '1.0.4',
    'app_env' => 'production', // 'development' or 'production'

    // Server-Side Secret Key to authenticate requests from Smart Agri Flutter App
    // The mobile app will send this in the 'X-SmartAgri-Secret' or 'Authorization: Bearer' header
    'app_secret' => getenv('SMART_AGRI_SECRET') ?: '',

    // Google Gemini API Configuration (KEPT 100% SECURE ON SERVER)
    // Priority order: 1. Environment Variable 2. Configured key below
    'gemini' => [
        'api_key' => getenv('GEMINI_API_KEY') ?: '',
        'primary_model' => 'gemini-2.5-flash',
        // Fallback chain in case of model quotas or transient errors
        'fallback_models' => [
            'gemini-2.5-flash',
            'gemini-1.5-flash',
            'gemini-1.5-pro',
        ],
        'temperature' => 0.2,
        'max_tokens' => 2048,
    ],

    // Crop Disease Upload Limitation Rules
    'disease_limits' => [
        // One user can daily upload a maximum of 2 images of crops disease
        'max_scans_per_user_per_day' => 2,
        'max_file_size_bytes' => 10 * 1024 * 1024, // 10 MB
        'allowed_mime_types' => [
            'image/jpeg',
            'image/jpg',
            'image/png',
            'image/webp',
        ],
    ],

    // Database Configuration
    // Defaults to SQLite which works out-of-the-box on cPanel with 0 configuration!
    'database' => [
        'type' => 'sqlite', // 'sqlite' or 'mysql'
        'sqlite_path' => __DIR__ . '/storage/smartagri.db',

        // If you ever want to connect to MySQL in cPanel, change 'type' to 'mysql' and fill these:
        'mysql' => [
            'host' => 'localhost',
            'database' => 'your_database',
            'username' => 'your_db_user',
            'password' => '',
            'charset' => 'utf8mb4',
        ],
    ],

    // Storage Paths
    'storage' => [
        'base' => __DIR__ . '/storage',
        'uploads' => __DIR__ . '/storage/uploads',
    ],

    // Rate Limiting & Security
    'security' => [
        'ip_rate_limit_per_minute' => 60,
        'enforce_auth_header' => true,
    ],
];
