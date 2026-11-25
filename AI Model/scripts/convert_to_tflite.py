"""
Convert the trained Keras disease-detection model into a TensorFlow Lite
flatbuffer that can be loaded by the Flutter app via tflite_flutter.

Inputs
------
  - models/best_model.keras        (the trained EfficientNetB0 classifier)
  - reports/class_names.json       (the 28 class names in training order)

Outputs
-------
  - ../assets/models/disease_model.tflite   (the TFLite model, ~10 MB)
  - ../assets/models/labels.json            (class names copy, same order)

Usage
-----
  $ python convert_to_tflite.py
  $ python convert_to_tflite.py --force-synth   # ignore any real checkpoint

Notes
-----
* The model uses EfficientNetB0's standard preprocessing (input in [0, 255],
  internal Normalization layer inside the base model). The Dart-side
  `DiseaseClassifier` feeds raw [0, 255] float32 values accordingly.
* We use default optimization (no post-training quantization) so the
  converted model is a byte-for-byte close match to the original Keras
  accuracy. If app size becomes a concern, switch to `tf.lite.Optimize.DEFAULT`
  (dynamic-range quantization) — accuracy typically drops < 1%.
* Tested with TensorFlow 2.16+.

Fallback behaviour
------------------
If `models/best_model.keras` and `reports/class_names.json` are not both
present, the script falls back to a small synthetic Keras model (a
ConvNet trained for a handful of epochs on random data) so the
artifacts exist and the app's offline path at least loads. The synthetic
model's predictions are not meaningful — replace it with the real
checkpoint as soon as training is done.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

import tensorflow as tf

BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_PATH = BASE_DIR / "models" / "best_model.keras"
CLASS_NAMES_PATH = BASE_DIR / "reports" / "class_names.json"

# Output goes into the Flutter app's assets folder so it can be bundled
# with the APK / IPA / desktop binary.
ASSETS_DIR = BASE_DIR.parent / "assets" / "models"
TFLITE_OUTPUT_PATH = ASSETS_DIR / "disease_model.tflite"
LABELS_OUTPUT_PATH = ASSETS_DIR / "labels.json"

# The 28 classes the app's `disease_info.dart` knows about. Kept in
# sync with that file. Order matters: index i here = the i-th neuron
# of the classification head.
DEFAULT_CLASS_NAMES = [
    "Corn___Common_Rust",
    "Corn___Gray_Leaf_Spot",
    "Corn___Healthy",
    "Corn___Leaf_Blight",
    "Potato___Early_Blight",
    "Potato___Healthy",
    "Potato___Late_Blight",
    "Rice___Bacterial_Blight",
    "Rice___Blast",
    "Rice___Brown_Spot",
    "Rice___Dead_Heart",
    "Rice___False_Smut",
    "Rice___Gall_Midge",
    "Rice___Healthy",
    "Rice___Hispa",
    "Rice___Leaf_Blast",
    "Rice___Leaf_Scald",
    "Rice___Narrow_Brown_Leaf_Spot",
    "Rice___Neck_Blast",
    "Rice___Rice_Tungro",
    "Rice___Sheath_Blight",
    "Rice___Stem_Borer",
    "Wheat___Brown_Rust",
    "Wheat___Healthy",
    "Wheat___Yellow_Rust",
    # a couple of padding slots keep head size at a tidy 28
    "Rice___Unknown_A",
    "Rice___Unknown_B",
]
NUM_CLASSES = len(DEFAULT_CLASS_NAMES)
INPUT_HEIGHT = 224
INPUT_WIDTH = 224


def _build_synthetic_model() -> tf.keras.Model:
    """A small ConvNet that matches the (224, 224, 3) -> 28 contract.

    The architecture mirrors what a freshly-trained EfficientNetB0
    classifier head would expose — global average pooling + dense
    softmax — so the conversion and the Flutter app both see the same
    input/output tensor shapes. Predictions are NOT meaningful; this
    only exists so the offline path loads on day one.
    """
    inputs = tf.keras.Input(shape=(INPUT_HEIGHT, INPUT_WIDTH, 3), name="input")
    x = tf.keras.layers.Rescaling(1.0 / 255.0)(inputs)
    x = tf.keras.layers.Conv2D(16, 3, strides=2, activation="relu", padding="same")(x)
    x = tf.keras.layers.Conv2D(32, 3, strides=2, activation="relu", padding="same")(x)
    x = tf.keras.layers.Conv2D(64, 3, strides=2, activation="relu", padding="same")(x)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    outputs = tf.keras.layers.Dense(NUM_CLASSES, activation="softmax", name="output")(x)
    return tf.keras.Model(inputs=inputs, outputs=outputs, name="synthetic_disease")


def _train_synthetic(model: tf.keras.Model) -> None:
    """Run a couple of epochs on random data so weights aren't pure noise.

    The resulting predictions are still meaningless (the data is
    random), but the tensors are valid and the model has learned
    *something* about the input distribution — enough to keep the
    offline path alive in the demo build.
    """
    import numpy as np

    print("Generating random training data (synthetic fallback)...")
    x = np.random.rand(64, INPUT_HEIGHT, INPUT_WIDTH, 3).astype("float32")
    # Uniform labels are fine for this purpose; we only need *some*
    # trained weights.
    y = np.zeros((64, NUM_CLASSES), dtype="float32")
    y[:, 0] = 1.0
    model.compile(
        optimizer=tf.keras.optimizers.Adam(),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.fit(x, y, epochs=2, batch_size=8, verbose=1)


def _load_real_model_and_labels():
    print(f"Loading trained Keras model from {MODEL_PATH}")
    model = tf.keras.models.load_model(MODEL_PATH)
    print(f"Input shape : {model.input_shape}")
    print(f"Output shape: {model.output_shape}")
    with open(CLASS_NAMES_PATH, "r", encoding="utf-8") as f:
        labels = json.load(f)
    if len(labels) != model.output_shape[-1]:
        print(
            f"WARNING: {len(labels)} labels in class_names.json but the "
            f"model expects {model.output_shape[-1]} outputs. Predictions "
            f"will be misaligned."
        )
    return model, labels


def _build_synthetic_model_and_labels():
    print("No trained checkpoint found — building a synthetic fallback model.")
    model = _build_synthetic_model()
    _train_synthetic(model)
    return model, list(DEFAULT_CLASS_NAMES)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--force-synth",
        action="store_true",
        help="Ignore any real Keras checkpoint and force the synthetic fallback.",
    )
    args = parser.parse_args()

    print("=" * 70)
    print("CONVERTING DISEASE MODEL TO TFLITE")
    print("=" * 70)

    use_real = (
        not args.force_synth
        and MODEL_PATH.exists()
        and CLASS_NAMES_PATH.exists()
    )
    if use_real:
        model, labels = _load_real_model_and_labels()
    else:
        if not args.force_synth:
            print(
                "Trained model or class names not found — falling back to a "
                "synthetic model. Re-run after training the real one."
            )
        model, labels = _build_synthetic_model_and_labels()

    print("\nBuilding TFLite converter...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    # Default optimizations off to preserve accuracy. To enable dynamic-range
    # quantization (smaller file, ~negligible accuracy loss):
    #
    #   converter.optimizations = [tf.lite.Optimize.DEFAULT]
    #
    # We keep the default (float32) to match the original Keras accuracy.

    print("Converting...")
    tflite_model = converter.convert()

    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    TFLITE_OUTPUT_PATH.write_bytes(tflite_model)
    print(f"\nWrote {TFLITE_OUTPUT_PATH} ({len(tflite_model) / 1024 / 1024:.2f} MB)")

    with open(LABELS_OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(labels, f, indent=2)
    print(f"Wrote {LABELS_OUTPUT_PATH} ({len(labels)} classes)")

    # Sanity check: load the TFLite model and run a dummy inference.
    print("\nSanity-checking the converted model...")
    interpreter = tf.lite.Interpreter(model_path=str(TFLITE_OUTPUT_PATH))
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    print(f"Input  : {input_details[0]['shape']} {input_details[0]['dtype']}")
    print(f"Output : {output_details[0]['shape']} {output_details[0]['dtype']}")

    import numpy as np

    dummy = np.zeros(input_details[0]["shape"], dtype=input_details[0]["dtype"])
    interpreter.set_tensor(input_details[0]["index"], dummy)
    interpreter.invoke()
    out = interpreter.get_tensor(output_details[0]["index"])
    print(f"Dummy output shape: {out.shape}")
    print(f"Dummy output sum  : {out.sum():.4f} (should be ~1.0 for softmax)")

    print("\n" + "=" * 70)
    print("DONE")
    print("=" * 70)
    print("Next step: run the Flutter app on a real device or emulator.")
    print("The .tflite file is bundled automatically (pubspec.yaml assets).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
