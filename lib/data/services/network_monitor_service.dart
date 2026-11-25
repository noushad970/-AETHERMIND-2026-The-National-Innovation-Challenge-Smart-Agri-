import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitors active internet connectivity (Mobile Data and Wi-Fi) and
/// provides real-time connection status updates.
class NetworkMonitorService extends ChangeNotifier {
  NetworkMonitorService._();
  static final NetworkMonitorService instance = NetworkMonitorService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  bool _isWifi = false;
  bool get isWifi => _isWifi;

  bool _isMobileData = false;
  bool get isMobileData => _isMobileData;

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();
  Stream<bool> get onConnectionChanged => _connectionStreamController.stream;

  bool _initialized = false;

  /// Initializes the connectivity listener and performs initial check.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Listen to network interface changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });

    // Check initial state
    final initialResults = await _connectivity.checkConnectivity();
    await _handleConnectivityChange(initialResults);
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    _isWifi = results.contains(ConnectivityResult.wifi);
    _isMobileData = results.contains(ConnectivityResult.mobile);

    final hasNetworkInterface = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );

    if (!hasNetworkInterface) {
      _updateStatus(false);
      return;
    }

    // Verify true internet access via fast lookup
    final hasInternet = await checkTrueInternetAccess();
    _updateStatus(hasInternet);
  }

  /// Verifies active internet reachability
  Future<bool> checkTrueInternetAccess() async {
    // Browsers cannot do DNS lookups, so rely on the connectivity status.
    if (kIsWeb) return true;
    try {
      final lookupResult = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      if (lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      try {
        final fallbackLookup = await InternetAddress.lookup('cloudflare.com')
            .timeout(const Duration(seconds: 3));
        if (fallbackLookup.isNotEmpty &&
            fallbackLookup[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Manually triggers a re-check of the network (e.g. from Retry button)
  Future<bool> checkConnection() async {
    _isChecking = true;
    notifyListeners();

    try {
      final results = await _connectivity.checkConnectivity();
      _isWifi = results.contains(ConnectivityResult.wifi);
      _isMobileData = results.contains(ConnectivityResult.mobile);

      final hasNetworkInterface = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet ||
            r == ConnectivityResult.vpn,
      );

      if (!hasNetworkInterface) {
        _updateStatus(false);
        return false;
      }

      final hasInternet = await checkTrueInternetAccess();
      _updateStatus(hasInternet);
      return hasInternet;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  void _updateStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      debugPrint('[NetworkMonitorService] Internet status changed: online=$online');
      _connectionStreamController.add(online);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _connectionStreamController.close();
    super.dispose();
  }
}
