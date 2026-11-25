# AI Agriculture Assistant for Bangladesh — Full App Documentation

> **Repository:** `smart-agro-by-flutter` (owner: `noushad970`)
> **App package id:** `com.bdapps.smartagri.ai_agri_assistant`
> **App name:** `ai_agri_assistant` (marketing: *AI Agriculture Assistant for Bangladesh*)
> **Publisher:** BD Apps · **Version:** `1.0.0+1`
> **Dart SDK:** `^3.11.0` (Flutter `^3.41.1`)
> **Target platforms:** Android, iOS, Web (Flutter cross-platform)

---

## 1. Project Mission

A mobile-first, AI-powered digital farming companion for smallholder farmers in Bangladesh. The app combines **crop lifecycle management**, **AI image-based disease diagnosis**, **a conversational AI agronomist**, **weather-driven agronomy advice**, **live market prices**, **livestock & poultry tracking**, and **farm expense bookkeeping** into a single app — built to work **online or offline**.

The primary outcomes targeted by the product:

- Help farmers identify crop diseases and pest attacks early via AI image recognition.
- Reduce guess-work around irrigation, fertilization, and harvesting with auto-generated cultivation calendars.
- Surface *actionable* weather and market information localized to Bangladesh (Dhaka, Chittagong, Khulna, Rajshahi, …).
- Provide offline access to essential farming guides so the app remains useful in low-connectivity rural areas.

---

## 2. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                          Flutter UI (lib/)                       │
│   MaterialApp + Provider  ·  Feature-first folders under lib/    │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│            State / Providers (ChangeNotifier per feature)        │
│  AuthProvider · CropsProvider · ChatbotProvider ·                │
│  WeatherProvider · MarketPricesProvider · LivestockProvider ·    │
│  DiseaseDetectionProvider · DailySuggestionsProvider · …         │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌─────────────┬──────────────▼─────────────┬──────────────────────┐
│  Services   │      Repositories          │    Remote APIs        │
│ (lib/data)  │     (lib/data)             │                       │
│             │                            │                       │
│ • auth      │ • crop_repository          │ • Firebase Auth       │
│ • gemini    │ • livestock_repository     │ • Cloud Firestore     │
│ • weather   │ • daily_suggestion_repo    │ • Firebase Storage    │
│ • market    │ • livestock_daily_sug_rep  │ • FCM                 │
│ • notif.    │ • weather_daily_advice     │ • Gemini (Google)     │
│ • realtime  │                            │ • Open-Meteo          │
│   services  │                            │ • DAM (moa-services)  │
└─────────────┴────────────────────────────┴──────────────────────┘
```

### Architectural choices

- **Feature-first folders** under `lib/features/<name>/{data, presentation/{providers, screens, widgets}}`. Cross-cutting code lives under `lib/core/{config, constants, routes, theme, utils, widgets}` and `lib/data/{models, repositories, services}`.
- **Provider** (`package:provider`) for state management — one `ChangeNotifier` per feature, wired through a top-level `MultiProvider` in `main.dart`.
- **Realtime Firestore streams** (`*RealtimeService`) share a single listener per collection, multiplexed into UI providers via `ChangeNotifierProxyProvider` so screens don't open duplicate snapshots.
- **Graceful degradation** — Firebase init is wrapped in `try/catch`; on failure the app surfaces a startup banner and continues in *local-only* mode (Hive-style cache + offline guides).
- **Local persistence** — Hive (with `@HiveType` models and `build_runner` adapters) for crops, activities, expenses, market-price cache, chat history.

---

## 3. Technology Stack

### 3.1 Frontend / Mobile (Flutter, Dart 3.11+)

| Concern              | Library / API                                  |
| -------------------- | ---------------------------------------------- |
| UI framework         | Flutter (Material 3, custom `AppTheme.lightTheme`) |
| State management     | `provider` ^6.1.2 (`ChangeNotifier` per feature) |
| Routing              | Named routes via `AppRouter.generate` + `AppRoutes` constants |
| Local DB / cache     | Hive (with `build_runner` generated adapters)   |
| Internationalization | `intl` ^0.20.2                                 |
| Fonts                | `NotoSansBengali` (full Bangla variable font)   |
| Image loading        | `cached_network_image` ^3.4.1                  |
| Permissions          | `permission_handler` ^11.3.1                   |

### 3.2 Firebase Backend (optional cloud sync)

| Service              | Library                                          |
| -------------------- | ------------------------------------------------ |
| Firebase Core        | `firebase_core` ^3.6.0                           |
| Authentication       | `firebase_auth` ^5.3.1                           |
| Cloud Firestore      | `cloud_firestore` ^5.4.4 (realtime collections) |
| File Storage         | `firebase_storage` ^12.3.4 (disease images)      |
| Cloud Messaging      | `firebase_messaging` ^15.1.3 (push, future use)  |

- Android config wired via `google-services` plugin (`com.google.gms.google-services 4.5.0`) and `firebase-bom 34.17.0`.
- `compileSdk`/`targetSdk` lifted to **36**, Kotlin 2.3 (JVM target 17), `coreLibraryDesugaring` enabled for `flutter_local_notifications`.

### 3.3 Artificial Intelligence

| Capability                       | Backend                                                              |
| -------------------------------- | -------------------------------------------------------------------- |
| Cloud disease detection (image)  | **Google Gemini** (`google_generative_ai` ^0.4.7), model `gemini-3.5-flash-lite` (override via `--dart-define=GEMINI_MODEL=…`). JSON-structured Bangla response with confidence, causes, prevention, organic & chemical treatment. |
| On-device disease detection      | **TensorFlow Lite** (`tflite_flutter`), input `EfficientNetB0` (~17 MB) flattened into `assets/models/disease_model.tflite`. Used when offline or as a fast pre-filter. |
| Chatbot (English today, planned Bangla) | Gemini with multi-model fallback (`gemini-3.5-flash-lite`, `gemini-flash-latest`). System prompt enforces farming-domain guidance. |
| Daily AI suggestions             | Gemini, generated once per day per crop / per animal and cached under `users/{uid}/crops/{cropId}/daily_suggestions/{dateKey}`. |
| Voice input                      | `speech_to_text` ^7.0.0 (for chatbot)                                |

> **Note** — A genuine Gemini key is supplied at runtime via `--dart-define=GEMINI_API_KEY=…`. There is a hardcoded fallback key in `gemini_service.dart` for development convenience; replace before any public release.

### 3.4 Maps, Weather, Location

| Capability                | Provider                                                  |
| ------------------------- | --------------------------------------------------------- |
| Forecast / current weather | **Open-Meteo** (`https://api.open-meteo.com/v1`) — no key required |
| Reverse geocoding         | **Open-Meteo Geocoding** + hard-coded nearest-city fallback for Bangladesh |
| Device location           | `geolocator` ^13.0.1                                     |
| Map rendering             | `flutter_map` ^7.0.2 + `latlong2` ^0.9.1 (OpenStreetMap tiles) |

### 3.5 Notifications

- `flutter_local_notifications` ^17.2.3 + `timezone` ^0.9.4
- Android channel `farming_reminders` (high importance); iOS requests alert/badge/sound permission.
- Scheduling is zoned (`tz.TZDateTime`) so reminders fire at the user's wall-clock time even across DST boundaries.

### 3.6 Networking

- `http` ^1.2.2 for all REST calls (Gemini, Open-Meteo, DAM market scrape, BD Apps OTP/subscription servers).
- `url_launcher` ^6.3.1 to open external resources (extension officer links, etc.).

### 3.7 Lints / DX

- `flutter_lints` ^6.0.0 — strict Flutter lint preset.
- `analysis_options.yaml` excludes `build/`, `android/`, `ios/`, `web/` from analyzer.

---

## 4. Folder / Module Map

```
lib/
├── core/
│   ├── config/        AppConfig (feature flags, cache TTLs, image-size limits)
│   ├── constants/     AppConstants (Firestore paths, API URLs, crop defaults)
│                     AppStrings (user-facing copy)
│   ├── routes/        AppRoutes (named route constants) + AppRouter (generator)
│   ├── theme/         AppTheme.lightTheme
│   ├── utils/         validators, helpers
│   └── widgets/       AuthGate (protects auth-required screens) + shared widgets
│
├── data/
│   ├── models/        Crop, CropActivity, Animal, ChatMessage,
│   │                  DiseaseResult, Expense, MarketPrice, WeatherData,
│   │                  DailySuggestion, LivestockDailySuggestion, LivestockDailySummary,
│   │                  WeatherDailyAdvice
│   ├── repositories/  crop_repository, livestock_repository,
│   │                  daily_suggestion_repository,
│   │                  livestock_daily_suggestion_repository,
│   │                  weather_daily_advice_repository
│   └── services/      auth_service, firestore_sync_service,
│                      crops_realtime_service, livestock_realtime_service,
│                      livestock_children_service,
│                      crop_daily_suggestion_service,
│                      chat_realtime_service,
│                      expenses_realtime_service,
│                      crop_template_service,
│                      daily_suggestion_update_service,
│                      gemini_service, weather_service,
│                      market_price_service, notification_service
│
├── features/
│   ├── splash/auth    SplashScreen, LoginScreen, RegisterScreen, AuthProvider
│   ├── home           HomeScreen (dashboard)
│   ├── crop_tracker/  AddCrop, CropList, CropDetail, CropLiveTrack
│   ├── livestock/     AddLivestock, LivestockList, LivestockDetail, LivestockLiveTrack
│   ├── ai_disease/    DiseaseDetect (camera/gallery), DiseaseResult (Gemini + TFLite)
│   ├── ai_chatbot/    ChatbotScreen (Gemini chat + speech-to-text)
│   ├── chatbot/       (older chat UI kept alongside)
│   ├── weather/       WeatherScreen (current + 7-day) + WeatherDailyAdvice
│   ├── market_prices/ MarketPricesScreen (DAM scrape with cache + mock fallback)
│   ├── farm_records/  FarmRecordsScreen, ExpenseListScreen, AddExpenseScreen
│   └── notifications/ NotificationsScreen (upcoming reminders)
│
├── firebase_options.dart   generated by `flutterfire configure`
└── main.dart               entrypoint + MultiProvider wiring
```

---

## 5. Feature Inventory (what the app does today)

### 5.1 Authentication & Onboarding
- **Email + password** sign-up / sign-in via Firebase Authentication.
- **Splash → Login/Register → Home** flow, with `AuthGate` guarding screens that require sign-in (chatbot, saved history).
- **Graceful Firebase-init failure**: a red overlay banner guides developers to run `flutterfire configure` instead of crashing silently.

### 5.2 Home Dashboard
- Single landing surface linking into every module: crop tracker, livestock, disease detection, chatbot, weather, market prices, farm records, notifications.

### 5.3 Crop Growth Tracker *(core feature)*
- Add a crop by selecting from **Rice, Wheat, Tomato, Potato, Mango, Banana, Jute, Maize, Lentil, Onion** (configurable in `AppConstants.commonCrops`).
- Inputs: planting date, land area, number of trees (for orchards), optional variety.
- `CropTemplateService` auto-generates the full cultivation timeline (e.g. for a 90-day rice variety: Day 1 land prep → Day 2 plant → Day 7 first irrigation → Day 15 weeding → Day 20 fertilizer → Day 35 pest inspection → Day 45 second fertilizer → Day 60 disease monitoring → Day 80 maturity check → Day 90 harvest).
- Per crop, the app tracks:
  - Days remaining until harvest.
  - Current growth stage.
  - Completed vs upcoming activities.
  - Estimated harvest date.
  - Crop health status (driven by `DailySuggestionsProvider`).
- For orchards (Mango, Banana): per-tree status (alive / dead / new).
- `CropLiveTrackScreen` is a count-down UI showing today's pending activities and a live progress wheel.

### 5.4 Livestock & Poultry Tracker
- Supported species: **Poultry chicken (broiler/meat), Egg chicken (layer), Duck, Cow, Goat, Sheep**.
- Each animal carries a *purpose*: `meat`, `egg`, `dairy`, or `mixed`. The UI prevents nonsensical pairings (no "Egg" for a cow).
- Default activity templates are species-and-purpose aware:
  - Layers → daily egg-collection tasks.
  - Broilers → weight-check tasks.
  - Dairy → milking tasks.
- Children (`LivestockChildrenService`) track offspring (chicks, calves, kids, lambs) with their own activity templates.
- `LivestockLiveTrackScreen` mirrors the crop live tracker with a daily checklist.

### 5.5 AI Crop Disease Detection (`ai_disease/`)
- Two inference backends:
  1. **Cloud**: send image bytes to Gemini, get a structured Bangla-language JSON report (disease name, confidence score, possible causes, prevention, organic & chemical treatment).
  2. **On-device**: TensorFlow Lite model (`assets/models/disease_model.tflite`) for offline use. Trained classifier targets **28 classes** common to Bangladesh (rice blast, brown planthopper, tomato late blight, …).
- Image source: camera or gallery (`image_picker`). Max upload size 10 MB (`AppConfig.maxImageSizeBytes`).
- A minimum confidence gate (`0.4`) filters low-quality predictions.
- All scans are logged to `users/{uid}/disease_scans` for later reference.

### 5.6 AI Agricultural Chatbot (`ai_chatbot/` + `chatbot/`)
- Text and voice (`speech_to_text`) input.
- Gemini answers in conversational English (Bangla is on the roadmap, see §8) about irrigation schedules, fertilizer selection, pest control, weather-day decisions, etc.
- Multi-model fallback (`gemini-3.5-flash-lite`, `gemini-flash-latest`) for resilience against single-model rate-limits or deprecation.
- Conversation history is persisted under `users/{uid}/chat_threads/{threadId}/messages/{messageId}` (Firestore) and locally in Hive.
- Capped at `maxChatHistoryMessages = 50` for performance.

### 5.7 Weather (`weather/`)
- Current + **7-day forecast** from Open-Meteo (no API key needed).
- Location: device GPS via `geolocator`, with graceful permission denial.
- Reverse geocoding uses Open-Meteo's geocoding API with a hard-coded nearest-city fallback for Bangladesh (works on Flutter Web where the upstream `/reverse` endpoint lacks CORS headers).
- `WeatherDailyAdviceProvider` produces day-by-day agronomy advice (e.g. "good day to spray — low wind, no rain expected in next 24 h") and caches it under `users/{uid}/weather_daily_advice`.

### 5.8 Market Prices (`market_prices/`)
- Scrapes **Department of Agricultural Marketing (DAM)** daily wholesale prices from `moa-services.com` for Dhaka (other divisions fall back to "all divisions" until DAM IDs are confirmed).
- Resolution order:
  1. Today-cached Firestore entries.
  2. Live DAM scrape → persisted to `users/{uid}/marketPrices/{dateKey}`.
  3. Most-recent Firestore entries (any age).
  4. Built-in mock dataset so the UI is never empty.
- Rows are labelled **Live / Cached / Sample data** so the user knows the freshness.
- Search + filter UI on `MarketPricesScreen`.

### 5.9 Farm Records / Expense Tracking (`farm_records/`)
- Log expenses by category (seeds, fertilizer, pesticide, labor, equipment, transport, …) and month.
- `FarmRecordsScreen` shows a dashboard summary; `ExpenseListScreen` lists all entries; `AddExpenseScreen` captures a new one.
- Persisted to Firestore under `users/{uid}/expenses` with a Hive mirror for offline reads.

### 5.10 Notifications / Reminders (`notifications/`)
- `NotificationService.scheduleActivityReminder(CropActivity)` schedules a zoned local notification at each activity's `scheduledDate`.
- Android 12+ requests `SCHEDULE_EXACT_ALARM` so reminders fire on time.
- `NotificationsScreen` lists upcoming reminders in one place.

### 5.11 Daily AI Suggestions (cross-cutting)
- `DailySuggestionUpdateService` runs on login and every 30 minutes while the app is open.
- For each crop **and** each animal it ensures today's AI suggestion exists in Firestore, regenerating only when the day's plan changes (e.g. when the user toggles a checklist item — the livestock provider triggers a stale-marking hook that calls `ensureToday()`).

---

## 6. External Services & Integrations

| Service                          | Purpose                                                        | Auth surface                                                                  |
| -------------------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| **Firebase Auth**                | Email/password sign-in                                         | App-side                                                                      |
| **Cloud Firestore**              | Real-time user data (crops, livestock, chat, scans, expenses, market cache, daily suggestions) | Per-user security rules in `firestore.rules` (see §7)                        |
| **Firebase Storage**             | Disease-leaf image uploads (optional)                          | App-side                                                                      |
| **Firebase Cloud Messaging**     | Reserved for future push (reminders, weather alerts, market alerts) | App-side                                                                      |
| **Google Gemini API**            | Disease detection, chatbot, daily AI suggestions               | `GEMINI_API_KEY` passed via `--dart-define`                                   |
| **Open-Meteo**                   | Weather forecast + geocoding                                   | None (free tier)                                                              |
| **DAM (`moa-services.com`)**     | Daily wholesale market prices                                  | None                                                                          |
| **OpenStreetMap tiles**          | Map rendering in weather screen                                | None (attribution)                                                            |
| **BD Apps Telco (server/*.php)** | OTP sign-in, subscription status, USSD, SMS, SDK helpers        | `APP_139125` application id + password (currently stub PHP that talks to `developer.bdapps.com`) |

### BD Apps server endpoints (`server/`)
The repo ships PHP glue for the **BD Apps Telco platform** (a Bangladesh telco VAS integration):
- `send_otp.php` → initiates OTP sign-in via `https://developer.bdapps.com/subscription/otp/request`.
- `verify_otp.php` → verifies OTP against `https://developer.bdapps.com/subscription/otp/verify`.
- `check_subscription.php` → `subscription/getStatus`.
- `subscribe.php` / `unsubscribe.php` → subscription management.
- `subscription_listener.php` → inbound telco notification webhook.
- `sms.php` → outbound SMS via `https://developer.bdapps.com/sms/send`.
- `ussd.php` → USSD session handler (uses `sdk_file.php`).
- `sdk_file.php` → BD Apps PHP SDK wrappers (`SmsSender`, `UssdSender`, `Subscription`, `UssdReceiver`).

> **Status:** these endpoints are wired server-side but are **not yet called from the Flutter app** — the auth path is currently Firebase-only. They exist for the planned BD Apps phone-number sign-in + premium subscription tier (§8).

---

## 7. Data Model & Security

### Firestore schema (per authenticated user)

```
users/{uid}/
├── crops/{cropId}
│   ├── activities/{activityId}               (subcollection – planned)
│   └── daily_suggestions/{dateKey}          (AI suggestions, one per day)
├── expenses/{expenseId}
├── chat_threads/{threadId}
│   └── messages/{messageId}
├── disease_scans/{scanId}
├── livestock/{animalId}
│   ├── livestock_activities/{activityId}
│   ├── livestock_daily_summaries/{dateKey}
│   └── livestock_daily_suggestions/{dateKey}
└── marketPrices/{dateKey}
```

All collections are guarded by `firestore.rules`:

- `request.auth != null` **and** `request.auth.uid == uid` (the `{uid}` path segment must match the caller's UID).
- No admin SDK in the app, no blanket writes, default-deny for unmatched paths.
- This means a compromised token cannot read another farmer's data even if it knows their UID.

### Local persistence

- Hive boxes mirror the same collections (crops, activities, expenses, chat history, market-price cache) so the app is responsive offline and survives restarts.
- All `@HiveType` models regenerate via `flutter pub run build_runner build --delete-conflicting-outputs`.

---

## 8. Roadmap / Future Implementations

These items are listed in `Details/AI Agriculture Assistant for Bangladesh.md` and confirmed by code shape (e.g. `firebase_messaging` is already a dependency; `tflite_flutter` is ready for the offline model):

### Near-term
- **BD Apps phone-number sign-in** — flip from Firebase-only to OTP via the bundled PHP endpoints (`server/send_otp.php` + `verify_otp.php`).
- **BD Apps subscription integration** — `check_subscription.php` + `subscribe.php` for a premium AI tier.
- **Bangla language for the chatbot** — the Gemini system prompt already supports locale switching; UI strings will move through `AppStrings`.
- **Bangla voice assistant** — full speech-to-text + speech-to-speech in Bangla (already enabled via `AppConfig.enableBanglaVoice`).
- **On-device TensorFlow Lite disease model rollout** — `assets/models/disease_model.tflite` and `labels.json` are wired through the `DiseaseClassifier`; once the trained weights are exported by `AI Model/scripts/convert_to_tflite.py` the offline path becomes first-class.
- **Firebase Cloud Messaging push** — push-based weather alerts, market-price spikes, and outbreak warnings.
- **Multi-language support** beyond Bangla/English (Hindi, Burmese, Nepali — common in cross-border farming communities).
- **Yield prediction** — Gemini-driven harvest-yield estimator using crop variety + area + weather history.

### Medium-term
- **Satellite crop monitoring** — Sentinel-2 / NASA Harvest NDVI integrations to flag field stress.
- **IoT sensor integration** — soil moisture, pH, NPK probes via BLE / MQTT to feed the daily AI suggestions.
- **Drone-based crop inspection** — orthomosaic upload + AI analysis.
- **Soil health analysis** — lab-report OCR + recommendation engine.
- **Agricultural marketplace** — direct farmer → buyer listings, with the existing `MarketPricesScreen` becoming a "what to sell" decision aid.
- **Government subsidy & loan information** — localized alerts tied to farmer profile (district, crop, area).

### Long-term
- **Cooperative & farmer community platform** — chat groups, knowledge-sharing boards, peer-to-peer mentorship.
- **Offline-first push sync** — every feature (including chat, disease detection, market prices) works fully without connectivity, syncing on reconnection.
- **Cross-border deployment** — India, Nepal, Sri Lanka, Myanmar with localized crop libraries and price feeds.

---

## 9. Build, Run, Distribute

### Common scripts
```bash
flutter pub get                                          # install Dart/Flutter deps
flutter analyze                                          # static analysis
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY        # dev run
flutter build apk --release --dart-define=GEMINI_API_KEY=YOUR_KEY
flutter build ios --release --dart-define=GEMINI_API_KEY=YOUR_KEY
flutter pub run build_runner build --delete-conflicting-outputs  # regen Hive adapters
```

### Machine-learning rebuild
```bash
cd "AI Model"
python scripts/convert_to_tflite.py        # writes assets/models/{disease_model.tflite, labels.json}
```

### Firebase reconfiguration
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

### Required Android permissions
| Permission                                | Why                                              |
| ----------------------------------------- | ------------------------------------------------ |
| `INTERNET`                                | Open-Meteo, Gemini, Firebase, DAM                |
| `ACCESS_FINE_LOCATION`                    | Local weather lookup                             |
| `CAMERA` / `READ_MEDIA_IMAGES`            | Disease-detection leaf photo                     |
| `RECORD_AUDIO`                            | Voice input to the chatbot                       |
| `POST_NOTIFICATIONS`                      | Local activity reminders                         |
| `SCHEDULE_EXACT_ALARM` (Android 12+)      | Reliable reminder delivery                       |

---

## 10. Known Limitations & Disclaimers

- **Weather & market prices require internet.** Market screen falls back to the last Hive-cached snapshot on failure.
- **Disease detection is advisory only.** Always confirm with a local agricultural extension officer before applying pesticides.
- **Placeholder `firebase_options.dart`** is for project `smart-agro-f5aec` with empty keys — run `flutterfire configure` before shipping.
- **Hardcoded Gemini key** in `gemini_service.dart` is for development; replace via `--dart-define=GEMINI_API_KEY=…` for production.
- **Hive adapters** must be regenerated after any `@HiveType` model change.
- **Telco (BD Apps) PHP endpoints** are stubbed and not yet called from the Flutter app — they exist for the planned OTP / subscription integration.

---

## 11. Expected Impact

By combining AI image diagnosis, conversational agronomy advice, automated cultivation calendars, weather-aware recommendations, and live market intelligence into a single app usable offline, the AI Agriculture Assistant aims to:

- **Increase yields** through timely, data-driven decisions on irrigation, fertilization, and harvest.
- **Reduce crop losses** via early disease detection and pest scouting.
- **Lower production costs** by avoiding unnecessary pesticide / fertilizer use.
- **Modernize smallholder farming** in Bangladesh with a smartphone-first UX that respects low-connectivity realities.

With the planned BD Apps phone verification + premium subscription, plus the ML / IoT / satellite roadmap, the platform can evolve into a comprehensive **smart-farming ecosystem** for Bangladesh and other agriculture-focused regions.
