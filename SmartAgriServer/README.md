# Smart Agri Dedicated Backend Server

This is the dedicated backend server for the **Smart Agri** mobile application. It securely handles:
1. **Google Gemini AI Processing**: Your Gemini API key is stored safely on this server and is never exposed in client application binaries.
2. **Crop Disease Image Upload Limitation**: Enforces a strict daily limit of **maximum 2 crop disease image uploads per user per day**.
3. **Sequential Step-by-Step AI Guidance**: Replaces dense technical jargon with sequential numbered steps (`Step 1`, `Step 2`, `Step 3`... and `ধাপ ১`, `ধাপ ২`, `ধাপ ৩`...) so farmers can easily follow advice in the field.
4. **Bilingual Support**: Returns advice in both **English** and **Bangla**.
5. **Fast Local Data Persistence**: Coordinates with the mobile app's **Hive** local cache.
6. **Maximum Security**: Protected with request secret verification (`X-SmartAgri-Secret`), IP rate limiting, input sanitization, and hidden `.htaccess` rules.

---

## 🚀 How to Upload to cPanel

1. In cPanel File Manager, create `public_html/SmartAgriServer/`.
2. Upload the contents of this `SmartAgriServer/` folder into it.
3. Set your secrets (see below). Protected routes answer `503` until a secret is set.
4. Open `https://yourdomain.com/SmartAgriServer/test_api.php` to check the server,
   database and AI configuration, then delete or restrict that file.

Point the app at the server with `SERVER_BASE_URL=https://yourdomain.com/SmartAgriServer/api`
and the same `SMART_AGRI_SECRET` in the app's `.env` file.

---

## ⚙️ Configuration (`config.php`)

All settings are in `config.php`:
- `gemini.api_key`: Your Google Gemini API key (or the `GEMINI_API_KEY` environment variable). Empty in this repository.
- `app_secret`: A long random string you choose (or `SMART_AGRI_SECRET`). The app sends it as `X-SmartAgri-Secret`. Empty in this repository.
- `disease_limits.max_scans_per_user_per_day`: Set to `2` by default.
- `database.type`: Set to `'sqlite'` by default (works with 0 configuration on cPanel). If you ever want MySQL, simply change to `'mysql'` and enter your MySQL credentials.

> Never commit your real key or secret to a public repository.
