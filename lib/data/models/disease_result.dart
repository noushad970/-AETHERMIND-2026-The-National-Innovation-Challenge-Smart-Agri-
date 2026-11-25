/// Result returned from the Smart Agri Backend Server or Gemini Vision AI.
/// 
/// Supports:
/// 1. Sequential text format (Step 1, Step 2, Step 3... / ধাপ ১, ধাপ ২, ধাপ ৩...)
/// 2. Bilingual output (English and Bangla)
/// 3. Local Hive database serialization for offline fast access.
class DiseaseResult {
  DiseaseResult({
    String? diseaseName,
    required this.confidence,
    this.id = '',
    this.diseaseNameEn = '',
    this.diseaseNameBn = '',
    this.cropNameEn = '',
    this.cropNameBn = '',
    this.severity = 'Medium',
    this.severityBn = 'মাঝারি',
    this.symptomsStepsEn = const [],
    this.symptomsStepsBn = const [],
    this.treatmentStepsEn = const [],
    this.treatmentStepsBn = const [],
    this.preventionStepsEn = const [],
    this.preventionStepsBn = const [],
    this.medicinesEn = const [],
    this.medicinesBn = const [],
    this.causes = '',
    this.causesEn = '',
    this.causesBn = '',
    this.symptoms = '',
    this.spread = '',
    this.prevention = '',
    this.treatment = '',
    this.organicSolutions = '',
    this.chemicalSolutions = '',
    this.rawText = '',
    this.imageBytesBase64 = '',
    DateTime? createdAt,
  })  : diseaseName = (diseaseName != null && diseaseName.trim().isNotEmpty)
            ? diseaseName
            : (diseaseNameBn.isNotEmpty ? diseaseNameBn : (diseaseNameEn.isNotEmpty ? diseaseNameEn : 'Unknown')),
        createdAt = createdAt ?? DateTime.now();

  final String id;

  /// Primary display name (Bangla by default, or English fallback).
  final String diseaseName;

  /// English disease name (e.g. "Brown Spot", "Late Blight").
  final String diseaseNameEn;

  /// Bangla disease name (e.g. "বাদামি দাগ রোগ", "নাবি ধসা রোগ").
  final String diseaseNameBn;

  /// Identified crop in English (e.g. "Rice", "Tomato").
  final String cropNameEn;

  /// Identified crop in Bangla (e.g. "ধান", "টমেটো").
  final String cropNameBn;

  /// Confidence score between 0.0 and 1.0.
  final double confidence;

  /// Severity in English ("Low", "Medium", "High").
  final String severity;

  /// Severity in Bangla ("হালকা", "মাঝারি", "তীব্র").
  final String severityBn;

  /// Sequential step-by-step symptoms in English.
  final List<String> symptomsStepsEn;

  /// Sequential step-by-step symptoms in Bangla (ধাপ ১, ধাপ ২...).
  final List<String> symptomsStepsBn;

  /// Sequential step-by-step treatment plan in English (Step 1, Step 2...).
  final List<String> treatmentStepsEn;

  /// Sequential step-by-step treatment plan in Bangla (ধাপ ১, ধাপ ২...).
  final List<String> treatmentStepsBn;

  /// Sequential step-by-step prevention steps in English.
  final List<String> preventionStepsEn;

  /// Sequential step-by-step prevention steps in Bangla (ধাপ ১, ধাপ ২...).
  final List<String> preventionStepsBn;

  /// Recommended medicines & dosages in English.
  final List<String> medicinesEn;

  /// Recommended medicines & dosages in Bangla.
  final List<String> medicinesBn;

  /// Description of causes.
  final String causes;
  final String causesEn;
  final String causesBn;

  /// Flat symptoms string (for backward compatibility).
  final String symptoms;

  /// How it spreads.
  final String spread;

  /// Prevention text summary.
  final String prevention;

  /// Treatment text summary.
  final String treatment;

  /// Organic solutions summary.
  final String organicSolutions;

  /// Chemical solutions summary.
  final String chemicalSolutions;

  /// Raw response text.
  final String rawText;

  /// Base64 encoded thumbnail image for fast offline Hive viewing.
  final String imageBytesBase64;

  /// Date when the scan took place.
  final DateTime createdAt;

  /// Helper to convert a dynamic JSON field into a clean List of Strings.
  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      // If it contains newlines or bullets, split them into steps
      final lines = value.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      return lines.isNotEmpty ? lines : [value.trim()];
    }
    return [];
  }

  /// Parses response returned from Smart Agri dedicated backend server.
  factory DiseaseResult.fromServerJson(Map<String, dynamic> j, {String? imageBase64}) {
    double conf = 0.0;
    final rawConf = j['confidence'];
    if (rawConf is num) conf = rawConf.toDouble().clamp(0.0, 1.0);
    if (rawConf is String) conf = double.tryParse(rawConf) ?? 0.0;

    final symEn = _toStringList(j['symptoms_steps_en']);
    final symBn = _toStringList(j['symptoms_steps_bn']);
    final treatEn = _toStringList(j['treatment_steps_en']);
    final treatBn = _toStringList(j['treatment_steps_bn']);
    final prevEn = _toStringList(j['prevention_steps_en']);
    final prevBn = _toStringList(j['prevention_steps_bn']);
    final medEn = _toStringList(j['medicines_en']);
    final medBn = _toStringList(j['medicines_bn']);

    final dNameEn = (j['disease_name_en'] ?? j['disease_name'] ?? '').toString().trim();
    final dNameBn = (j['disease_name_bn'] ?? j['রোগের_নাম'] ?? '').toString().trim();

    return DiseaseResult(
      id: (j['id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
      diseaseName: dNameBn.isNotEmpty ? dNameBn : (dNameEn.isNotEmpty ? dNameEn : 'Unknown'),
      diseaseNameEn: dNameEn,
      diseaseNameBn: dNameBn,
      cropNameEn: (j['crop_name_en'] ?? '').toString(),
      cropNameBn: (j['crop_name_bn'] ?? '').toString(),
      confidence: conf,
      severity: (j['severity'] ?? 'Medium').toString(),
      severityBn: (j['severity_bn'] ?? 'মাঝারি').toString(),
      symptomsStepsEn: symEn,
      symptomsStepsBn: symBn,
      treatmentStepsEn: treatEn,
      treatmentStepsBn: treatBn,
      preventionStepsEn: prevEn,
      preventionStepsBn: prevBn,
      medicinesEn: medEn,
      medicinesBn: medBn,
      causes: (j['causes_bn'] ?? j['causes'] ?? '').toString(),
      causesEn: (j['causes_en'] ?? '').toString(),
      causesBn: (j['causes_bn'] ?? '').toString(),
      symptoms: symBn.isNotEmpty ? symBn.join('\n') : (j['symptoms'] ?? '').toString(),
      spread: (j['spread'] ?? '').toString(),
      prevention: prevBn.isNotEmpty ? prevBn.join('\n') : (j['prevention'] ?? '').toString(),
      treatment: treatBn.isNotEmpty ? treatBn.join('\n') : (j['treatment'] ?? '').toString(),
      organicSolutions: (j['organic_solutions'] ?? '').toString(),
      chemicalSolutions: medBn.isNotEmpty ? medBn.join('\n') : (j['chemical_solutions'] ?? '').toString(),
      rawText: (j['raw_text'] ?? '').toString(),
      imageBytesBase64: imageBase64 ?? (j['image_bytes_base64'] ?? '').toString(),
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  /// Backward-compatible factory for direct Gemini JSON response.
  factory DiseaseResult.fromGeminiJson(Map<String, dynamic> j) {
    return DiseaseResult.fromServerJson(j);
  }

  /// Converts this model to JSON for Hive or network storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'disease_name': diseaseName,
    'disease_name_en': diseaseNameEn,
    'disease_name_bn': diseaseNameBn,
    'crop_name_en': cropNameEn,
    'crop_name_bn': cropNameBn,
    'confidence': confidence,
    'severity': severity,
    'severity_bn': severityBn,
    'symptoms_steps_en': symptomsStepsEn,
    'symptoms_steps_bn': symptomsStepsBn,
    'treatment_steps_en': treatmentStepsEn,
    'treatment_steps_bn': treatmentStepsBn,
    'prevention_steps_en': preventionStepsEn,
    'prevention_steps_bn': preventionStepsBn,
    'medicines_en': medicinesEn,
    'medicines_bn': medicinesBn,
    'causes': causes,
    'causes_en': causesEn,
    'causes_bn': causesBn,
    'symptoms': symptoms,
    'spread': spread,
    'prevention': prevention,
    'treatment': treatment,
    'organic_solutions': organicSolutions,
    'chemical_solutions': chemicalSolutions,
    'raw_text': rawText,
    'image_bytes_base64': imageBytesBase64,
    'created_at': createdAt.toIso8601String(),
  };

  factory DiseaseResult.fromJson(Map<String, dynamic> json) => DiseaseResult.fromServerJson(json);
}
