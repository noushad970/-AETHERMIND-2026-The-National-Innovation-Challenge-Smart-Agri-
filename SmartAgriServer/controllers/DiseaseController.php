<?php
/**
 * Disease Detection Controller
 * 
 * Enforces:
 * 1. Daily limitation: Maximum 2 crop disease image uploads per user per day.
 * 2. Formats all disease descriptions and solutions as SEQUENTIAL STEPS (Step 1, Step 2, Step 3... / ধাপ ১, ধাপ ২, ধাপ ৩...).
 * 3. Provides bilingual output in both English and Bangla.
 * 4. Calls Google Gemini Vision API securely from the backend server without exposing API keys.
 */

class DiseaseController {
    private array $config;
    private PDO $db;

    public function __construct(array $config) {
        $this->config = $config;
        $this->db = Database::getConnection();
    }

    /**
     * Check how many uploads the user has used today and how many remain.
     * GET /api/disease/limit-status
     */
    public function getLimitStatus(array $auth): void {
        $userId = $auth['user_id'];
        $today = date('Y-m-d');
        $maxDaily = (int)($this->config['disease_limits']['max_scans_per_user_per_day'] ?? 2);

        $stmt = $this->db->prepare('SELECT COUNT(*) as cnt FROM disease_scans WHERE user_id = :user_id AND scan_date = :scan_date');
        $stmt->execute([':user_id' => $userId, ':scan_date' => $today]);
        $row = $stmt->fetch();
        $used = (int)($row['cnt'] ?? 0);
        $remaining = max(0, $maxDaily - $used);

        echo json_encode([
            'success' => true,
            'user_id' => $userId,
            'date' => $today,
            'limit' => $maxDaily,
            'used' => $used,
            'remaining' => $remaining,
            'can_upload' => ($remaining > 0),
            'reset_time' => date('Y-m-d 23:59:59'),
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Get user's past scan history stored on the server.
     * GET /api/disease/history
     */
    public function getHistory(array $auth): void {
        $userId = $auth['user_id'];
        $stmt = $this->db->prepare('
            SELECT id, user_id, scan_date, crop_name_en, crop_name_bn, 
                   disease_name_en, disease_name_bn, confidence, severity, 
                   symptoms_steps, treatment_steps, prevention_steps, medicines, created_at
            FROM disease_scans 
            WHERE user_id = :user_id 
            ORDER BY id DESC LIMIT 50
        ');
        $stmt->execute([':user_id' => $userId]);
        $rows = $stmt->fetchAll();

        $scans = array_map(function($r) {
            return [
                'id' => (int)$r['id'],
                'user_id' => $r['user_id'],
                'scan_date' => $r['scan_date'],
                'crop_name_en' => $r['crop_name_en'] ?? '',
                'crop_name_bn' => $r['crop_name_bn'] ?? '',
                'disease_name_en' => $r['disease_name_en'],
                'disease_name_bn' => $r['disease_name_bn'],
                'confidence' => (float)$r['confidence'],
                'severity' => $r['severity'] ?? 'Medium',
                'symptoms_steps' => json_decode($r['symptoms_steps'] ?? '[]', true) ?: $r['symptoms_steps'],
                'treatment_steps' => json_decode($r['treatment_steps'] ?? '[]', true) ?: $r['treatment_steps'],
                'prevention_steps' => json_decode($r['prevention_steps'] ?? '[]', true) ?: $r['prevention_steps'],
                'medicines' => json_decode($r['medicines'] ?? '[]', true) ?: $r['medicines'],
                'created_at' => $r['created_at'],
            ];
        }, $rows);

        echo json_encode([
            'success' => true,
            'count' => count($scans),
            'history' => $scans,
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Detect crop disease from uploaded image.
     * POST /api/disease/detect
     */
    public function detect(array $auth): void {
        $userId = $auth['user_id'];
        $today = date('Y-m-d');
        $maxDaily = (int)($this->config['disease_limits']['max_scans_per_user_per_day'] ?? 2);

        // 1. Check daily limit
        $stmt = $this->db->prepare('SELECT COUNT(*) as cnt FROM disease_scans WHERE user_id = :user_id AND scan_date = :scan_date');
        $stmt->execute([':user_id' => $userId, ':scan_date' => $today]);
        $row = $stmt->fetch();
        $used = (int)($row['cnt'] ?? 0);

        if ($used >= $maxDaily) {
            http_response_code(429); // Too Many Requests
            echo json_encode([
                'success' => false,
                'error_code' => 'DAILY_LIMIT_EXCEEDED',
                'message' => "Daily limit reached. You can only analyze up to {$maxDaily} crop disease images per day.",
                'message_bn' => "দৈনিক সীমা অতিক্রম হয়েছে। আপনি প্রতিদিন সর্বোচ্চ {$maxDaily}টি ফসলের ছবি পরীক্ষা করতে পারেন। অনুগ্রহ করে আগামীকাল আবার চেষ্টা করুন।",
                'limit' => $maxDaily,
                'used' => $used,
                'remaining' => 0,
                'reset_time' => date('Y-m-d 23:59:59'),
            ], JSON_UNESCAPED_UNICODE);
            return;
        }

        // 2. Validate uploaded file or base64 payload
        $imageData = null;
        $mimeType = 'image/jpeg';
        $originalFilename = 'crop_scan.jpg';

        if (isset($_FILES['image']) && is_uploaded_file($_FILES['image']['tmp_name'])) {
            $file = $_FILES['image'];
            if ($file['error'] !== UPLOAD_ERR_OK) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Upload error code: ' . $file['error'],
                    'message_bn' => 'ছবি আপলোডে ত্রুটি দেখা দিয়েছে।',
                ], JSON_UNESCAPED_UNICODE);
                return;
            }

            // Size check
            $maxBytes = $this->config['disease_limits']['max_file_size_bytes'] ?? (10 * 1024 * 1024);
            if ($file['size'] > $maxBytes) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'File size exceeds maximum allowed size (10MB).',
                    'message_bn' => 'ছবির আকার সর্বোচ্চ ১০ মেগাবাইটের বেশি হতে পারবে না।',
                ], JSON_UNESCAPED_UNICODE);
                return;
            }

            // MIME type check
            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            $detectedMime = finfo_file($finfo, $file['tmp_name']);
            finfo_close($finfo);

            $allowedMimes = $this->config['disease_limits']['allowed_mime_types'] ?? ['image/jpeg', 'image/png', 'image/webp'];
            if (!in_array($detectedMime, $allowedMimes)) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => "Invalid image format ({$detectedMime}). Only JPEG, PNG, and WebP are supported.",
                    'message_bn' => 'অসমর্থিত ছবির ফরম্যাট। শুধুমাত্র JPG, PNG বা WebP ছবি গ্রহণযোগ্য।',
                ], JSON_UNESCAPED_UNICODE);
                return;
            }

            $mimeType = $detectedMime;
            $originalFilename = $file['name'];
            $imageData = file_get_contents($file['tmp_name']);
        } else {
            // Check JSON body for base64
            $input = json_decode(file_get_contents('php://input'), true);
            if (!empty($input['image_base64'])) {
                $raw = $input['image_base64'];
                if (preg_match('/^data:(image\/[a-zA-Z0-9\+\-]+);base64,/', $raw, $m)) {
                    $mimeType = $m[1];
                    $raw = substr($raw, strpos($raw, ',') + 1);
                }
                $imageData = base64_decode($raw);
                $originalFilename = $input['filename'] ?? 'crop_scan.jpg';
            }
        }

        if (empty($imageData)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'No image was provided. Send via multipart form (key "image") or JSON "image_base64".',
                'message_bn' => 'কোনো ছবি পাওয়া যায়নি। অনুগ্রহ করে ফসলের একটি ছবি নির্বাচন করুন।',
            ], JSON_UNESCAPED_UNICODE);
            return;
        }

        // 3. Call Gemini Vision API securely
        $apiKey = $this->config['gemini']['api_key'] ?? '';
        if (empty($apiKey)) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Gemini API key is not configured on the backend server.',
                'message_bn' => 'সার্ভারে এআই কনফিগারেশন অনুপস্থিত।',
            ], JSON_UNESCAPED_UNICODE);
            return;
        }

        $base64Image = base64_encode($imageData);
        $imageHash = md5($imageData);

        $aiResult = $this->analyzeWithGemini($apiKey, $base64Image, $mimeType);

        if (!$aiResult['success']) {
            http_response_code(502);
            echo json_encode([
                'success' => false,
                'message' => 'AI analysis failed: ' . $aiResult['error'],
                'message_bn' => 'এআই সার্ভারে রোগ বিশ্লেষণ করা যায়নি। কিছুক্ষণ পর আবার চেষ্টা করুন।',
            ], JSON_UNESCAPED_UNICODE);
            return;
        }

        $parsed = $aiResult['data'];

        // 4. Record successful scan in database and consume 1 quota
        try {
            $insert = $this->db->prepare('
                INSERT INTO disease_scans (
                    user_id, scan_date, image_hash, crop_name_en, crop_name_bn,
                    disease_name_en, disease_name_bn, confidence, severity,
                    symptoms_steps, treatment_steps, prevention_steps, medicines,
                    raw_response, client_ip, created_at
                ) VALUES (
                    :user_id, :scan_date, :image_hash, :crop_name_en, :crop_name_bn,
                    :disease_name_en, :disease_name_bn, :confidence, :severity,
                    :symptoms_steps, :treatment_steps, :prevention_steps, :medicines,
                    :raw_response, :client_ip, :created_at
                )
            ');

            $now = date('Y-m-d H:i:s');
            $insert->execute([
                ':user_id' => $userId,
                ':scan_date' => $today,
                ':image_hash' => $imageHash,
                ':crop_name_en' => $parsed['crop_name_en'] ?? 'Crop',
                ':crop_name_bn' => $parsed['crop_name_bn'] ?? 'ফসল',
                ':disease_name_en' => $parsed['disease_name_en'],
                ':disease_name_bn' => $parsed['disease_name_bn'],
                ':confidence' => $parsed['confidence'],
                ':severity' => $parsed['severity'] ?? 'Medium',
                ':symptoms_steps' => json_encode($parsed['symptoms_steps_bn'], JSON_UNESCAPED_UNICODE),
                ':treatment_steps' => json_encode($parsed['treatment_steps_bn'], JSON_UNESCAPED_UNICODE),
                ':prevention_steps' => json_encode($parsed['prevention_steps_bn'], JSON_UNESCAPED_UNICODE),
                ':medicines' => json_encode($parsed['medicines_bn'], JSON_UNESCAPED_UNICODE),
                ':raw_response' => $aiResult['raw_text'] ?? '',
                ':client_ip' => $auth['client_ip'],
                ':created_at' => $now,
            ]);

            // Update user record
            $userUpsert = $this->db->prepare("
                INSERT INTO users (user_id, device_id, client_ip, total_scans, created_at, last_active_at)
                VALUES (:u, :d, :ip, 1, :now, :now)
                ON CONFLICT(user_id) DO UPDATE SET
                    total_scans = total_scans + 1,
                    last_active_at = :now,
                    client_ip = :ip
            ");
            $userUpsert->execute([
                ':u' => $userId,
                ':d' => $auth['device_id'],
                ':ip' => $auth['client_ip'],
                ':now' => $now,
            ]);
        } catch (Exception $e) {
            error_log('[DB Insert Scan Error] ' . $e->getMessage());
        }

        $newUsed = $used + 1;
        $newRemaining = max(0, $maxDaily - $newUsed);

        // 5. Return structured response with sequential text and bilingual support
        echo json_encode([
            'success' => true,
            'limit_info' => [
                'limit' => $maxDaily,
                'used' => $newUsed,
                'remaining' => $newRemaining,
                'reset_time' => date('Y-m-d 23:59:59'),
            ],
            'data' => $parsed,
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Executes prompt on Gemini Vision API with model fallback chain.
     * Enforces sequential steps output in both English and Bangla.
     */
    private function analyzeWithGemini(string $apiKey, string $base64Image, string $mimeType): array {
        $models = $this->config['gemini']['fallback_models'] ?? ['gemini-2.5-flash', 'gemini-1.5-flash', 'gemini-1.5-pro'];
        $prompt = $this->buildSequentialBilingualPrompt();

        $lastError = 'Unknown error';

        foreach ($models as $model) {
            $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=" . urlencode($apiKey);

            $payload = [
                'contents' => [
                    [
                        'role' => 'user',
                        'parts' => [
                            ['text' => $prompt],
                            [
                                'inline_data' => [
                                    'mime_type' => $mimeType,
                                    'data' => $base64Image,
                                ]
                            ]
                        ]
                    ]
                ],
                'generationConfig' => [
                    'temperature' => (float)($this->config['gemini']['temperature'] ?? 0.2),
                    'maxOutputTokens' => (int)($this->config['gemini']['max_tokens'] ?? 2048),
                    'responseMimeType' => 'application/json',
                ]
            ];

            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST => true,
                CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                CURLOPT_POSTFIELDS => json_encode($payload),
                CURLOPT_TIMEOUT => 30,
                CURLOPT_CONNECTTIMEOUT => 10,
                CURLOPT_SSL_VERIFYPEER => true,
            ]);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $curlError = curl_error($ch);
            curl_close($ch);

            if ($response === false || !empty($curlError)) {
                $lastError = "cURL error on model {$model}: {$curlError}";
                continue;
            }

            if ($httpCode !== 200) {
                $lastError = "HTTP {$httpCode} on model {$model}: {$response}";
                continue;
            }

            $json = json_decode($response, true);
            $text = $json['candidates'][0]['content']['parts'][0]['text'] ?? '';

            if (empty(trim($text))) {
                $lastError = "Empty text from model {$model}";
                continue;
            }

            // Parse structured JSON
            $parsed = $this->cleanAndParseJson($text);
            if ($parsed !== null) {
                return [
                    'success' => true,
                    'model' => $model,
                    'data' => $parsed,
                    'raw_text' => $text,
                ];
            } else {
                $lastError = "Failed to parse JSON reply from {$model}: " . substr($text, 0, 150);
            }
        }

        return [
            'success' => false,
            'error' => $lastError,
        ];
    }

    /**
     * Builds the prompt demanding sequential steps (Step 1, Step 2, Step 3... / ধাপ ১, ধাপ ২...)
     * and bilingual (English + Bangla) fields.
     */
    private function buildSequentialBilingualPrompt(): string {
        return <<<PROMPT
You are an expert Bangladeshi Agricultural Plant Pathologist ("Krishi Sahayak").
Analyze the provided crop image carefully and diagnose the exact disease, pest, or nutrient deficiency.

CRITICAL INSTRUCTIONS FOR FARMER UNDERSTANDING:
1. FARMERS NEED SIMPLE, SEQUENTIAL STEPS INSTEAD OF COMPLEX PARAGRAPHS.
   Every section (Symptoms, Immediate Treatment, Prevention, Medicine) MUST be broken down into clear, sequential numbered steps:
   - In English: "Step 1: ...", "Step 2: ...", "Step 3: ..."
   - In Bangla: "ধাপ ১: ...", "ধাপ ২: ...", "ধাপ ৩: ..."
2. BILINGUAL OUTPUT: Provide both complete English and complete Bangla translations for every field.
3. MEDICATIONS: Mention exact Bangladesh-available pesticide/fungicide names (e.g. Carbendazim, Mancozeb, Imidacloprid, Trichoderma) and exact dose per liter of water (e.g., প্রতি লিটার পানিতে ২ গ্রাম).
4. If image is not a plant or disease is unclear, mark disease_name_bn as "শনাক্ত করা যায়নি" and confidence as 0.0.
5. Return ONLY a single raw valid JSON object matching the schema below. No markdown fences.

EXACT JSON SCHEMA:
{
  "crop_name_en": "Crop name in English (e.g. Rice, Tomato, Potato)",
  "crop_name_bn": "Crop name in Bangla (e.g. ধান, টমেটো, আলু)",
  "disease_name_en": "Disease name in English (e.g. Brown Spot, Late Blight)",
  "disease_name_bn": "Disease name in Bangla (e.g. বাদামি দাগ রোগ, নাবি ধসা রোগ)",
  "confidence": 0.95,
  "severity": "Low" | "Medium" | "High",
  "severity_bn": "হালকা" | "মাঝারি" | "তীব্র",
  "symptoms_steps_en": [
    "Step 1: Check for small dark brown circular or oval spots on leaves.",
    "Step 2: Note if spots develop gray or whitish centers.",
    "Step 3: Inspect if lower leaves begin yellowing and withering prematurely."
  ],
  "symptoms_steps_bn": [
    "ধাপ ১: পাতার উপর ছোট গাঢ় বাদামি বা ডিম্বাকৃতির দাগ লক্ষ্য করুন।",
    "ধাপ ২: লক্ষ্য করুন দাগের কেন্দ্রস্থল ধূসর বা সাদাটে হচ্ছে কিনা।",
    "ধাপ ৩: নিচের পাতাগুলো হলুদ হয়ে অকালে শুকিয়ে ঝরে পড়ছে কিনা পরীক্ষা করুন।"
  ],
  "treatment_steps_en": [
    "Step 1: Immediately pluck and safely bury or burn all heavily infected leaves.",
    "Step 2: Drain stagnant water from the field and allow fresh aeration for 2 days.",
    "Step 3: Spray recommended organic or chemical solution in the late afternoon."
  ],
  "treatment_steps_bn": [
    "ধাপ ১: সাথে সাথে আক্রান্ত পাতাগুলো ছিঁড়ে দূরে মাটির নিচে পুঁতে ফেলুন বা পুড়িয়ে নষ্ট করুন।",
    "ধাপ ২: জমি থেকে জমা পানি নিষ্কাশন করুন এবং ২ দিন শিকড়ে বাতাস চলাচলের সুযোগ দিন।",
    "ধাপ ৩: বিকেলে রোদ কমে গেলে নির্দেশিত জৈব বা রাসায়নিক ওষুধ ভালোভাবে স্প্রে করুন।"
  ],
  "prevention_steps_en": [
    "Step 1: Treat seeds with Trichoderma or Carbendazim (2g/kg) before sowing.",
    "Step 2: Maintain proper spacing between rows to avoid excessive moisture.",
    "Step 3: Balance nitrogen fertilizer with sufficient potassium and zinc."
  ],
  "prevention_steps_bn": [
    "ধাপ ১: বীজ বপনের আগে কার্বেন্ডাজিম (প্রতি কেজি বীজে ২ গ্রাম) দিয়ে শোধন করুন।",
    "ধাপ ২: জমিতে চারা রোপণের সময় নির্দিষ্ট দূরত্ব বজায় রাখুন যেন আলো-বাতাস পায়।",
    "ধাপ ৩: ইউরিয়া সারের মাত্রা কমিয়ে পটাশ ও দস্তা সারের সঠিক ভারসাম্য রাখুন।"
  ],
  "medicines_en": [
    "Carbendazim 50% WP (Autostin/Knowin) - 2 grams per 1 Liter of water.",
    "Mancozeb 75% WP (Dithane M-45) - 2.5 grams per 1 Liter of water.",
    "Neem oil spray (organic) - 5ml + 1ml liquid soap per 1 Liter of water."
  ],
  "medicines_bn": [
    "কার্বেন্ডাজিম ৫০% ডব্লিউপি (অটোস্টিন/নয়িন) - প্রতি লিটার পানিতে ২ গ্রাম।",
    "ম্যানকোজেব ৭৫% ডব্লিউপি (ডাইথেন এম-৪৫) - প্রতি লিটার পানিতে ২.৫ গ্রাম।",
    "নিম তেলের মিশ্রণ (জৈব সমাধান) - প্রতি লিটার পানিতে ৫ মিলি নিম তেল ও অল্প ডিটারজেন্ট মিশিয়ে স্প্রে করুন।"
  ],
  "causes_en": "Warm, humid conditions and excessive nitrogen fertilizer.",
  "causes_bn": "উষ্ণ ও স্যাঁতসেঁতে আবহাওয়া এবং অতিরিক্ত ইউরিয়া সারের ব্যবহার।"
}
PROMPT;
    }

    private function cleanAndParseJson(string $text): ?array {
        $trimmed = trim($text);
        // Strip markdown backticks ```json ... ```
        if (preg_match('/```(?:json)?\s*(.*?)\s*```/is', $trimmed, $m)) {
            $trimmed = trim($m[1]);
        }
        $data = json_decode($trimmed, true);
        if (is_array($data) && (!empty($data['disease_name_en']) || !empty($data['disease_name_bn']) || !empty($data['disease_name']))) {
            // Normalize fields
            if (empty($data['disease_name_bn']) && !empty($data['disease_name'])) {
                $data['disease_name_bn'] = $data['disease_name'];
            }
            if (empty($data['disease_name_en'])) {
                $data['disease_name_en'] = $data['disease_name_bn'] ?? 'Plant Disease';
            }
            if (empty($data['confidence'])) {
                $data['confidence'] = 0.85;
            }
            // Ensure sequential steps arrays exist
            if (empty($data['treatment_steps_bn']) && !empty($data['treatment'])) {
                $data['treatment_steps_bn'] = ["ধাপ ১: " . $data['treatment']];
            }
            if (empty($data['treatment_steps_en']) && !empty($data['treatment_steps_bn'])) {
                $data['treatment_steps_en'] = $data['treatment_steps_bn'];
            }
            return $data;
        }
        return null;
    }
}
