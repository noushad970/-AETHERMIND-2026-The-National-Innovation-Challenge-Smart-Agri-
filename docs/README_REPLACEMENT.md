# README Replacement

The canonical project documentation now lives in the root
[`README.md`](../README.md). This file historically served as a drop-in
replacement when the root README lagged behind the codebase; that gap no
longer exists.

The project is **Cloud Firestore only** — there is no local database
(Hive, SQLite, or shared_preferences are not used). All user data
(crops, livestock, farm records, chat history, AI daily advice, disease
scans, market-price cache) is stored per-user under `users/{uid}` and
accessed through realtime Firestore streams. See the root README for:

- Setup (Flutter deps, Firebase + `firestore.rules` deployment, Gemini key)
- The complete Firestore schema and how reads/writes work
- The offline TensorFlow Lite disease model (see also
  [`docs/ML_MODEL.md`](ML_MODEL.md))
- Permissions and project layout
