import 'package:flutter/foundation.dart';

import '../../../../data/models/market_price.dart';
import '../../../../data/services/market_price_service.dart';

class MarketPricesProvider extends ChangeNotifier {
  MarketPricesProvider({MarketPriceService? service})
    : _service = service ?? MarketPriceService();

  final MarketPriceService _service;

  String _market = 'Dhaka';
  List<MarketPrice> _prices = const [];
  bool _loading = false;
  String? _error;
  PriceSource _source = PriceSource.cached;
  DateTime? _updatedAt;
  DateTime? _expiresAt;

  String get market => _market;
  List<MarketPrice> get prices => _prices;
  bool get isLoading => _loading;
  String? get error => _error;
  PriceSource get source => _source;
  DateTime? get updatedAt => _updatedAt ?? (_prices.isEmpty ? null : _prices.first.date);
  DateTime? get expiresAt => _expiresAt ?? _updatedAt?.add(const Duration(days: 7));
  DateTime? get lastUpdated => updatedAt;

  bool get isGemini => _source == PriceSource.geminiAi;
  bool get isFromDatabase => _source == PriceSource.cached;

  int get daysUntilNextUpdate {
    final exp = expiresAt;
    if (exp == null) return 7;
    final diff = exp.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  Future<void> load({String? market, bool forceAiRefresh = false}) async {
    if (market != null) _market = market;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.fetchTodayPrices(
        market: _market,
        forceAiRefresh: forceAiRefresh,
      );
      _prices = result.prices;
      _source = result.source;
      _updatedAt = result.updatedAt;
      _expiresAt = result.expiresAt;
    } catch (e) {
      _error = e.toString();
      final cached = _service.getCached(market: _market);
      _prices = cached;
      _source = cached.isEmpty ? PriceSource.mock : PriceSource.cached;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWithGemini() async {
    await load(forceAiRefresh: true);
  }
}
