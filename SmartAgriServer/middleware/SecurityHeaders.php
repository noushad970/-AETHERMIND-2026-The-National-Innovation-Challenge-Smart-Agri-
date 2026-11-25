<?php
/**
 * Security Headers & CORS Middleware
 */

class SecurityHeaders {
    public static function apply(): void {
        // Prevent clickjacking & MIME confusion
        header('X-Content-Type-Options: nosniff');
        header('X-Frame-Options: SAMEORIGIN');
        header('X-XSS-Protection: 1; mode=block');
        header('Referrer-Policy: strict-origin-when-cross-origin');

        // CORS for Mobile Apps & Web
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Origin, Content-Type, Accept, Authorization, X-SmartAgri-Secret, X-User-ID, X-Device-ID');
        header('Access-Control-Max-Age: 86400');

        // Respond immediately to preflight OPTIONS
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            http_response_code(200);
            exit();
        }
    }
}
