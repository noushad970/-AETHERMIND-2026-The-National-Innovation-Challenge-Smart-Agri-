/// Market price of a single commodity on a given day.
class MarketPrice {
  MarketPrice({
    required this.id,
    required this.commodity,
    this.commodityBn = '',
    required this.pricePerKg,
    required this.unit,
    required this.market,
    required this.date,
    this.changePercent = 0.0,
    this.category = 'General',
  });

  final String id;
  final String commodity; // English or Primary Name (e.g. Miniket Rice)
  final String commodityBn; // Bangla Name (e.g. মিনিকেট চাল)
  final double pricePerKg;
  final String unit; // 'kg' | 'ton' | 'piece' | 'dozen' | 'liter' | 'hali'
  final String market; // e.g. Dhaka, Chittagong, Rajshahi
  final DateTime date;
  final double changePercent; // vs previous day, +/-
  final String category; // 'Grains', 'Vegetables', 'Spices', 'Pulses', 'Fruits', 'Livestock', 'Fish'

  String get displayName => commodity;
  String get displayNameBn => commodityBn.isNotEmpty ? commodityBn : commodity;

  Map<String, dynamic> toMap() => {
    'id': id,
    'commodity': commodity,
    'commodityBn': commodityBn,
    'pricePerKg': pricePerKg,
    'unit': unit,
    'market': market,
    'date': date.toIso8601String(),
    'changePercent': changePercent,
    'category': category,
  };

  factory MarketPrice.fromMap(Map<String, dynamic> m) => MarketPrice(
    id: m['id'] as String,
    commodity: m['commodity'] as String,
    commodityBn: (m['commodityBn'] ?? '') as String,
    pricePerKg: (m['pricePerKg'] as num).toDouble(),
    unit: (m['unit'] ?? 'kg') as String,
    market: (m['market'] ?? '') as String,
    date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
    changePercent: ((m['changePercent'] ?? 0) as num).toDouble(),
    category: (m['category'] ?? 'General') as String,
  );
}
