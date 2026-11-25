# Smart Agri BD (স্মার্ট এগ্রি)

AI-powered, bilingual (বাংলা / English) agriculture assistant for farmers in
Bangladesh, covering crops, fish ponds, livestock and farm accounts in one app.
Prepared for **AETHERMIND 2026: The National Innovation Challenge**.

## Features

| Area | What it does |
|------|--------------|
| AI disease detection | Photograph a leaf and get step-by-step diagnosis and treatment, with Bangla voice readout and offline history |
| Krishi Sahayak chatbot | Farming questions answered by Google Gemini, with automatic model fallback |
| Crop tracking | Bangladesh crop catalogue, activity calendar, live tracking and daily AI suggestions |
| Fish ponds | Pond records, activity plan, live tracking and feeding guidance |
| Livestock and poultry | Herd records, vaccination and care schedule, daily suggestions |
| Feeding alarms | Loud reminders at feeding times |
| Weather | Open-Meteo current conditions, 7-day forecast and farming advice |
| Smart irrigation | Soil moisture and water requirement calculator |
| Yield forecaster | Estimated production, revenue and profit |
| Market prices | Commodity prices with search and filters |
| Farm records | Expenses and accounting |
| Community feed | Farmer posts, photos, likes and comments |
| Krishi helpline | 16123 hotline and officer directory |
| Everyday use | Offline-first storage and sync, notifications, onboarding, tutorial, light and dark themes, animated or low-end static mode |

## Tech stack

Flutter and Provider · Hive (offline storage) · Firebase Auth, Firestore and
Storage · Google Gemini · Open-Meteo · optional PHP backend with SQLite or MySQL.

## Project layout

```
lib/
  core/        theme, routes, configuration, shared widgets
  data/        models, repositories, services
  features/    one folder per feature (screens and state)
SmartAgriServer/   optional PHP backend
test/              unit and widget tests
```

## Setup

Requires Flutter 3.44 or newer and Android Studio or Xcode.

```bash
flutter pub get
cp .env.example .env      # Windows: copy .env.example .env
flutter run --dart-define-from-file=.env
```

Release build:

```bash
flutter build apk --release --dart-define-from-file=.env
```

## Keys you add yourself

No keys or secrets are stored in this repository.

| What | Where |
|------|-------|
| Gemini API key | `GEMINI_API_KEY` in `.env` |
| Backend URL and secret (optional) | `SERVER_BASE_URL`, `SMART_AGRI_SECRET` in `.env` |
| Firebase API keys | `lib/firebase_options.dart`, or run `flutterfire configure` |
| Firebase Android config | `android/app/google-services.json` |
| Firebase iOS config | `ios/Runner/GoogleService-Info.plist` |
| Release signing (optional) | `android/key.properties` and your keystore |

`.env`, the Firebase config files and signing files are ignored by git.
`lib/firebase_options.dart` is tracked, so **do not commit your real keys in it**:

```bash
git update-index --skip-worktree lib/firebase_options.dart
```

Firebase is required for sign-in, cloud sync and the community feed. In the
Firebase console enable Email/Password and Google sign-in, Firestore and
Storage, then deploy `firestore.rules` and `storage.rules`.

Anything built into the app (including `GEMINI_API_KEY`) can be extracted from
the APK. For a public release, use the backend so the key stays on the server,
and leave `GEMINI_API_KEY` empty.

## Optional backend

See [SmartAgriServer/README.md](SmartAgriServer/README.md). It keeps the Gemini
key on the server and limits disease scans to 2 per user per day. Without it the
app calls Gemini directly and applies a 20 requests per day limit on the device.

## Tests

```bash
flutter analyze
flutter test
```

GitHub Actions runs analysis, tests and a debug APK build on every push to `main`.
