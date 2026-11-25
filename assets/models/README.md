# `assets/models/`

This directory is where the on-device disease-detection model lives after
the one-time conversion step. After running `convert_to_tflite.py` you
should see two files here:

- `disease_model.tflite` — the TensorFlow Lite flatbuffer (~17 MB).
- `labels.json` — the 28 class names exported by the training script.

Until both files are present, the Flutter app falls back to the Gemini
cloud model (or surfaces a "no model available" message if no Gemini key
is set).

To regenerate after retraining:

```sh
cd "AI Model"
python scripts/convert_to_tflite.py
flutter pub get
```

See `docs/ML_MODEL.md` for the full conversion + run guide.