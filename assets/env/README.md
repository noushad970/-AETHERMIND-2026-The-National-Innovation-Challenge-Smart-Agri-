# Local settings

Copy `.env.example` from the project root to `assets/env/app.env` and fill in
your values. The app reads that file when it starts.

Everything in this folder except this note is ignored by git. Never commit your
keys: the repository is public. The file is packaged into the app, so anyone who
has a build can read it.
