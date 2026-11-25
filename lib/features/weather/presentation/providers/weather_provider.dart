import 'package:flutter/foundation.dart';

import '../../../../data/models/weather_data.dart';
import '../../../../data/services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherProvider({WeatherService? service})
      : _service = service ?? WeatherService();

  final WeatherService _service;

  WeatherData? _data;
  bool _loading = false;
  String? _error;

  WeatherData? get data => _data;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasData => _data != null;

  Future<void> loadCurrentLocation() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      dynamic pos;
      try {
        pos = await _service.getDeviceLocation();
      } catch (_) {
        pos = _service.getDhakaFallback();
      }
      _data = await _service.fetchWeather(
        lat: pos.latitude as double,
        lon: pos.longitude as double,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadFallback() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final pos = _service.getDhakaFallback();
      _data = await _service.fetchWeather(lat: pos.latitude, lon: pos.longitude);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
