import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/constants/app_constants.dart';
import '../models/animal.dart';
import '../models/disease_result.dart';
import '../models/fish_daily_summary.dart';
import '../models/fish_pond.dart';
import '../models/livestock_daily_summary.dart';
import '../models/market_price.dart';
import 'ai_rate_limit_service.dart';
import 'backend_api_service.dart';

class GeminiService {
  GeminiService({String? apiKey, String? modelName}) {
    _apiKeyOverride = apiKey;
    _modelNameOverride = modelName;
  }

  String? _apiKeyOverride;
  String? _modelNameOverride;

  GenerativeModel? _model;
  String? _modelNameActive;

  String get _apiKey => _apiKeyOverride ?? AppConstants.geminiApiKey;
  String get _modelName => _modelNameOverride ?? AppConstants.geminiModel;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Gemini 3.5+ models ordered by speed, capability, and token limits.
  /// If one model limit or token finishes, the system automatically transitions
  /// to the next model in this chain.
  static const List<String> _fallbackModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.5-flash',
    'gemini-3.5-pro',
  ];

  static int get fallbackModelsCount => _fallbackModels.length;

  /// Persists the currently working model across instances so if one model's quota
  /// finishes, the app immediately uses the next working model without hitting limit errors.
  static String? _workingModel;

  /// Returns candidate models starting with the current working model,
  /// followed by any overrides and the rest of the prioritized fallback chain.
  List<String> _getCandidateModels() {
    final list = <String>[];
    if (_workingModel != null && _fallbackModels.contains(_workingModel)) {
      list.add(_workingModel!);
    }
    if (_modelNameOverride != null && !list.contains(_modelNameOverride)) {
      list.add(_modelNameOverride!);
    }
    if (!list.contains(_modelName)) {
      list.add(_modelName);
    }
    for (final m in _fallbackModels) {
      if (!list.contains(m)) {
        list.add(m);
      }
    }
    return list;
  }

  GenerativeModel _ensureModel({String? modelName}) {
    if (!isConfigured) {
      throw const GeminiException(
        'Gemini API key not configured. Pass --dart-define=GEMINI_API_KEY=... when running.',
      );
    }
    final name = modelName ?? _workingModel ?? _modelName;
    final cached = _model;
    if (cached != null && _modelNameActive == name) return cached;
    _modelNameActive = name;
    return _model = GenerativeModel(
      model: name,
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemPrompt()),
    );
  }

  /// Detect a crop disease from raw image bytes using the Gemini API
  /// (free tier). The image is sent with a Bangla-language prompt that
  /// asks for a structured JSON report. Automatically rotates through models
  /// if a quota or token limit is reached.
  Future<DiseaseResult> detectDiseaseBytes(
    Uint8List bytes, {
    String filename = '',
    String userId = 'farmer',
  }) async {
    // 1. First delegate to dedicated Smart Agri cPanel backend server
    try {
      final backendResult = await BackendApiService().detectDisease(
        bytes: bytes,
        filename: filename,
        userId: userId,
      );
      return backendResult;
    } on DailyLimitExceededException {
      rethrow;
    } catch (e) {
      developer.log(
        'Backend server call failed ($e), attempting direct fallback...',
        name: 'GeminiService',
      );
    }

    if (!isConfigured) {
      throw const GeminiException(
        'Gemini API key not configured. Pass --dart-define=GEMINI_API_KEY=... when running.',
      );
    }
    // Enforce 20 requests/day rate limit
    await AiRateLimitService.instance.checkAndConsumeQuota();
    final mime = _mimeForFilename(filename);
    final prompt = TextPart(_diseasePrompt());
    final imagePart = DataPart(mime, bytes);
    final candidates = _getCandidateModels();
    Object? lastError;

    for (final candidate in candidates) {
      try {
        final model = _ensureModel(modelName: candidate);
        final response = await model.generateContent([
          Content.multi([prompt, imagePart]),
        ]);
        final text = response.text?.trim() ?? '';
        if (text.isNotEmpty) {
          _workingModel = candidate;
          _model = model;
          _modelNameActive = candidate;
          return _parseDiseaseResponse(text);
        }
        lastError = GeminiException(
          'Model $candidate returned empty response.',
        );
        developer.log(
          'Empty disease reply from $candidate, trying next model',
          name: 'GeminiService',
        );
      } catch (e) {
        lastError = e;
        developer.log(
          'Model $candidate failed or quota limit reached ($e), switching to next model in chain',
          name: 'GeminiService',
          error: e,
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }

    if (lastError is GeminiException) {
      throw lastError;
    }
    throw GeminiException(
      'All Gemini models failed to detect the disease. Last error: $lastError',
    );
  }

  Future<DiseaseResult> detectDiseaseBytesFromFile(
    Future<Uint8List> Function() read,
  ) async {
    return detectDiseaseBytes(await read());
  }

  String _mimeForFilename(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<String> chatCompletion({
    required String userMessage,
    required List<Map<String, String>> history,
    void Function({
      required String model,
      required int attemptNumber,
      required bool success,
      String? finishReason,
      String? error,
    })?
    onAttempt,
  }) async {
    // 1. Try dedicated Smart Agri backend server first
    try {
      final serverReply = await BackendApiService().sendChatMessage(
        userMessage: userMessage,
        history: history,
        userId: 'farmer',
      );
      if (serverReply.trim().isNotEmpty && !serverReply.contains('সাময়িক ট্রাফিক রয়েছে')) {
        onAttempt?.call(
          model: 'server-gemini',
          attemptNumber: 1,
          success: true,
          finishReason: 'stop',
          error: null,
        );
        return ensureGreeting(serverReply);
      }
    } catch (e) {
      developer.log('Backend chat call failed ($e), falling back to client...', name: 'GeminiService');
    }

    // Enforce 20 requests/day rate limit
    await AiRateLimitService.instance.checkAndConsumeQuota();

    final historyContent = history
        .where((m) => (m['content'] ?? '').trim().isNotEmpty)
        .map((m) {
          final role = (m['role'] ?? 'user') == 'assistant' ? 'model' : 'user';
          return Content(role, [TextPart(m['content'] ?? '')]);
        })
        .toList();

    final candidates = _getCandidateModels();
    onAttempt?.call(
      model: candidates.first,
      attemptNumber: 0,
      success: false,
      finishReason: 'QUEUED',
      error: null,
    );

    Object? lastError;
    int attempt = 0;
    for (final candidate in candidates) {
      attempt++;
      try {
        onAttempt?.call(
          model: candidate,
          attemptNumber: attempt,
          success: false,
          finishReason: 'CALLING',
          error: null,
        );
        final model = _ensureModel(modelName: candidate);
        final chat = model.startChat(history: historyContent);
        final response = await chat.sendMessage(Content.text(userMessage));

        final cand = response.candidates.isNotEmpty
            ? response.candidates.first
            : null;
        final finishReason = cand?.finishReason?.name;
        final text = response.text?.trim() ?? '';

        if (text.isNotEmpty) {
          _workingModel = candidate;
          _model = model;
          _modelNameActive = candidate;
          onAttempt?.call(
            model: candidate,
            attemptNumber: attempt,
            success: true,
            finishReason: finishReason ?? 'stop',
            error: null,
          );
          return ensureGreeting(text);
        }

        if (finishReason == 'SAFETY' || finishReason == 'RECITATION') {
          onAttempt?.call(
            model: candidate,
            attemptNumber: attempt,
            success: false,
            finishReason: finishReason,
            error: 'safety_block',
          );
          throw GeminiException(
            'Response blocked by safety filter (finishReason=$finishReason). Rephrase the question and try again.',
          );
        }
        developer.log(
          'Empty reply from $candidate (finishReason=$finishReason), trying next candidate',
          name: 'GeminiService',
        );
        lastError = GeminiException(
          'Model $candidate returned empty (finishReason=$finishReason).',
        );
        onAttempt?.call(
          model: candidate,
          attemptNumber: attempt,
          success: false,
          finishReason: finishReason,
          error: 'empty_reply',
        );
      } catch (e) {
        developer.log(
          'Model $candidate token limit or server error: $e. Advancing to next fallback model.',
          name: 'GeminiService',
          error: e,
        );
        lastError = e;
        final s = e.toString();
        onAttempt?.call(
          model: candidate,
          attemptNumber: attempt,
          success: false,
          finishReason: 'ERROR',
          error: s,
        );
        // Continue loop to try all candidate fallback models seamlessly
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }

    developer.log('All Gemini models failed: $lastError', name: 'GeminiService');
    return ensureGreeting(
      'কৃষক ভাই, এআই সার্ভারে কিছুটা সাময়িক ট্রাফিক রয়েছে। আপনার বার্তাটি পেয়েছি। '
      'ফসলের যেকোনো রোগবালাই বা সারের সঠিক পরামর্শের জন্য স্থানীয় কৃষি কর্মকর্তার সাহায্য নিতে পারেন '
      'অথবা কিছুক্ষণ পর পুনরায় বার্তাটি পাঠান।',
    );
  }

  /// Live test connection to Gemini API returning detailed diagnostic result.
  Future<Map<String, dynamic>> testConnection() async {
    final candidate = _getCandidateModels().first;
    try {
      final model = _ensureModel(modelName: candidate);
      final response = await model.generateContent([
        Content.text('Hello! Reply with one word "Ready" if you can hear me.'),
      ]);
      final text = response.text?.trim() ?? '';
      return {
        'success': true,
        'model': candidate,
        'reply': text,
        'apiKeyPreview': _apiKey.length > 10
            ? '${_apiKey.substring(0, 6)}...${_apiKey.substring(_apiKey.length - 4)}'
            : _apiKey,
      };
    } catch (e) {
      return {
        'success': false,
        'model': candidate,
        'error': e.toString(),
        'apiKeyPreview': _apiKey.length > 10
            ? '${_apiKey.substring(0, 6)}...${_apiKey.substring(_apiKey.length - 4)}'
            : _apiKey,
      };
    }
  }

  /// Bangla-language prompt that asks Gemini to analyse a crop image
  /// and return a structured JSON report. Tone is tuned for a
  /// Bangladeshi farmer reading the result on a phone in the field.
  String _diseasePrompt() =>
      ''''তুমি একজন বিশেষজ্ঞ উদ্ভিদ রোগবিশেষজ্ঞ (plant pathologist)। সংযুক্ত ছবিতে বাংলাদেশের একটি ফসলের পাতা, ফল, কাণ্ড বা শিকড় দেখানো হয়েছে।

নির্দেশনা:
- ছবিটি ভালোভাবে পর্যবেক্ষণ করো এবং সবচেয়ে সম্ভাব্য রোগ, পোকার আক্রমণ বা পুষ্টির ঘাটতি চিহ্নিত করো।
- ছবি যদি ফসলের না হয় বা রোগ স্পষ্ট না হয়, তাহলে "অজানা" লিখো এবং confidence 0 দাও।
- সম্পূর্ণ উত্তর বাংলায় দাও। সাধারণ কৃষকের বোঝার মতো সহজ ভাষা ব্যবহার করো।
- কীটনাশক/সারের নাম বাংলাদেশে প্রচলিত নামে লেখো (যেমন: ইমিডাক্লোপ্রিড, কার্বেন্ডাজিম, ট্রাইকোডার্মা) এবং সম্ভব হলে প্রতি লিটার পানিতে মাত্রা উল্লেখ করো।
- শুধু একটি একক JSON অবজেক্ট রিটার্ন করো। কোনো মার্কডাউন, কোড ব্লক বা অতিরিক্ত ব্যাখ্যা দিও না।

JSON স্কিমা:
{
  "disease_name": "রোগের নাম (বাংলায়)",
  "confidence": 0.0 থেকে 1.0 এর মধ্যে সংখ্যা,
  "causes": "রোগ হওয়ার কারণ ও পরিবেশগত অবস্থা (১-২ বাক্য)",
  "symptoms": "আক্রান্ত গাছে দৃশ্যমান লক্ষণসমূহ (১-২ বাক্য)",
  "spread": "রোগটি কীভাবে ছড়িয়ে পড়ে (সংক্ষেপে)",
  "prevention": "প্রতিরোধের উপায় (২-৩ বাক্য)",
  "treatment": "আক্রান্ত গাছের চিকিৎসা (২-৩ বাক্য)",
  "organic_solutions": "জৈবিক সমাধান (যেমন: নিম তেল, ট্রাইকোডার্মা, ফেরোমন ফাঁদ)",
  "chemical_solutions": "রাসায়নিক সমাধান: ওষুধের নাম, প্রতি লিটার পানিতে মাত্রা, স্প্রে করার সময় ও সতর্কতা"
}

উত্তর শুধু JSON আকারে দাও, এর বাইরে কিছু লিখো না।''';

  String _systemPrompt() =>
      '''You are "Krishi Sahayak" (কৃষি সহায়ক), an expert, friendly, and respectful AI agricultural advisor for farmers across Bangladesh.

MANDATORY GREETING RULE:
- You MUST ALWAYS start EVERY conversational answer with a polite, warm greeting appropriate for Bangladeshi farmers:
  * In Bangla: "আসসালামু আলাইকুম" (Assalamu Alaikum), "শুভ সকাল" (Shuvo Sokal), "শুভ দুপুর", "শুভ সন্ধ্যা", "নমস্কার", or "হ্যালো কৃষক ভাই".
  * In English: "Hello", "Good Morning", "Good Afternoon", or "Assalamu Alaikum".
- After the warm greeting, give direct, practical, and highly actionable farming advice.
- Answer in simple, natural Bangla by default. If the user writes in English, reply in English starting with an English greeting.
- Keep responses concise, encouraging, and easy to understand for a farmer in the field.
- Use bullet points when listing treatment steps or fertilizers.
- Mention locally available fertilizer/pesticide names and doses in Bangladesh when relevant.
- Never output raw JSON or code blocks in normal chat unless explicitly asked.''';

  /// Ensures every AI response begins with a warm greeting if not already present.
  static String ensureGreeting(String response) {
    final trimmed = response.trim();
    if (trimmed.isEmpty) return response;

    final lower = trimmed.toLowerCase();
    final hasGreeting = lower.startsWith('assalamu alaikum') ||
        lower.startsWith('assalamualaykum') ||
        lower.startsWith('আসসালামু আলাইকুম') ||
        lower.startsWith('আসসালামু') ||
        lower.startsWith('hello') ||
        lower.startsWith('hi ') ||
        lower.startsWith('hi,') ||
        lower.startsWith('good morning') ||
        lower.startsWith('good afternoon') ||
        lower.startsWith('good evening') ||
        lower.startsWith('shuvo sokal') ||
        lower.startsWith('shubho sokal') ||
        lower.startsWith('শুভ সকাল') ||
        lower.startsWith('শুভ দুপুর') ||
        lower.startsWith('শুভ সন্ধ্যা') ||
        lower.startsWith('নমস্কার') ||
        lower.startsWith('আদাব') ||
        lower.startsWith('হ্যালো');

    if (hasGreeting) return trimmed;

    final isBangla = RegExp(r'[\u0980-\u09FF]').hasMatch(trimmed);
    final hour = DateTime.now().hour;
    String greeting;

    if (isBangla) {
      if (hour >= 5 && hour < 12) {
        greeting = 'আসসালামু আলাইকুম / শুভ সকাল!';
      } else if (hour >= 12 && hour < 17) {
        greeting = 'আসসালামু আলাইকুম / শুভ দুপুর!';
      } else if (hour >= 17 && hour < 21) {
        greeting = 'আসসালামু আলাইকুম / শুভ সন্ধ্যা!';
      } else {
        greeting = 'আসসালামু আলাইকুম কৃষক ভাই!';
      }
    } else {
      if (hour >= 5 && hour < 12) {
        greeting = 'Hello, Good morning!';
      } else if (hour >= 12 && hour < 17) {
        greeting = 'Hello, Good afternoon!';
      } else if (hour >= 17 && hour < 21) {
        greeting = 'Hello, Good evening!';
      } else {
        greeting = 'Hello, Assalamu Alaikum!';
      }
    }

    return '$greeting\n\n$trimmed';
  }

  /// Generate a per-crop, per-day recommendation that the app can show
  /// next to the user's cultivation checklist. Returns a structured
  /// [DailyCropAdvice] the UI can render without parsing prose.
  Future<DailyCropAdvice> getDailyCropAdvice({
    required String cropType,
    required String variety,
    required int dayFromPlanting,
    required String growthStage,
    required List<Map<String, dynamic>> checklist,
    required String weatherSummary,
    double? landAreaDecimal,
    int? numberOfTrees,
    int? deadTrees,
    int? newlyPlantedTrees,
    int? daysRemainingUntilHarvest,
    String? notes,
    void Function({
      required String model,
      required int attemptNumber,
      required bool success,
      String? finishReason,
      String? error,
    })?
    onAttempt,
  }) async {
    if (!isConfigured) {
      throw const GeminiException(
        'Gemini API key not configured. Pass --dart-define=GEMINI_API_KEY=... when running.',
      );
    }

    final doList = checklist
        .where((a) => !(a['isCompleted'] as bool? ?? false))
        .map((a) => '- [TODO] ${a['title']} (Day ${a['dayFromPlanting']})')
        .join('\n');
    final doneList = checklist
        .where((a) => (a['isCompleted'] as bool? ?? false))
        .map((a) => '- [DONE] ${a['title']} (Day ${a['dayFromPlanting']})')
        .join('\n');

    final profile = _cropProfileLine(
      landAreaDecimal: landAreaDecimal,
      numberOfTrees: numberOfTrees,
      deadTrees: deadTrees,
      newlyPlantedTrees: newlyPlantedTrees,
      daysRemainingUntilHarvest: daysRemainingUntilHarvest,
      notes: notes,
    );

    final prompt = _dailyAdvicePrompt(
      cropType: cropType,
      variety: variety,
      dayFromPlanting: dayFromPlanting,
      growthStage: growthStage,
      doList: doList,
      doneList: doneList,
      weatherSummary: weatherSummary,
      cropProfile: profile,
    );

    final raw = await chatCompletion(
      userMessage: prompt,
      history: const [],
      onAttempt: onAttempt,
    );

    return _parseDailyAdvice(raw);
  }

  String _dailyAdvicePrompt({
    required String cropType,
    required String variety,
    required int dayFromPlanting,
    required String growthStage,
    required String doList,
    required String doneList,
    required String weatherSummary,
    String cropProfile = '',
  }) {
    final profileBlock = cropProfile.isEmpty
        ? ''
        : '\n\nFarm profile:\n$cropProfile';
    return '''You are advising a Bangladeshi farmer about their "$variety" $cropType, which is on Day $dayFromPlanting ($growthStage).
$profileBlock

Today's local weather summary: $weatherSummary

Outstanding tasks on the cultivation checklist:
$doList

Already completed today / earlier:
$doneList

Respond with ONLY a single JSON object (no markdown fences, no commentary). The farmer reads this on a phone in the field â€” keep it short and practical. Use Bangla if the crop/variety is Bangla-origin; otherwise use English. Schema:

{
  "guidance": "1-3 sentence summary of today's situation and overall direction. Reference the area / tree count / days-to-harvest whenever they change the advice (e.g. dose per decimal, labour per 100 trees, harvest prep when days remaining <= 7).",
  "do": ["max 4 short imperatives the farmer should DO today"],
  "dont": ["max 4 short imperatives the farmer should AVOID today"]
}

Rules:
- Reference the checklist state â€” if a critical task is already done, don't repeat it.
- Reference the farm profile (area, tree count, days-to-harvest) when relevant. For orchard crops mention per-tree doses; for field crops mention per-decimal doses.
- Mention the weather only if it materially changes a recommendation (e.g. don't irrigate before rain).
- Keep each bullet under 12 words.
- Return JSON only, with no surrounding text.''';
  }

  /// Builds a short, plain-English summary of the crop's scale so the
  /// prompt can reference concrete numbers (area, plant count, harvest
  /// timing) without us having to rewrite the model API for every
  /// field. Returns an empty string when nothing was supplied.
  String _cropProfileLine({
    double? landAreaDecimal,
    int? numberOfTrees,
    int? deadTrees,
    int? newlyPlantedTrees,
    int? daysRemainingUntilHarvest,
    String? notes,
  }) {
    final parts = <String>[];
    if (landAreaDecimal != null && landAreaDecimal > 0) {
      parts.add(
        'Total land: ${landAreaDecimal.toStringAsFixed(2)} decimal '
        '(1 decimal ≈ 40.47 m²).',
      );
    }
    if (numberOfTrees != null && numberOfTrees > 0) {
      final live = numberOfTrees + (newlyPlantedTrees ?? 0) - (deadTrees ?? 0);
      parts.add(
        'Orchard: $numberOfTrees planned trees, ${deadTrees ?? 0} dead, '
        '${newlyPlantedTrees ?? 0} newly planted (≈$live alive).',
      );
    }
    if (daysRemainingUntilHarvest != null) {
      if (daysRemainingUntilHarvest <= 0) {
        parts.add('Harvest window: ready now.');
      } else {
        parts.add('Days to harvest: $daysRemainingUntilHarvest.');
      }
    }
    if (notes != null && notes.trim().isNotEmpty) {
      parts.add('Farmer notes: ${notes.trim()}');
    }
    return parts.join(' ');
  }

  DailyCropAdvice _parseDailyAdvice(String text) {
    String clean = text.trim();
    if (clean.startsWith('```')) {
      clean = clean.replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '');
      clean = clean.replaceAll(RegExp(r'\n?```$'), '');
    }
    final firstBrace = clean.indexOf('{');
    final lastBrace = clean.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace > firstBrace) {
      clean = clean.substring(firstBrace, lastBrace + 1);
    }
    try {
      final json = jsonDecode(clean) as Map<String, dynamic>;
      final doList = (json['do'] as List?) ?? const [];
      final dontList = (json['dont'] as List?) ?? const [];
      return DailyCropAdvice(
        guidance: (json['guidance'] ?? '').toString().trim(),
        doItems: doList.map((e) => e.toString().trim()).toList(growable: false),
        dontItems: dontList
            .map((e) => e.toString().trim())
            .toList(growable: false),
      );
    } catch (_) {
      // Fall back to wrapping the raw text so the UI still has *something*
      return DailyCropAdvice(
        guidance: text.trim(),
        doItems: const [],
        dontItems: const [],
      );
    }
  }

  /// Deterministic fallback used when Gemini is offline / rate-limited.
  /// Crafts simple rule-based advice from the checklist state so the
  /// user still gets actionable bullets instead of an error screen.
  DailyCropAdvice buildOfflineAdvice({
    required String cropType,
    required int dayFromPlanting,
    required List<Map<String, dynamic>> checklist,
  }) {
    final next = checklist.firstWhere(
      (a) => !(a['isCompleted'] as bool? ?? false),
      orElse: () => const {},
    );
    final guidance =
        'Day $dayFromPlanting of your $cropType. Based on your checklist:';
    final doItems = <String>[];
    final dontItems = <String>[];
    if (next.isNotEmpty) {
      doItems.add('Complete: ${next['title']}');
    } else {
      doItems.add('All scheduled activities are done â€” observe the crop.');
    }
    if (dayFromPlanting < 30) {
      dontItems.add('Do not apply heavy fertilizer yet.');
    } else if (dayFromPlanting < 70) {
      dontItems.add('Avoid over-watering; check soil before irrigation.');
    } else {
      dontItems.add('Do not delay harvest â€” monitor maturity daily.');
    }
    return DailyCropAdvice(
      guidance: guidance,
      doItems: doItems,
      dontItems: dontItems,
    );
  }

  /// Generate a per-animal, per-day recommendation that the app shows
  /// next to the user's daily livestock checklist. Returns a
  /// structured [LivestockDailyAdvice] the UI can render without
  /// parsing prose. Falls back to [buildOfflineLivestockGuidance] when
  /// Gemini is unreachable so the farmer always sees actionable bullets.
  Future<LivestockDailyAdvice> getLivestockGuidance({
    required Animal animal,
    required LivestockDailySummary? summary,
    required String weatherSummary,
    void Function({
      required String model,
      required int attemptNumber,
      required bool success,
      String? finishReason,
      String? error,
    })?
    onAttempt,
  }) async {
    if (!isConfigured) {
      return buildOfflineLivestockGuidance(animal: animal, summary: summary);
    }

    final prompt = _livestockGuidancePrompt(
      animal: animal,
      summary: summary,
      weatherSummary: weatherSummary,
    );

    try {
      final raw = await chatCompletion(
        userMessage: prompt,
        history: const [],
        onAttempt: onAttempt,
      );
      return _parseLivestockGuidance(raw);
    } catch (e) {
      developer.log(
        'getLivestockGuidance failed, returning offline advice',
        name: 'GeminiService',
        error: e,
      );
      return buildOfflineLivestockGuidance(animal: animal, summary: summary);
    }
  }

  String _livestockGuidancePrompt({
    required Animal animal,
    required LivestockDailySummary? summary,
    required String weatherSummary,
  }) {
    final species = animal.species;
    final purpose = animal.purpose;
    final day = animal.daysSinceStart;
    final live = animal.liveCount;
    final dead = animal.deadCount;
    final eggs = summary?.eggsToday ?? 0;
    final milk = summary?.milkLitersToday ?? 0;
    final deathsToday = summary?.deathsToday ?? 0;
    final feedKg = summary?.feedKg ?? 0;
    final notes = (summary?.notes ?? animal.notes).trim();
    return '''You are advising a Bangladeshi farmer about their livestock farm.
Species: $species
Purpose: $purpose
Days since start: $day
Live count: $live
Total deaths so far: $dead
Today's deaths: $deathsToday
Today's eggs: $eggs
Today's milk (litres): $milk
Today's feed (kg): $feedKg
Farmer notes: ${notes.isEmpty ? '(none)' : notes}
Local weather: $weatherSummary

Respond with ONLY a single JSON object (no markdown fences, no commentary).
Keep it short and practical for a farmer reading on a phone in Bangla.
Schema:
{
  "guidance": "1-3 sentence summary of today's situation",
  "do": ["max 4 short imperatives the farmer should DO today"],
  "dont": ["max 4 short imperatives the farmer should AVOID today"]
}

Rules:
- Reference the mortality trend and weather only if they materially change
  a recommendation (e.g. biosecurity on rainy days, ventilation in heat).
- Each bullet under 12 words. Use Bangla.
- Return JSON only, with no surrounding text.''';
  }

  LivestockDailyAdvice _parseLivestockGuidance(String text) {
    String clean = text.trim();
    if (clean.startsWith('```')) {
      clean = clean.replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '');
      clean = clean.replaceAll(RegExp(r'\n?```$'), '');
    }
    final firstBrace = clean.indexOf('{');
    final lastBrace = clean.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace > firstBrace) {
      clean = clean.substring(firstBrace, lastBrace + 1);
    }
    try {
      final json = jsonDecode(clean) as Map<String, dynamic>;
      final doList = (json['do'] as List?) ?? const [];
      final dontList = (json['dont'] as List?) ?? const [];
      return LivestockDailyAdvice(
        guidance: (json['guidance'] ?? '').toString().trim(),
        doItems: doList.map((e) => e.toString().trim()).toList(growable: false),
        dontItems: dontList
            .map((e) => e.toString().trim())
            .toList(growable: false),
        source: 'gemini',
      );
    } catch (_) {
      return LivestockDailyAdvice(
        guidance: text.trim(),
        doItems: const [],
        dontItems: const [],
        source: 'gemini-raw',
      );
    }
  }

  /// Deterministic fallback when Gemini is offline / rate-limited /
  /// throws. Crafts rule-based advice from mortality and production
  /// trends so the farmer still gets actionable bullets.
  LivestockDailyAdvice buildOfflineLivestockGuidance({
    required Animal animal,
    required LivestockDailySummary? summary,
  }) {
    final day = animal.daysSinceStart;
    final deathsToday = summary?.deathsToday ?? 0;
    final live = animal.liveCount;
    final species = animal.species;

    final guidance =
        'Day $day of your $species farm. Live animals: $live. '
        'Today\'s deaths: $deathsToday.';

    final doItems = <String>[
      'Provide clean drinking water twice today.',
      'Check feed quality and remove spoiled portions.',
    ];
    final dontItems = <String>[
      'Do not introduce new animals without 7-day quarantine.',
    ];

    if (deathsToday > 0) {
      doItems.add(
        'Isolate sick animals immediately and call a vet if deaths continue.',
      );
      dontItems.add('Do not reuse the same water/feed troughs.');
    }
    if (animal.purpose == AppConstants.purposeEgg) {
      doItems.add('Collect eggs twice daily; store in a cool place.');
    } else if (animal.purpose == AppConstants.purposeDairy) {
      doItems.add('Milk twice daily at fixed times.');
      dontItems.add('Do not milk during heavy rain — udder infection risk.');
    }

    return LivestockDailyAdvice(
      guidance: guidance,
      doItems: doItems,
      dontItems: dontItems,
      source: 'offline',
    );
  }

  // --- Fish & Aquaculture Guidance -------------------------------------------

  Future<FishDailyAdvice> getFishGuidance({
    required FishPond pond,
    required FishDailySummary? summary,
    String? weatherSummary,
  }) async {
    if (!isConfigured) {
      return buildOfflineFishGuidance(pond: pond, summary: summary);
    }
    final prompt = _fishGuidancePrompt(
      pond: pond,
      summary: summary,
      weatherSummary: weatherSummary,
    );
    try {
      final raw = await chatCompletion(userMessage: prompt, history: const []);
      return _parseFishGuidance(raw);
    } catch (e) {
      developer.log(
        'getFishGuidance failed, returning offline guidance',
        name: 'GeminiService',
        error: e,
      );
      return buildOfflineFishGuidance(pond: pond, summary: summary);
    }
  }

  String _fishGuidancePrompt({
    required FishPond pond,
    required FishDailySummary? summary,
    String? weatherSummary,
  }) {
    return '''
You are an expert aquaculture advisor for Bangladesh fish farmers.
Provide daily guidance in Bangla (with English translation) for this fish pond:

Species: ${pond.speciesName} (${pond.speciesId})
Pond Size: ${pond.pondAreaDecimals} decimals, Depth: ${pond.waterDepthFeet} ft
Days of culture: ${pond.daysSinceStocking} / ${pond.targetHarvestDays} days
Live fish count: ${pond.liveCount} (Stocked: ${pond.fingerlingCount}, Dead: ${pond.deadCount})
Feed Type: ${pond.feedType}
Daily Metrics:
- Feed Given Today: ${summary?.feedGivenKg ?? 0} kg
- Dissolved Oxygen: ${summary?.dissolvedOxygenPpm ?? 5.5} ppm
- Water Temperature: ${summary?.waterTempC ?? 28.0} °C
- Swimming Aeration Done: ${summary?.swimmingAerationDone ?? false}
- Weather: ${weatherSummary ?? 'Standard Bangladesh tropical climate'}

Focus heavily on:
1. Exact feeding dosage and timing.
2. Dissolved oxygen management (spreading oxygen by swimming in pond, bamboo agitation, water splashing, avoiding morning hypoxia).
3. Water color / plankton bloom & ammonium prevention.

Respond in valid JSON only:
{
  "guidanceBn": "বাংলায় আজকের মূল দিকনির্দেশনা",
  "guidanceEn": "Today's key guidance in English",
  "oxygenAerationAdviceBn": "সাঁতার কেটে বা বাঁশ পিটিয়ে অক্সিজেন সঞ্চালনের পরামর্শ",
  "oxygenAerationAdviceEn": "Oxygen aeration and water agitation advice",
  "waterQualityTipsBn": "পানির গুণমান ও পিএইচ রক্ষা করার টিপস",
  "waterQualityTipsEn": "Water quality and pH tips",
  "doItems": ["আজ যা করবেন ১", "আজ যা করবেন ২"],
  "dontItems": ["যা করবেন না ১", "যা করবেন না ২"]
}
''';
  }

  FishDailyAdvice _parseFishGuidance(String raw) {
    try {
      final clean = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return FishDailyAdvice(
        guidanceBn: (json['guidanceBn'] ?? '').toString(),
        guidanceEn: (json['guidanceEn'] ?? '').toString(),
        oxygenAerationAdviceBn:
            (json['oxygenAerationAdviceBn'] ?? '').toString(),
        oxygenAerationAdviceEn:
            (json['oxygenAerationAdviceEn'] ?? '').toString(),
        waterQualityTipsBn: (json['waterQualityTipsBn'] ?? '').toString(),
        waterQualityTipsEn: (json['waterQualityTipsEn'] ?? '').toString(),
        doItems: List<String>.from(json['doItems'] ?? const []),
        dontItems: List<String>.from(json['dontItems'] ?? const []),
        source: 'gemini-3.5-flash-lite',
      );
    } catch (_) {
      return const FishDailyAdvice(
        guidanceBn:
            'আজকের আবহাওয়া ও পানির তাপমাত্রা অনুযায়ী সকাল ও বিকালে নির্ধারিত মাত্রায় খাবার দিন এবং পানিতে নেমে অক্সিজেন সঞ্চালন নিশ্চিত করুন।',
        guidanceEn:
            'Feed measured rations in morning and afternoon and ensure oxygen aeration via water agitation.',
        oxygenAerationAdviceBn:
            'পুকুরে সাঁতার কেটে অথবা বাঁশ পিটিয়ে পানির উপরিভাগে ঢেউ তৈরি করুন যাতে দ্রবীভূত অক্সিজেন ৫ পিপিএম এর উপরে থাকে।',
        oxygenAerationAdviceEn:
            'Agitate surface water by swimming or bamboo poles to keep dissolved oxygen above 5 ppm.',
        waterQualityTipsBn:
            'পানির রং হালকা সবুজ রাখুন। অতিরিক্ত শেওলা জমলে চুন বা লবণ প্রয়োগ করুন।',
        waterQualityTipsEn:
            'Maintain light green water color and apply agricultural lime if algal bloom occurs.',
        doItems: [
          'সকাল ৮:০০ ও বিকাল ৪:৩০ টায় সুষম খাবার দিন',
          'ভোরে বা দুপুরে পুকুরে সাঁতার কেটে অক্সিজেন বৃদ্ধি করুন',
        ],
        dontItems: [
          'মেঘলা দিনে বা বৃষ্টিতে অতিরিক্ত খাবার ফেলবেন না',
          'পুকুরে পচা আবর্জনা জমতে দেবেন না',
        ],
        source: 'gemini-3.5-flash-lite',
      );
    }
  }

  FishDailyAdvice buildOfflineFishGuidance({
    required FishPond pond,
    required FishDailySummary? summary,
  }) {
    final species = pond.speciesData;
    final day = pond.daysSinceStocking;
    return FishDailyAdvice(
      guidanceBn:
          'আপনার ${species.nameBn} চাষের $dayতম দিন। পুকুরের আয়তন ${pond.pondAreaDecimals} শতক এবং বর্তমান জীবিত মাছ ${pond.liveCount}টি।',
      guidanceEn:
          'Day $day of ${species.nameEn} culture in ${pond.pondAreaDecimals} decimal pond. Live count: ${pond.liveCount}.',
      oxygenAerationAdviceBn: species.swimmingAerationAdviceBn,
      oxygenAerationAdviceEn:
          'Agitate water to ensure dissolved oxygen remains above ${species.minOxygenPpm} ppm.',
      waterQualityTipsBn:
          'পানির গভীরতা ${pond.waterDepthFeet} ফুট বজায় রাখুন। পানির পিএইচ ৭.৫ থেকে ৮.৫ এর মধ্যে রাখুন।',
      waterQualityTipsEn:
          'Maintain water depth at ${pond.waterDepthFeet} ft and keep pH between 7.5 and 8.5.',
      doItems: [
        'সকাল ${species.optimalFeedingTimes.first} টায় এবং বিকাল ${species.optimalFeedingTimes.length > 1 ? species.optimalFeedingTimes[1] : "04:30 PM"} টায় সুষম ফিড দিন।',
        'পুকুরে নেমে সাঁতার কাটুন অথবা বাঁশ পিটিয়ে অক্সিজেন সঞ্চালন করুন।',
        if ((summary?.deadCount ?? 0) > 0)
          'মৃত মাছ তাৎক্ষণিক অপসারণ করুন ও পুকুরে প্রতি শতকে ১০০ গ্রাম চুন ও ৫০ গ্রাম লবণ দিন।',
      ],
      dontItems: [
        'মাছ খাবি খেলে বা মেঘলা দিনে সম্পূরক খাবার অতিরিক্ত দেবেন না।',
        'পুকুরের তলদেশে বিষাক্ত গ্যাস জমতে দেবেন না।',
      ],
      source: 'offline',
    );
  }

  /// Generate today's AI weather tip for the farmer. The shape is
  /// intentionally close to the per-crop advice so the UI can use
  /// the same `_BulletList` widget. Errors fall through to
  /// [buildOfflineWeatherAdvice] so the card is never empty.
  Future<DailyWeatherAdvice> getDailyWeatherAdvice({
    required Map<String, dynamic> weather,
  }) async {
    if (!isConfigured) {
      return buildOfflineWeatherAdvice(weather: weather);
    }
    final prompt = _weatherAdvicePrompt(weather);
    try {
      final raw = await chatCompletion(userMessage: prompt, history: const []);
      return _parseWeatherAdvice(raw, fallbackWeather: weather);
    } catch (e) {
      developer.log(
        'getDailyWeatherAdvice failed, returning offline advice',
        name: 'GeminiService',
        error: e,
      );
      return buildOfflineWeatherAdvice(weather: weather);
    }
  }

  String _weatherAdvicePrompt(Map<String, dynamic> w) {
    final loc = (w['locationName'] ?? 'your area').toString();
    final temp = (w['temperatureC'] ?? '').toString();
    final feels = (w['feelsLikeC'] ?? '').toString();
    final cond = (w['conditionLabel'] ?? '').toString();
    final humidity = (w['humidity'] ?? '').toString();
    final wind = (w['windKph'] ?? '').toString();
    final rain = (w['precipMm'] ?? w['rainMm'] ?? '').toString();
    return '''You are advising a Bangladeshi farmer about today's weather and how it affects farm work.

Location: $loc
Temperature: $temp°C (feels like $feels°C)
Condition: $cond
Humidity: $humidity %
Wind: $wind km/h
Precipitation (last 24h): $rain mm

Respond with ONLY a single JSON object (no markdown fences, no commentary).
Keep it short and practical for a farmer reading on a phone in Bangla.
Schema:
{
  "headline": "1 short Bangla sentence (<= 8 words) describing today's headline",
  "summary": "2-3 sentence summary in Bangla connecting weather to farm work (irrigation, spraying, harvesting, livestock, drying crops)",
  "do": ["max 4 short imperatives the farmer should DO today"],
  "dont": ["max 4 short imperatives the farmer should AVOID today"]
}

Rules:
- Reference the exact temperature/rain/wind only when they materially change a recommendation.
- Each bullet under 12 words.
- Use Bangla.
- Return JSON only, with no surrounding text.''';
  }

  DailyWeatherAdvice _parseWeatherAdvice(
    String text, {
    required Map<String, dynamic> fallbackWeather,
  }) {
    String clean = text.trim();
    if (clean.startsWith('```')) {
      clean = clean.replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '');
      clean = clean.replaceAll(RegExp(r'\n?```$'), '');
    }
    final firstBrace = clean.indexOf('{');
    final lastBrace = clean.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace > firstBrace) {
      clean = clean.substring(firstBrace, lastBrace + 1);
    }
    try {
      final json = jsonDecode(clean) as Map<String, dynamic>;
      final doList = (json['do'] as List?) ?? const [];
      final dontList = (json['dont'] as List?) ?? const [];
      return DailyWeatherAdvice(
        headline: (json['headline'] ?? '').toString().trim(),
        summary: (json['summary'] ?? '').toString().trim(),
        doItems: doList.map((e) => e.toString().trim()).toList(growable: false),
        dontItems: dontList
            .map((e) => e.toString().trim())
            .toList(growable: false),
        source: 'gemini',
      );
    } catch (_) {
      // Gemini returned non-JSON prose. Wrap it as the summary so the
      // user still sees something useful.
      return DailyWeatherAdvice(
        headline: '',
        summary: text.trim(),
        doItems: const [],
        dontItems: const [],
        source: 'gemini-raw',
      );
    }
  }

  /// Deterministic weather advice based on the same numbers — used
  /// when Gemini is offline so the daily card stays useful.
  DailyWeatherAdvice buildOfflineWeatherAdvice({
    required Map<String, dynamic> weather,
  }) {
    final temp = (weather['temperatureC'] as num?)?.toDouble() ?? 0;
    final humidity = (weather['humidity'] as num?)?.toDouble() ?? 0;
    final rain =
        (weather['precipMm'] as num?)?.toDouble() ??
        (weather['rainMm'] as num?)?.toDouble() ??
        0;
    final wind = (weather['windKph'] as num?)?.toDouble() ?? 0;
    final cond = (weather['conditionLabel'] ?? '').toString().toLowerCase();

    final headline = temp >= 32
        ? 'গরম বেশি — হাইড্রেটেড থাকুন'
        : temp <= 18
        ? 'ঠাণ্ডা আবহাওয়া — গবাদিপশু সুরক্ষা রাখুন'
        : rain > 5
        ? 'বৃষ্টির সম্ভাবনা — স্প্রে স্থগিত রাখুন'
        : 'আবহাওয়া মোটামুটি অনুকূল';

    final summary = StringBuffer(
      'আজ তাপমাত্রা ${temp.toStringAsFixed(0)}°C এবং আর্দ্রতা ${humidity.toStringAsFixed(0)}%। ',
    );
    if (rain > 5) {
      summary.write('বৃষ্টি হতে পারে — সেচ ও স্প্রে এড়িয়ে চলুন। ');
    } else if (temp >= 32) {
      summary.write('রোদ ও গরম বেশি — দিনের মাঝে কঠিন কাজ এড়িয়ে চলুন। ');
    } else {
      summary.write('কাজ চালিয়ে যাওয়ার উপযুক্ত আবহাওয়া। ');
    }
    if (wind >= 25) {
      summary.write('বাতাস বেশি — কীটনাশক স্প্রে স্থগিত রাখুন।');
    }

    final doItems = <String>[];
    final dontItems = <String>[];
    if (rain > 5) {
      doItems.add('ফসলের পানি নিষ্কাশনের ব্যবস্থা করুন।');
      dontItems.add('সেচ বা স্প্রে করবেন না।');
    } else {
      doItems.add('সকালে বা সন্ধ্যায় সেচ দিন।');
    }
    if (temp >= 32) {
      doItems.add('ছায়ায় বিশ্রাম নিন এবং পানি পান করুন।');
      dontItems.add('দুপুর ১১টা–৩টায় ভারী কাজ করবেন না।');
    }
    if (wind >= 25) {
      dontItems.add('কীটনাশক স্প্রে করবেন না।');
    }
    if (humidity >= 80 && (cond.contains('cloud') || cond.contains('মেঘ'))) {
      doItems.add('ছত্রাকনাশক প্রয়োগের জন্য উপযুক্ত সময়।');
    }
    if (doItems.isEmpty) {
      doItems.add('স্বাভাবিক কৃষিকাজ চালিয়ে যান।');
    }
    if (dontItems.isEmpty) {
      dontItems.add('অপ্রয়োজনীয় রাসায়নিক প্রয়োগ এড়িয়ে চলুন।');
    }

    return DailyWeatherAdvice(
      headline: headline,
      summary: summary.toString().trim(),
      doItems: doItems,
      dontItems: dontItems,
      source: 'offline',
    );
  }

  /// Uses Gemini AI to fetch / estimate current realistic market wholesale
  /// and retail prices for 30 to 50 agricultural and food commodities in Bangladesh for [market].
  Future<List<MarketPrice>> fetchMarketPricesWithGemini({
    String market = 'Dhaka',
  }) async {
    if (!isConfigured) return [];

    final prompt = '''
You are an expert Bangladesh Agricultural Market Intelligence AI.
Generate current realistic wholesale and retail market prices for 35 to 50 essential food products and agricultural commodities in Bangladesh (market: $market).

Include a diverse mix across all these categories:
1. Grains & Cereals (ধান ও চাল, গম, আটা, ভুট্টা, পাট)
2. Vegetables (আলু, পেঁয়াজ, রসুন, আদা, কাঁচা মরিচ, টমেটো, বেগুন, ফুলকপি, বাঁধাকপি, করলা, লাউ, পটল, ঢেঁড়শ, শসা, গাজর, মিষ্টি কুমড়া, শাকসবজি)
3. Pulses & Lentils (মসুর ডাল, মুগ ডাল, খেসারি ডাল, ছোলা)
4. Oils & Spices (সরিষার তেল, সয়াবিন তেল, হলুদ, শুকনা মরিচ, জিরা, ধনিয়া)
5. Fruits (কলা, আম, পেয়ারা, পেঁপে, তরমুজ, লেবু, ডাব)
6. Poultry, Meat, Fish & Dairy (ব্রয়লার মুরগি, সোনালী মুরগি, ডিম, গরুর মাংস, খাসির মাংস, রুই মাছ, ইলিশ মাছ, তেলাপিয়া, পাঙ্গাস, গরুর দুধ)

Return ONLY a valid JSON array of objects without markdown fences, in this exact schema:
[
  {
    "commodity": "Miniket Rice",
    "commodityBn": "মিনিকেট চাল",
    "pricePerKg": 74.0,
    "unit": "kg",
    "market": "$market",
    "changePercent": 1.5,
    "category": "Grains"
  },
  {
    "commodity": "Potato",
    "commodityBn": "গোল আলু",
    "pricePerKg": 32.0,
    "unit": "kg",
    "market": "$market",
    "changePercent": -2.0,
    "category": "Vegetables"
  }
]

Ensure pricePerKg reflects realistic Bangladeshi Taka (BDT) rates, unit is appropriate ('kg', 'liter', 'piece', 'dozen', 'hali'), and category is one of ['Grains', 'Vegetables', 'Pulses', 'Spices', 'Fruits', 'Livestock', 'Fish', 'Dairy'].
''';

    final candidates = _getCandidateModels();
    for (final candidate in candidates) {
      try {
        final model = _ensureModel(modelName: candidate);
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim() ?? '';
        if (text.isNotEmpty) {
          final prices = _parseMarketPricesJson(text, market);
          if (prices.isNotEmpty) {
            _workingModel = candidate;
            _model = model;
            _modelNameActive = candidate;
            return prices;
          }
        }
      } catch (e) {
        developer.log(
          'Gemini market price fetch error on $candidate: $e',
          name: 'GeminiService',
        );
      }
    }
    return [];
  }

  List<MarketPrice> _parseMarketPricesJson(String text, String market) {
    String clean = text.trim();
    if (clean.startsWith('```')) {
      clean = clean.replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '');
      clean = clean.replaceAll(RegExp(r'\n?```$'), '');
    }
    try {
      final list = jsonDecode(clean) as List;
      final today = DateTime.now();
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        return MarketPrice(
          id: '${market.toLowerCase()}_${(m['commodity'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}',
          commodity: (m['commodity'] ?? '').toString(),
          commodityBn: (m['commodityBn'] ?? '').toString(),
          pricePerKg: (m['pricePerKg'] as num?)?.toDouble() ?? 0.0,
          unit: (m['unit'] ?? 'kg').toString(),
          market: (m['market'] ?? market).toString(),
          date: today,
          changePercent: (m['changePercent'] as num?)?.toDouble() ?? 0.0,
          category: (m['category'] ?? 'General').toString(),
        );
      }).toList();
    } catch (e) {
      developer.log('Error parsing market prices JSON: $e', name: 'GeminiService');
      return [];
    }
  }

  DiseaseResult _parseDiseaseResponse(String text) {
    String clean = text.trim();
    if (clean.startsWith('```')) {
      clean = clean.replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '');
      clean = clean.replaceAll(RegExp(r'\n?```$'), '');
    }
    try {
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return DiseaseResult.fromGeminiJson({...json, 'raw_text': text});
    } catch (_) {
      return DiseaseResult(
        diseaseName: 'Unknown',
        confidence: 0,
        causes: '',
        prevention: '',
        treatment: '',
        organicSolutions: '',
        chemicalSolutions: '',
        rawText: text,
      );
    }
  }
}

class GeminiException implements Exception {
  const GeminiException(this.message);
  final String message;
  @override
  String toString() => 'GeminiException: $message';
}

/// Structured daily advice returned by [GeminiService.getDailyCropAdvice].
/// Designed to be rendered directly by the crop-detail UI without any
/// prose parsing.
class DailyCropAdvice {
  const DailyCropAdvice({
    required this.guidance,
    required this.doItems,
    required this.dontItems,
  });

  /// 1-3 sentence summary.
  final String guidance;

  /// Action items the farmer should DO today.
  final List<String> doItems;

  /// Action items the farmer should AVOID today.
  final List<String> dontItems;
}

/// Structured daily advice returned by
/// [GeminiService.getLivestockGuidance]. Rendered directly by the
/// livestock detail screen. `source` lets the UI badge the advice as
/// online (Gemini) vs offline (rule-based fallback).
class LivestockDailyAdvice {
  const LivestockDailyAdvice({
    required this.guidance,
    required this.doItems,
    required this.dontItems,
    required this.source,
  });

  final String guidance;
  final List<String> doItems;
  final List<String> dontItems;
  final String source;

  bool get isOffline => source == 'offline';
}

/// Structured daily weather guidance returned by
/// [GeminiService.getDailyWeatherAdvice]. Rendered by the weather
/// screen's AI tip card. `source` lets the UI badge the advice as
/// online (Gemini) vs offline (rule-based fallback).
class DailyWeatherAdvice {
  const DailyWeatherAdvice({
    required this.headline,
    required this.summary,
    required this.doItems,
    required this.dontItems,
    required this.source,
  });

  final String headline;
  final String summary;
  final List<String> doItems;
  final List<String> dontItems;
  final String source;

  bool get isOffline => source == 'offline';
}

/// Structured daily advice returned by [GeminiService.getFishGuidance].
class FishDailyAdvice {
  const FishDailyAdvice({
    required this.guidanceBn,
    required this.guidanceEn,
    required this.oxygenAerationAdviceBn,
    required this.oxygenAerationAdviceEn,
    required this.waterQualityTipsBn,
    required this.waterQualityTipsEn,
    required this.doItems,
    required this.dontItems,
    required this.source,
  });

  final String guidanceBn;
  final String guidanceEn;
  final String oxygenAerationAdviceBn;
  final String oxygenAerationAdviceEn;
  final String waterQualityTipsBn;
  final String waterQualityTipsEn;
  final List<String> doItems;
  final List<String> dontItems;
  final String source;

  bool get isOffline => source == 'offline';
}

