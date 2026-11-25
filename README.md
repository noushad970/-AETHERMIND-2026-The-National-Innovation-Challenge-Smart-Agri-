# Smart Agri BD (স্মার্ট এগ্রি)

AI-powered, bilingual (বাংলা / English) agriculture assistant for farmers in
Bangladesh. Built with Flutter. Prepared for **AETHERMIND 2026: The National
Innovation Challenge**.

> Status: features are being added one at a time. Each commit on `main` adds one.

## Features

| # | Feature | Status |
|---|---------|--------|
| 1 | Project foundation, theme, language and animation settings | Done |

## Requirements

- Flutter 3.44 or newer (Dart 3.12 or newer)
- Android Studio or Xcode for mobile builds

## Setup

```bash
flutter pub get
cp .env.example .env      # Windows: copy .env.example .env
flutter run --dart-define-from-file=.env
```

## Keys you add yourself

No keys or secrets are stored in this repository.

| What | Where |
|------|-------|
| Gemini API key | `GEMINI_API_KEY` in `.env` |
| Backend URL and secret (optional) | `SERVER_BASE_URL`, `SMART_AGRI_SECRET` in `.env` |
| Firebase API keys | `lib/firebase_options.dart`, or run `flutterfire configure` |
| Firebase Android config | `android/app/google-services.json` |
| Release signing (optional) | `android/key.properties` and your keystore |

Everything in the table except `lib/firebase_options.dart` is ignored by git.
Keep your real `firebase_options.dart` values out of commits.
