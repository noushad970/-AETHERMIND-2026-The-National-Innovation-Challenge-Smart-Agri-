<?php
/**
 * Farmer AI Chatbot Controller
 * Securely communicates with Gemini LLM on the server side
 * without exposing API keys to the client.
 */

class ChatController {
    private array $config;
    private PDO $db;

    public function __construct(array $config) {
        $this->config = $config;
        $this->db = Database::getConnection();
    }

    /**
     * POST /api/chat
     * Input: { message: "...", history: [...], user_id: "..." }
     */
    public function reply(array $auth): void {
        $input = json_decode(file_get_contents('php://input'), true);
        $userMessage = trim($input['message'] ?? $_POST['message'] ?? '');
        $history = $input['history'] ?? [];
        $userId = $auth['user_id'];

        if (empty($userMessage)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Message cannot be empty.',
                'message_bn' => 'বার্তার ঘর ফাঁকা রাখা যাবে না।',
            ], JSON_UNESCAPED_UNICODE);
            return;
        }

        $apiKey = $this->config['gemini']['api_key'] ?? '';
        if (empty($apiKey)) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Gemini API key is not configured on the backend server.',
                'message_bn' => 'সার্ভারে এআই কনফিগারেশন ত্রুটি।',
            ], JSON_UNESCAPED_UNICODE);
            return;
        }

        $models = $this->config['gemini']['fallback_models'] ?? ['gemini-2.5-flash', 'gemini-1.5-flash'];
        $systemInstruction = $this->getSystemPrompt();

        // Build contents array
        $contents = [];
        foreach ($history as $h) {
            $role = ($h['role'] ?? 'user') === 'assistant' ? 'model' : 'user';
            $text = trim($h['content'] ?? '');
            if (!empty($text)) {
                $contents[] = [
                    'role' => $role,
                    'parts' => [['text' => $text]]
                ];
            }
        }
        $contents[] = [
            'role' => 'user',
            'parts' => [['text' => $userMessage]]
        ];

        $replyText = '';
        $usedModel = '';

        foreach ($models as $model) {
            $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=" . urlencode($apiKey);

            $payload = [
                'system_instruction' => [
                    'parts' => [['text' => $systemInstruction]]
                ],
                'contents' => $contents,
                'generationConfig' => [
                    'temperature' => 0.4,
                    'maxOutputTokens' => 1024,
                ]
            ];

            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST => true,
                CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                CURLOPT_POSTFIELDS => json_encode($payload),
                CURLOPT_TIMEOUT => 25,
                CURLOPT_CONNECTTIMEOUT => 8,
                CURLOPT_SSL_VERIFYPEER => true,
            ]);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode === 200 && !empty($response)) {
                $json = json_decode($response, true);
                $replyText = $json['candidates'][0]['content']['parts'][0]['text'] ?? '';
                if (!empty(trim($replyText))) {
                    $usedModel = $model;
                    break;
                }
            }
        }

        if (empty(trim($replyText))) {
            $replyText = "আসসালামু আলাইকুম কৃষক ভাই! সার্ভারে কিছুটা সাময়িক ট্রাফিক রয়েছে। আপনার প্রশ্নটি বুঝতে পেরেছি। ফসলের সুরক্ষায় স্থানীয় কৃষি কর্মকর্তার পরামর্শ নিন অথবা কিছুক্ষণ পর আবার বার্তা দিন।";
            $usedModel = 'fallback_local';
        } else {
            $replyText = $this->ensureWarmGreeting($replyText);
        }

        // Log chat in database
        try {
            $stmt = $this->db->prepare('INSERT INTO chat_logs (user_id, prompt, reply, model_used, created_at) VALUES (:u, :p, :r, :m, :c)');
            $stmt->execute([
                ':u' => $userId,
                ':p' => $userMessage,
                ':r' => $replyText,
                ':m' => $usedModel,
                ':c' => date('Y-m-d H:i:s'),
            ]);
        } catch (Exception $e) {
            error_log('[Chat Log Error] ' . $e->getMessage());
        }

        echo json_encode([
            'success' => true,
            'reply' => $replyText,
            'model' => $usedModel,
        ], JSON_UNESCAPED_UNICODE);
    }

    private function getSystemPrompt(): string {
        return "You are 'Krishi Sahayak' (কৃষি সহায়ক), an expert, respectful, and friendly AI agricultural advisor for farmers across Bangladesh.\n"
            . "MANDATORY RULES:\n"
            . "1. ALWAYS start your reply with a polite, warm greeting in Bangla (e.g. 'আসসালামু আলাইকুম কৃষক ভাই', 'শুভ সকাল', 'নমস্কার') or in English if asked in English.\n"
            . "2. Give clear, sequential steps (ধাপ ১, ধাপ ২...) for pest treatment or fertilizers.\n"
            . "3. Mention Bangladeshi local fertilizer and pesticide brand names and doses per liter of water.\n"
            . "4. Keep language simple, practical, and easy for any farmer to understand.";
    }

    private function ensureWarmGreeting(string $text): string {
        $trimmed = trim($text);
        if (empty($trimmed)) return $text;
        $lower = mb_strtolower($trimmed, 'UTF-8');
        $greetings = ['assalamu', 'আসসালামু', 'hello', 'hi', 'শুভ সকাল', 'শুভ দুপুর', 'শুভ সন্ধ্যা', 'নমস্কার', 'আদাব', 'হ্যালো'];
        foreach ($greetings as $g) {
            if (str_starts_with($lower, $g)) {
                return $trimmed;
            }
        }
        return "আসসালামু আলাইকুম কৃষক ভাই!\n\n" . $trimmed;
    }
}
