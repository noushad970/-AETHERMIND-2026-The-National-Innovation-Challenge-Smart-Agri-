<?php
/**
 * Smart Agri Server Diagnostic & Self-Test Utility
 * 
 * Open this in your browser after uploading to cPanel:
 * https://yourdomain.com/SmartAgriServer/test_api.php
 */

define('SMART_AGRI_APP', true);
header('Content-Type: text/html; charset=UTF-8');

$config = require __DIR__ . '/config.php';
require_once __DIR__ . '/models/Database.php';

$phpVersion = PHP_VERSION;
$curlAvailable = extension_loaded('curl');
$pdoSqliteAvailable = extension_loaded('pdo_sqlite');
$storageWritable = is_writable(__DIR__ . '/storage');

$dbStatus = 'Not Connected';
$dbError = '';
try {
    Database::init($config);
    $pdo = Database::getConnection();
    $stmt = $pdo->query('SELECT COUNT(*) as cnt FROM disease_scans');
    $row = $stmt->fetch();
    $dbStatus = 'Connected & Operational (Total scans: ' . ($row['cnt'] ?? 0) . ')';
} catch (Exception $e) {
    $dbError = $e->getMessage();
}

$apiKeyPresent = !empty($config['gemini']['api_key']);
// Never echo any part of the key: this page is publicly reachable.
$apiKeyMasked = $apiKeyPresent ? 'Configured' : 'Missing';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Smart Agri Backend Status</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #f0fdf4; color: #1e293b; margin: 0; padding: 24px; }
        .card { max-width: 720px; margin: 0 auto; background: #ffffff; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); padding: 32px; border: 1px solid #bbf7d0; }
        h1 { color: #166534; margin-top: 0; display: flex; align-items: center; gap: 10px; font-size: 24px; }
        .badge { display: inline-block; padding: 4px 10px; border-radius: 9999px; font-size: 13px; font-weight: bold; }
        .badge-success { background: #dcfce7; color: #15803d; }
        .badge-danger { background: #fee2e2; color: #b91c1c; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #f1f5f9; }
        th { color: #475569; font-weight: 600; width: 35%; }
        code { background: #f1f5f9; padding: 2px 6px; border-radius: 4px; font-family: monospace; font-size: 13px; color: #0f172a; }
        .endpoint-box { background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 16px; margin-top: 24px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>🌾 Smart Agri Backend Diagnostics</h1>
        <p>This page confirms your dedicated cPanel backend server is online, secure, and ready for the mobile app.</p>

        <table>
            <tr>
                <th>PHP Version</th>
                <td><code><?= htmlspecialchars($phpVersion) ?></code> (PHP 7.4+ or 8.x recommended)</td>
            </tr>
            <tr>
                <th>cURL Extension</th>
                <td>
                    <?php if ($curlAvailable): ?>
                        <span class="badge badge-success">✓ Enabled</span>
                    <?php else: ?>
                        <span class="badge badge-danger">✗ Disabled</span>
                    <?php endif; ?>
                </td>
            </tr>
            <tr>
                <th>PDO SQLite Extension</th>
                <td>
                    <?php if ($pdoSqliteAvailable): ?>
                        <span class="badge badge-success">✓ Enabled</span>
                    <?php else: ?>
                        <span class="badge badge-danger">✗ Disabled</span>
                    <?php endif; ?>
                </td>
            </tr>
            <tr>
                <th>Storage Directory</th>
                <td>
                    <?php if ($storageWritable): ?>
                        <span class="badge badge-success">✓ Writable</span>
                    <?php else: ?>
                        <span class="badge badge-danger">✗ Check 755 permissions on storage/</span>
                    <?php endif; ?>
                </td>
            </tr>
            <tr>
                <th>Database Status</th>
                <td>
                    <?php if (empty($dbError)): ?>
                        <span class="badge badge-success">✓ <?= htmlspecialchars($dbStatus) ?></span>
                    <?php else: ?>
                        <span class="badge badge-danger">✗ Error: <?= htmlspecialchars($dbError) ?></span>
                    <?php endif; ?>
                </td>
            </tr>
            <tr>
                <th>Gemini API Key</th>
                <td>
                    <?php if ($apiKeyPresent): ?>
                        <span class="badge badge-success">✓ Configured</span> <code><?= htmlspecialchars($apiKeyMasked) ?></code>
                    <?php else: ?>
                        <span class="badge badge-danger">✗ Missing in config.php</span>
                    <?php endif; ?>
                </td>
            </tr>
            <tr>
                <th>Daily Upload Limit</th>
                <td><strong>2 images</strong> per user per calendar day (BST)</td>
            </tr>
            <tr>
                <th>Format Output</th>
                <td><strong>Sequential Steps</strong> (Step 1, Step 2... / ধাপ ১, ধাপ ২...) & <strong>Bilingual (EN + BN)</strong></td>
            </tr>
        </table>

        <div class="endpoint-box">
            <h3 style="margin-top: 0; color: #1e293b;">Active API Endpoints</h3>
            <ul>
                <li><code>GET /SmartAgriServer/api/health</code> - Server status</li>
                <li><code>POST /SmartAgriServer/api/disease/detect</code> - Crop disease detection (2 images/day limit)</li>
                <li><code>GET /SmartAgriServer/api/disease/limit-status</code> - Remaining scans check</li>
                <li><code>POST /SmartAgriServer/api/chat</code> - Farmer AI chatbot</li>
                <li><code>POST /SmartAgriServer/api/sync</code> - Offline Hive local database sync</li>
            </ul>
        </div>
    </div>
</body>
</html>
