<?php
/**
 * Authentication Middleware
 * Validates request authenticity via X-SmartAgri-Secret or Bearer Token.
 */

class AuthMiddleware {
    public static function authenticate(array $config): array {
        $securityConfig = $config['security'] ?? [];
        $expectedSecret = $config['app_secret'] ?? '';

        // Refuse to serve protected routes until a secret has been configured,
        // otherwise anyone could spend your Gemini quota.
        if (!empty($securityConfig['enforce_auth_header']) && empty($expectedSecret)) {
            http_response_code(503);
            echo json_encode([
                'success' => false,
                'error_code' => 'SERVER_NOT_CONFIGURED',
                'message' => 'Server secret is not configured. Set SMART_AGRI_SECRET or app_secret in config.php.',
                'message_bn' => 'সার্ভার এখনো কনফিগার করা হয়নি।',
            ], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // If auth enforcement is enabled, verify secret
        if (!empty($securityConfig['enforce_auth_header'])) {
            $providedSecret = self::getProvidedSecret();

            if (empty($providedSecret) || !hash_equals($expectedSecret, $providedSecret)) {
                http_response_code(401);
                echo json_encode([
                    'success' => false,
                    'error_code' => 'UNAUTHORIZED',
                    'message' => 'Invalid or missing API secret header (X-SmartAgri-Secret).',
                    'message_bn' => 'অননুমোদিত অনুরোধ। অ্যাপ সিক্রেট কী সঠিক নয়।',
                ], JSON_UNESCAPED_UNICODE);
                exit();
            }
        }

        // Extract user identifiers
        $userId = self::getHeader('X-User-ID') 
            ?: ($_POST['user_id'] ?? $_GET['user_id'] ?? 'guest_farmer_' . substr(md5(self::getClientIp()), 0, 10));
        $deviceId = self::getHeader('X-Device-ID') ?: ($_POST['device_id'] ?? $_GET['device_id'] ?? '');

        return [
            'user_id' => trim($userId),
            'device_id' => trim($deviceId),
            'client_ip' => self::getClientIp(),
        ];
    }

    private static function getProvidedSecret(): ?string {
        // Check X-SmartAgri-Secret header
        $secret = self::getHeader('X-SmartAgri-Secret');
        if (!empty($secret)) {
            return $secret;
        }

        // Check Authorization header: Bearer <secret>
        $authHeader = self::getHeader('Authorization');
        if (!empty($authHeader) && preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            return trim($matches[1]);
        }

        return null;
    }

    private static function getHeader(string $name): ?string {
        $nameUpper = strtoupper(str_replace('-', '_', $name));
        if (isset($_SERVER['HTTP_' . $nameUpper])) {
            return $_SERVER['HTTP_' . $nameUpper];
        }
        if (isset($_SERVER[$nameUpper])) {
            return $_SERVER[$nameUpper];
        }
        if (function_exists('apache_request_headers')) {
            $headers = apache_request_headers();
            foreach ($headers as $k => $v) {
                if (strcasecmp($k, $name) === 0) {
                    return $v;
                }
            }
        }
        return null;
    }

    public static function getClientIp(): string {
        $keys = [
            'HTTP_CF_CONNECTING_IP', // Cloudflare
            'HTTP_X_FORWARDED_FOR',  // Proxies
            'HTTP_X_REAL_IP',
            'REMOTE_ADDR',
        ];
        foreach ($keys as $k) {
            if (!empty($_SERVER[$k])) {
                $ips = explode(',', $_SERVER[$k]);
                return trim($ips[0]);
            }
        }
        return '127.0.0.1';
    }
}
