<?php
/**
 * Smart Agri Master Front Controller & REST API Router
 * 
 * Target: public_html/SmartAgriServer on cPanel Apache / LiteSpeed
 */

define('SMART_AGRI_APP', true);

// Set default headers
header('Content-Type: application/json; charset=UTF-8');

// Load configurations
$config = require __DIR__ . '/config.php';

// Include components
require_once __DIR__ . '/models/Database.php';
require_once __DIR__ . '/middleware/SecurityHeaders.php';
require_once __DIR__ . '/middleware/AuthMiddleware.php';
require_once __DIR__ . '/controllers/DiseaseController.php';
require_once __DIR__ . '/controllers/ChatController.php';
require_once __DIR__ . '/controllers/SyncController.php';

// Apply security headers & handle preflight OPTIONS
SecurityHeaders::apply();

// Initialize database
Database::init($config);

// Extract path
$requestUri = $_SERVER['REQUEST_URI'] ?? '/';
$parsedPath = parse_url($requestUri, PHP_URL_PATH);

// Normalize path: strip folder prefixes like /SmartAgriServer/ or /public_html/SmartAgriServer/
$scriptName = dirname($_SERVER['SCRIPT_NAME'] ?? '');
if ($scriptName !== '/' && str_starts_with($parsedPath, $scriptName)) {
    $parsedPath = substr($parsedPath, strlen($scriptName));
}
$path = trim($parsedPath, '/');

// Strip leading 'api/' if present
if (str_starts_with($path, 'api/')) {
    $path = substr($path, 4);
} elseif ($path === 'api') {
    $path = '';
}

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

// Route Dispatcher
try {
    // 1. Healthcheck (public endpoint, no auth required)
    if ($path === '' || $path === 'health' || $path === 'status') {
        $dbConnected = false;
        try {
            Database::getConnection();
            $dbConnected = true;
        } catch (Exception $e) {
            $dbConnected = false;
        }

        echo json_encode([
            'success' => true,
            'app' => $config['app_name'],
            'version' => $config['app_version'],
            'status' => 'operational',
            'server_time' => date('Y-m-d H:i:s T'),
            'database_connected' => $dbConnected,
            'features' => [
                'disease_detection' => true,
                'daily_limit_per_user' => (int)($config['disease_limits']['max_scans_per_user_per_day'] ?? 2),
                'sequential_steps_output' => true,
                'bilingual_support' => 'English & Bangla',
                'ai_chatbot' => true,
                'local_sync' => true,
            ],
            'message' => 'Smart Agri dedicated backend server is running smoothly!',
            'message_bn' => 'স্মার্ট এগ্রি ডেডিকেটেড ব্যাকএন্ড সার্ভার সক্রিয় রয়েছে।',
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 2. Authenticate all protected API routes
    $auth = AuthMiddleware::authenticate($config);

    // 3. Protected Routes
    switch ($path) {
        // Crop Disease Detection (Enforces 2 daily scans limitation)
        case 'disease/detect':
            if ($method !== 'POST') {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method Not Allowed. Use POST.'], JSON_UNESCAPED_UNICODE);
                exit();
            }
            $controller = new DiseaseController($config);
            $controller->detect($auth);
            break;

        case 'disease/limit-status':
            $controller = new DiseaseController($config);
            $controller->getLimitStatus($auth);
            break;

        case 'disease/history':
            $controller = new DiseaseController($config);
            $controller->getHistory($auth);
            break;

        // Farmer Chatbot
        case 'chat':
            if ($method !== 'POST') {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method Not Allowed. Use POST.'], JSON_UNESCAPED_UNICODE);
                exit();
            }
            $controller = new ChatController($config);
            $controller->reply($auth);
            break;

        // Offline / Hive data sync
        case 'sync':
            if ($method !== 'POST') {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method Not Allowed. Use POST.'], JSON_UNESCAPED_UNICODE);
                exit();
            }
            $controller = new SyncController($config);
            $controller->sync($auth);
            break;

        case 'sync/fetch':
            $controller = new SyncController($config);
            $controller->fetch($auth);
            break;

        default:
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'error_code' => 'ENDPOINT_NOT_FOUND',
                'message' => "Endpoint not found: {$path}",
                'available_endpoints' => [
                    'GET  /api/health',
                    'POST /api/disease/detect',
                    'GET  /api/disease/limit-status',
                    'GET  /api/disease/history',
                    'POST /api/chat',
                    'POST /api/sync',
                    'GET  /api/sync/fetch',
                ]
            ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
            break;
    }
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error_code' => 'INTERNAL_SERVER_ERROR',
        'message' => $e->getMessage(),
        'file' => basename($e->getFile()),
        'line' => $e->getLine(),
    ], JSON_UNESCAPED_UNICODE);
}
