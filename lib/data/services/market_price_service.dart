import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/market_price.dart';
import 'gemini_service.dart';

/// Where the prices shown on screen came from.
enum PriceSource {
  geminiAi, // fetched live via Google Gemini AI
  cached, // global 7-day Firestore database cache
  mock, // 50-product curated baseline dataset
}

/// Helper model for the global Firestore document storing 50 product rates.
class GlobalMarketPriceDoc {
  GlobalMarketPriceDoc({
    required this.market,
    required this.updatedAt,
    required this.expiresAt,
    required this.prices,
  });

  final String market;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final List<MarketPrice> prices;

  /// Returns true if the cache is within the 7-day validity window.
  bool get isValid =>
      DateTime.now().isBefore(expiresAt) && prices.isNotEmpty && prices.length >= 20;

  int get daysRemaining {
    final diff = expiresAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}

/// Provides 50-commodity market price data with a global 7-day Firestore caching strategy.
///
/// Workflow:
///   1. Check Firestore `global_market_prices/latest_{market}`.
///   2. If valid (< 7 days old), return cached data immediately (0 Gemini token cost!).
///   3. If expired (>= 7 days old) or forced, call Gemini AI to generate current prices.
///   4. Update Firestore `global_market_prices` with new 7-day validity for all users.
///   5. Fallback to curated 50-product dataset if Gemini is unavailable.
class MarketPriceService {
  MarketPriceService({
    http.Client? client,
    GeminiService? gemini,
    FirebaseFirestore? firestore,
  })  : _client = client ?? http.Client(),
        _gemini = gemini ?? GeminiService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const String globalCollectionName = 'global_market_prices';
  static const int cacheValidityDays = 7;

  final http.Client _client;
  final GeminiService _gemini;
  final FirebaseFirestore _firestore;

  /// Returns 50-commodity market prices for [market].
  /// Uses global Firestore database cache valid for 7 days before calling Gemini AI.
  Future<PriceResult> fetchTodayPrices({
    String market = 'Dhaka',
    bool forceAiRefresh = false,
  }) async {
    final normalizedMarket = market.trim().isEmpty ? 'Dhaka' : market.trim();

    // 1. Check Global Firestore Database Cache (unless explicitly force-refreshed)
    if (!forceAiRefresh) {
      final cachedDoc = await _fetchFromGlobalFirestore(normalizedMarket);
      if (cachedDoc != null && cachedDoc.isValid) {
        developer.log(
          'Market prices loaded from Global Firestore cache (${cachedDoc.prices.length} items, valid for ${cachedDoc.daysRemaining} more days)',
          name: 'MarketPriceService',
        );
        primeCache(cachedDoc.prices);
        return PriceResult(
          cachedDoc.prices,
          PriceSource.cached,
          updatedAt: cachedDoc.updatedAt,
          expiresAt: cachedDoc.expiresAt,
        );
      }
    }

    // 2. Cache is expired (>= 7 days) or force refresh requested:
    // Request fresh prices from Google Gemini AI
    try {
      developer.log(
        'Fetching 50 product prices from Gemini AI for $normalizedMarket...',
        name: 'MarketPriceService',
      );
      final geminiPrices = await _gemini.fetchMarketPricesWithGemini(
        market: normalizedMarket,
      );

      if (geminiPrices.isNotEmpty && geminiPrices.length >= 25) {
        final now = DateTime.now();
        final expiresAt = now.add(const Duration(days: cacheValidityDays));

        // Save to Global Firestore Database for all users
        await _saveToGlobalFirestore(normalizedMarket, geminiPrices, now, expiresAt);

        primeCache(geminiPrices);
        return PriceResult(
          geminiPrices,
          PriceSource.geminiAi,
          updatedAt: now,
          expiresAt: expiresAt,
        );
      }
    } catch (e, st) {
      developer.log(
        'Gemini market price fetch failed: $e',
        name: 'MarketPriceService',
        error: e,
        stackTrace: st,
      );
    }

    // 3. Fallback: If Gemini is unavailable, try to use existing Firestore data (even if older than 7 days)
    final fallbackDoc = await _fetchFromGlobalFirestore(normalizedMarket);
    if (fallbackDoc != null && fallbackDoc.prices.isNotEmpty) {
      primeCache(fallbackDoc.prices);
      return PriceResult(
        fallbackDoc.prices,
        PriceSource.cached,
        updatedAt: fallbackDoc.updatedAt,
        expiresAt: fallbackDoc.expiresAt,
      );
    }

    // 4. Baseline curated dataset with 50 essential commodities & seed Firestore
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: cacheValidityDays));
    final curated = _curated50FoodProducts(normalizedMarket);

    await _saveToGlobalFirestore(normalizedMarket, curated, now, expiresAt);
    primeCache(curated);
    return PriceResult(
      curated,
      PriceSource.mock,
      updatedAt: now,
      expiresAt: expiresAt,
    );
  }

  /// Fetches global market price document from Firestore.
  Future<GlobalMarketPriceDoc?> _fetchFromGlobalFirestore(String market) async {
    try {
      final docId = 'latest_${market.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
      final snap = await _firestore.collection(globalCollectionName).doc(docId).get();

      if (!snap.exists || snap.data() == null) {
        return null;
      }

      final data = snap.data()!;
      final updatedAtStr = data['updatedAt'] as String?;
      final expiresAtStr = data['expiresAt'] as String?;
      final updatedAt = updatedAtStr != null ? (DateTime.tryParse(updatedAtStr) ?? DateTime.now()) : DateTime.now();
      final expiresAt = expiresAtStr != null ? (DateTime.tryParse(expiresAtStr) ?? updatedAt.add(const Duration(days: cacheValidityDays))) : updatedAt.add(const Duration(days: cacheValidityDays));

      final productsRaw = data['products'] as List<dynamic>? ?? [];
      if (productsRaw.isEmpty) return null;

      final prices = productsRaw
          .map((item) => MarketPrice.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();

      return GlobalMarketPriceDoc(
        market: market,
        updatedAt: updatedAt,
        expiresAt: expiresAt,
        prices: prices,
      );
    } catch (e) {
      developer.log(
        'Error reading global market prices from Firestore: $e',
        name: 'MarketPriceService',
      );
      return null;
    }
  }

  /// Saves 50 product market prices to the global Firestore collection with a 7-day TTL.
  Future<void> _saveToGlobalFirestore(
    String market,
    List<MarketPrice> prices,
    DateTime updatedAt,
    DateTime expiresAt,
  ) async {
    try {
      final docId = 'latest_${market.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
      await _firestore.collection(globalCollectionName).doc(docId).set({
        'market': market,
        'updatedAt': updatedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'validityDays': cacheValidityDays,
        'productCount': prices.length,
        'products': prices.map((p) => p.toMap()).toList(),
      }, SetOptions(merge: true));

      developer.log(
        'Successfully saved ${prices.length} global market prices to Firestore (valid until ${expiresAt.toIso8601String()})',
        name: 'MarketPriceService',
      );
    } catch (e) {
      developer.log(
        'Error saving global market prices to Firestore: $e',
        name: 'MarketPriceService',
      );
    }
  }

  /// Returns the in-memory cache.
  List<MarketPrice> getCached({String? market}) {
    final all = _cache.values.toList();
    if (market == null) return all;
    return all.where((p) => p.market == market).toList();
  }

  void primeCache(Iterable<MarketPrice> entries) {
    _cache
      ..clear()
      ..addEntries(entries.map((e) => MapEntry(e.id, e)));
  }

  void clearCache() => _cache.clear();

  final Map<String, MarketPrice> _cache = <String, MarketPrice>{};

  /// Comprehensive baseline catalog of 50 essential Bangladeshi food & agricultural commodities.
  List<MarketPrice> _curated50FoodProducts(String market) {
    final today = DateTime.now();

    final rawData = <Map<String, dynamic>>[
      // --- 1. Grains & Cereals (ধান ও চাল) ---
      {'en': 'Miniket Rice', 'bn': 'মিনিকেট চাল', 'price': 74.0, 'unit': 'kg', 'cat': 'Grains', 'chg': 1.2},
      {'en': 'Nazirshail Rice', 'bn': 'নাজিরশাইল চাল', 'price': 82.0, 'unit': 'kg', 'cat': 'Grains', 'chg': 0.8},
      {'en': 'BRRI 28 Rice', 'bn': 'বিআর-২৮ চাল', 'price': 60.0, 'unit': 'kg', 'cat': 'Grains', 'chg': -1.0},
      {'en': 'Coarse Rice (Swarna)', 'bn': 'মোটা চাল (স্বর্ণা)', 'price': 52.0, 'unit': 'kg', 'cat': 'Grains', 'chg': 0.0},
      {'en': 'Chinigura Rice (Aromatic)', 'bn': 'চিনিগুঁড়া সুগন্ধি চাল', 'price': 140.0, 'unit': 'kg', 'cat': 'Grains', 'chg': 2.0},
      {'en': 'Aman Paddy', 'bn': 'আমন ধান', 'price': 34.0, 'unit': 'kg', 'cat': 'Grains', 'chg': -0.5},
      {'en': 'Wheat', 'bn': 'গম', 'price': 44.0, 'unit': 'kg', 'cat': 'Grains', 'chg': 1.5},
      {'en': 'Wheat Flour (Atta)', 'bn': 'প্যাকেট আটা', 'price': 55.0, 'unit': 'kg', 'cat': 'Grains', 'chg': 0.0},
      {'en': 'Refined Flour (Maida)', 'bn': 'ময়দা', 'price': 65.0, 'unit': 'kg', 'cat': 'Grains', 'chg': 1.0},
      {'en': 'Maize (Corn)', 'bn': 'ভুট্টা', 'price': 32.0, 'unit': 'kg', 'cat': 'Grains', 'chg': -1.5},
      {'en': 'Raw Jute (Tosha)', 'bn': 'তোষা পাট', 'price': 78.0, 'unit': 'kg', 'cat': 'Grains', 'chg': 3.0},

      // --- 2. Vegetables (শাকসবজি) ---
      {'en': 'Potato (Diamond)', 'bn': 'গোল আলু (ডায়মন্ড)', 'price': 35.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': -2.5},
      {'en': 'Local Onion (Deshi)', 'bn': 'দেশি পেঁয়াজ', 'price': 85.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': 4.5},
      {'en': 'Imported Onion', 'bn': 'আমদানি করা পেঁয়াজ', 'price': 75.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': 2.0},
      {'en': 'Garlic (Deshi)', 'bn': 'দেশি রসুন', 'price': 210.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': 5.0},
      {'en': 'Ginger (Imported)', 'bn': 'আদা', 'price': 240.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': -3.0},
      {'en': 'Green Chili', 'bn': 'কাঁচা মরিচ', 'price': 160.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': -8.0},
      {'en': 'Ripe Tomato', 'bn': 'পাকা টমেটো', 'price': 65.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': -5.0},
      {'en': 'Eggplant (Round Brinjal)', 'bn': 'গোল বেগুন', 'price': 70.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': 2.5},
      {'en': 'Cauliflower', 'bn': 'ফুলকপি', 'price': 40.0, 'unit': 'piece', 'cat': 'Vegetables', 'chg': -4.0},
      {'en': 'Cabbage', 'bn': 'বাঁধাকপি', 'price': 35.0, 'unit': 'piece', 'cat': 'Vegetables', 'chg': -2.0},
      {'en': 'Bitter Gourd (Korola)', 'bn': 'করলা / উচ্ছে', 'price': 80.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': 3.5},
      {'en': 'Bottle Gourd (Lau)', 'bn': 'কচি লাউ', 'price': 60.0, 'unit': 'piece', 'cat': 'Vegetables', 'chg': 0.0},
      {'en': 'Pointed Gourd (Potol)', 'bn': 'পটল', 'price': 50.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': -1.5},
      {'en': 'Lady Finger (Okra)', 'bn': 'ঢেঁড়শ', 'price': 55.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': -3.0},
      {'en': 'Cucumber', 'bn': 'শসা', 'price': 45.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': 1.0},
      {'en': 'Carrot', 'bn': 'গাজর', 'price': 75.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': 0.0},
      {'en': 'Sweet Pumpkin', 'bn': 'মিষ্টি কুমড়া', 'price': 40.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': -2.0},
      {'en': 'Spinach (Palong)', 'bn': 'পালং শাক', 'price': 30.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': 0.0},
      {'en': 'Red Amaranth (Lal Shak)', 'bn': 'লাল শাক', 'price': 25.0, 'unit': 'kg', 'cat': 'Vegetables', 'chg': 0.0},

      // --- 3. Pulses & Lentils (ডাল) ---
      {'en': 'Red Lentils (Deshi Masoor)', 'bn': 'দেশি মসুর ডাল', 'price': 135.0, 'unit': 'kg', 'cat': 'Pulses', 'chg': 1.0},
      {'en': 'Moong Dal', 'bn': 'মুগ ডাল', 'price': 160.0, 'unit': 'kg', 'cat': 'Pulses', 'chg': 0.5},
      {'en': 'Khesari Dal', 'bn': 'খেসারি ডাল', 'price': 105.0, 'unit': 'kg', 'cat': 'Pulses', 'chg': -1.0},
      {'en': 'Chickpeas (Chola)', 'bn': 'ছোলা বুট', 'price': 115.0, 'unit': 'kg', 'cat': 'Pulses', 'chg': 2.0},
      {'en': 'Black Gram (Mashkolai)', 'bn': 'মাষকলাই ডাল', 'price': 170.0, 'unit': 'kg', 'cat': 'Pulses', 'chg': 0.0},

      // --- 4. Oils & Spices (তেল ও মসলা) ---
      {'en': 'Mustard Oil (Pure)', 'bn': 'খাঁটি সরিষার তেল', 'price': 240.0, 'unit': 'liter', 'cat': 'Spices', 'chg': 1.5},
      {'en': 'Soybean Oil (Bottled)', 'bn': 'সয়াবিন তেল', 'price': 172.0, 'unit': 'liter', 'cat': 'Spices', 'chg': 0.0},
      {'en': 'Turmeric Powder', 'bn': 'হলুদের গুঁড়া', 'price': 340.0, 'unit': 'kg', 'cat': 'Spices', 'chg': 4.0},
      {'en': 'Dry Red Chili', 'bn': 'শুকনা মরিচ', 'price': 380.0, 'unit': 'kg', 'cat': 'Spices', 'chg': -2.0},
      {'en': 'Cumin Seeds (Jira)', 'bn': 'জিরা', 'price': 780.0, 'unit': 'kg', 'cat': 'Spices', 'chg': -1.5},
      {'en': 'Coriander Seeds (Dhone)', 'bn': 'ধনিয়া গুঁড়া', 'price': 220.0, 'unit': 'kg', 'cat': 'Spices', 'chg': 0.5},

      // --- 5. Fruits (ফলমূল) ---
      {'en': 'Banana (Sagor Kola)', 'bn': 'সাগর কলা', 'price': 40.0, 'unit': 'hali', 'cat': 'Fruits', 'chg': 0.0},
      {'en': 'Mango (Himshagor)', 'bn': 'হিমসাগর আম', 'price': 120.0, 'unit': 'kg', 'cat': 'Fruits', 'chg': -3.0},
      {'en': 'Mango (Amrupali)', 'bn': 'আম্রপালি আম', 'price': 110.0, 'unit': 'kg', 'cat': 'Fruits', 'chg': -2.0},
      {'en': 'Guava (Kazi Peyara)', 'bn': 'কাজি পেয়ারা', 'price': 60.0, 'unit': 'kg', 'cat': 'Fruits', 'chg': 1.0},
      {'en': 'Ripe Papaya', 'bn': 'পাকা পেঁপে', 'price': 70.0, 'unit': 'kg', 'cat': 'Fruits', 'chg': 0.0},
      {'en': 'Watermelon', 'bn': 'তরমুজ', 'price': 45.0, 'unit': 'kg', 'cat': 'Fruits', 'chg': -5.0},
      {'en': 'Green Coconut (Daab)', 'bn': 'কচি ডাব', 'price': 110.0, 'unit': 'piece', 'cat': 'Fruits', 'chg': 5.0},
      {'en': 'Lemon (Kagzi)', 'bn': 'কাগজি লেবু', 'price': 30.0, 'unit': 'hali', 'cat': 'Fruits', 'chg': -2.0},

      // --- 6. Poultry, Meat, Fish & Dairy (মাংস, মাছ ও ডিম) ---
      {'en': 'Broiler Chicken', 'bn': 'ব্রয়লার মুরগি', 'price': 185.0, 'unit': 'kg', 'cat': 'Livestock', 'chg': 3.0},
      {'en': 'Sonali Chicken', 'bn': 'সোনালী মুরগি', 'price': 310.0, 'unit': 'kg', 'cat': 'Livestock', 'chg': 1.5},
      {'en': 'Farm Red Eggs', 'bn': 'ফার্মের লাল ডিম', 'price': 48.0, 'unit': 'hali', 'cat': 'Livestock', 'chg': 2.0},
      {'en': 'Beef (Fresh)', 'bn': 'গরুর মাংস', 'price': 750.0, 'unit': 'kg', 'cat': 'Livestock', 'chg': 0.0},
      {'en': 'Mutton (Khasi)', 'bn': 'খাসির মাংস', 'price': 1100.0, 'unit': 'kg', 'cat': 'Livestock', 'chg': 0.0},
      {'en': 'Rui Fish (Medium)', 'bn': 'রুই মাছ', 'price': 340.0, 'unit': 'kg', 'cat': 'Fish', 'chg': -1.0},
      {'en': 'Hilsha Fish (1kg Size)', 'bn': 'পদ্মার ইলিশ (১ কেজি)', 'price': 1450.0, 'unit': 'kg', 'cat': 'Fish', 'chg': 6.0},
      {'en': 'Tilapia Fish', 'bn': 'তেলাপিয়া মাছ', 'price': 210.0, 'unit': 'kg', 'cat': 'Fish', 'chg': 0.0},
      {'en': 'Pangas Fish', 'bn': 'পাঙ্গাস মাছ', 'price': 180.0, 'unit': 'kg', 'cat': 'Fish', 'chg': -2.0},
      {'en': 'Fresh Cow Milk', 'bn': 'খাঁটি তরল দুধ', 'price': 85.0, 'unit': 'liter', 'cat': 'Dairy', 'chg': 0.0},
    ];

    return rawData.map((item) {
      final basePrice = item['price'] as double;
      return MarketPrice(
        id: '${market.toLowerCase()}_${(item['en'] as String).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}',
        commodity: item['en'] as String,
        commodityBn: item['bn'] as String,
        pricePerKg: basePrice,
        unit: item['unit'] as String,
        market: market,
        date: today,
        changePercent: (item['chg'] as num).toDouble(),
        category: item['cat'] as String,
      );
    }).toList();
  }

  void dispose() => _client.close();
}

/// A pair of price rows plus where they came from and cache timestamps.
class PriceResult {
  PriceResult(
    this.prices,
    this.source, {
    this.updatedAt,
    this.expiresAt,
  });

  final List<MarketPrice> prices;
  final PriceSource source;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
}
