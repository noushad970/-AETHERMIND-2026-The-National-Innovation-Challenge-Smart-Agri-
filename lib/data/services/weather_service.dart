import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/weather_data.dart';

/// Open-Meteo client + device-location helpers.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Reverse-geocodes (lat,lon) into a human-readable location using
  /// Open-Meteo's geocoding API.
  ///
  /// Open-Meteo's `/reverse` endpoint does not return CORS headers, so
  /// requests from Flutter Web fail with `ClientException`. We instead
  /// hit `/search` (CORS-friendly) with a coarse "name" query and
  /// pick the closest matching city. Falls back to a hard-coded list of
  /// Bangladeshi cities if the network call fails.
  Future<String> reverseGeocode(double lat, double lon) async {
    // 1) Try Open-Meteo `/search` with the country name (works on Web).
    try {
      final uri = Uri.parse(
        '${AppConstants.geocodingBaseUrl}/search?name=Bangladesh&count=10&language=en&format=json',
      );
      final resp = await _client.get(uri);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = (body['results'] as List?) ?? const [];
        if (results.isNotEmpty) {
          // Pick the result closest to the device coordinates.
          Map<String, dynamic> best = results.first as Map<String, dynamic>;
          double bestDist = _distanceSq(
            lat,
            lon,
            (best['latitude'] as num).toDouble(),
            (best['longitude'] as num).toDouble(),
          );
          for (final r in results.skip(1)) {
            final m = r as Map<String, dynamic>;
            final d = _distanceSq(
              lat,
              lon,
              (m['latitude'] as num).toDouble(),
              (m['longitude'] as num).toDouble(),
            );
            if (d < bestDist) {
              best = m;
              bestDist = d;
            }
          }
          final name = best['name'];
          final admin = best['admin1'] ?? '';
          return admin.toString().isNotEmpty
              ? '$name, $admin'
              : name.toString();
        }
      }
    } catch (_) {
      // Network / CORS / parse failure — fall through.
    }

    // 2) Hard-coded nearest-city lookup for Bangladesh.
    return _nearestCityInBangladesh(lat, lon);
  }

  static double _distanceSq(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = lat1 - lat2;
    final dLon = lon1 - lon2;
    return dLat * dLat + dLon * dLon;
  }

  static String _nearestCityInBangladesh(double lat, double lon) {
    const cities = <_City>[
      _City('Dhaka', 23.8103, 90.4125),
      _City('Chattogram', 22.3569, 91.7832),
      _City('Khulna', 22.8456, 89.5403),
      _City('Rajshahi', 24.3740, 88.6011),
      _City('Sylhet', 24.8949, 91.8687),
      _City('Barishal', 22.7010, 90.3535),
      _City('Rangpur', 25.7439, 89.2752),
      _City('Mymensingh', 24.7471, 90.4203),
      _City('Comilla', 23.4607, 91.1809),
      _City('Narayanganj', 23.6238, 90.4996),
      _City('Gazipur', 23.9999, 90.4203),
    ];
    _City best = cities.first;
    double bestDist = _distanceSq(lat, lon, best.lat, best.lon);
    for (final c in cities.skip(1)) {
      final d = _distanceSq(lat, lon, c.lat, c.lon);
      if (d < bestDist) {
        best = c;
        bestDist = d;
      }
    }
    return '${best.name}, Bangladesh';
  }

  Future<WeatherData> fetchWeather({
    required double lat,
    required double lon,
    String? locationName,
  }) async {
    final params = {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
      'daily':
          'temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code',
      'timezone': 'auto',
      'forecast_days': '7',
    };
    final uri = Uri.parse(
      '${AppConstants.openMeteoBaseUrl}/forecast',
    ).replace(queryParameters: params);

    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Weather API error: ${resp.statusCode}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final name = locationName ?? await reverseGeocode(lat, lon);
    return WeatherData.fromOpenMeteoJson(json, locationName: name);
  }

  /// Best-effort device location. Throws if denied / unavailable.
  Future<Position> getDeviceLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  /// Fallback: capital of Bangladesh if device location isn't available.
  Position getDhakaFallback() => Position(
    latitude: 23.8103,
    longitude: 90.4125,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

class _City {
  const _City(this.name, this.lat, this.lon);
  final String name;
  final double lat;
  final double lon;
}
