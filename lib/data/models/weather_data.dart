/// Snapshot of weather data for a location.
class WeatherData {
  WeatherData({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windSpeedKmh,
    required this.precipitationMm,
    required this.weatherCode,
    required this.forecast,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
  });

  final double temperatureC;
  final double feelsLikeC;
  final int humidity; // percent
  final double windSpeedKmh;
  final double precipitationMm;
  final int weatherCode; // WMO weather code
  final List<DailyForecast> forecast;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  String get conditionLabel => _labelForCode(weatherCode);
  String get conditionLabelBn => _labelForCodeBn(weatherCode);

  String get farmingRecommendation {
    if (precipitationMm > 5) {
      return 'Heavy rain expected. Postpone fertilizer / pesticide application.';
    }
    if (precipitationMm > 0) {
      return 'Light rain likely. Good for irrigation, avoid spraying.';
    }
    if (temperatureC > 35) {
      return 'Hot and dry. Irrigate early morning or evening.';
    }
    if (temperatureC < 15) {
      return 'Cool weather. Watch for fungal diseases.';
    }
    if (humidity > 80) {
      return 'High humidity. Risk of fungal infection, monitor crops.';
    }
    return 'Favorable conditions for normal farming activities.';
  }

  String get farmingRecommendationBn {
    if (precipitationMm > 5) {
      return 'ভারী বৃষ্টির সম্ভাবনা। সার ও কীটনাশক স্প্রে করা স্থগিত রাখুন।';
    }
    if (precipitationMm > 0) {
      return 'হালকা বৃষ্টির সম্ভাবনা। সেচ স্থগিত রাখুন এবং নিবিড়ভাবে পর্যবেক্ষণ করুন।';
    }
    if (temperatureC > 35) {
      return 'অতিরিক্ত গরম ও শুষ্ক আবহাওয়া। ভোর বা সন্ধ্যায় পরিমিত সেচ দিন।';
    }
    if (temperatureC < 15) {
      return 'শীতল আবহাওয়া। ছত্রাকজনিত রোগের ঝুঁকি পর্যবেক্ষণ করুন।';
    }
    if (humidity > 80) {
      return 'অতিরিক্ত আর্দ্রতা। ব্লাস্ট বা ছত্রাকের ঝুঁকি রয়েছে, ফসল লক্ষ্য রাখুন।';
    }
    return 'স্বাভাবিক কৃষি কাজের জন্য অনুকূল আবহাওয়া।';
  }

  static String _labelForCode(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  static String _labelForCodeBn(int code) {
    if (code == 0) return 'পরিষ্কার আকাশ';
    if (code <= 3) return 'আংশিক মেঘলা';
    if (code <= 48) return 'কুয়াশাচ্ছন্ন';
    if (code <= 67) return 'বৃষ্টি';
    if (code <= 77) return 'তুষারপাত';
    if (code <= 82) return 'বৃষ্টির ধারা';
    if (code <= 99) return 'বজ্রঝড়';
    return 'স্বাভাবিক';
  }

  factory WeatherData.fromOpenMeteoJson(
    Map<String, dynamic> json, {
    required String locationName,
  }) {
    final current = (json['current'] ?? const {}) as Map<String, dynamic>;
    final daily = (json['daily'] ?? const {}) as Map<String, dynamic>;
    final times = (daily['time'] as List?) ?? const [];
    final maxT = (daily['temperature_2m_max'] as List?) ?? const [];
    final minT = (daily['temperature_2m_min'] as List?) ?? const [];
    final prcp = (daily['precipitation_sum'] as List?) ?? const [];
    final codes = (daily['weather_code'] as List?) ?? const [];

    final List<DailyForecast> forecast = [];
    for (var i = 0; i < times.length; i++) {
      forecast.add(DailyForecast(
        date: DateTime.parse(times[i] as String),
        maxTempC: (maxT[i] as num?)?.toDouble() ?? 0,
        minTempC: (minT[i] as num?)?.toDouble() ?? 0,
        precipitationMm: (prcp[i] as num?)?.toDouble() ?? 0,
        weatherCode: (codes[i] as num?)?.toInt() ?? 0,
      ));
    }

    return WeatherData(
      temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      feelsLikeC: (current['apparent_temperature'] as num?)?.toDouble() ?? 0,
      humidity: ((current['relative_humidity_2m'] as num?)?.toInt()) ?? 0,
      windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      precipitationMm: (current['precipitation'] as num?)?.toDouble() ?? 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      forecast: forecast,
      locationName: locationName,
      latitude: ((json['latitude'] as num?)?.toDouble()) ?? 0,
      longitude: ((json['longitude'] as num?)?.toDouble()) ?? 0,
      fetchedAt: DateTime.now(),
    );
  }
}

class DailyForecast {
  DailyForecast({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.precipitationMm,
    required this.weatherCode,
  });

  final DateTime date;
  final double maxTempC;
  final double minTempC;
  final double precipitationMm;
  final int weatherCode;

  String get conditionLabel {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode <= 3) return 'Cloudy';
    if (weatherCode <= 48) return 'Fog';
    if (weatherCode <= 67) return 'Rain';
    if (weatherCode <= 77) return 'Snow';
    if (weatherCode <= 82) return 'Showers';
    if (weatherCode <= 99) return 'Storm';
    return '—';
  }

  String get conditionLabelBn {
    if (weatherCode == 0) return 'পরিষ্কার';
    if (weatherCode <= 3) return 'মেঘলা';
    if (weatherCode <= 48) return 'কুয়াশা';
    if (weatherCode <= 67) return 'বৃষ্টি';
    if (weatherCode <= 77) return 'তুষারপাত';
    if (weatherCode <= 82) return 'বৃষ্টির ধারা';
    if (weatherCode <= 99) return 'বজ্রঝড়';
    return 'স্বাভাবিক';
  }
}