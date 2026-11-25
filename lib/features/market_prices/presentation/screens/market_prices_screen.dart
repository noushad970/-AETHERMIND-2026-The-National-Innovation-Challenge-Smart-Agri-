import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/layout/adaptive_card_list.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/market_price.dart';
import '../../../../data/services/market_price_service.dart';
import '../providers/market_prices_provider.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';

  static const _markets = [
    'Dhaka',
    'Chittagong',
    'Rajshahi',
    'Khulna',
    'Sylhet',
    'Rangpur',
    'Barishal',
    'Mymensingh',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketPricesProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.trending_up, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                AppStrings.marketPrices,
                AppStrings.marketPricesBn,
              ),
            ),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: AgriAtmosphericBackground(
        child: SafeArea(
          child: AuthGate(
            featureName: context.tr('market prices', 'বাজার দর'),
            child: Consumer<MarketPricesProvider>(
              builder: (context, prov, _) {
              var filtered = prov.prices;

              // Filter by category
              if (_selectedCategory != 'All') {
                filtered = filtered.where((p) {
                  if (_selectedCategory == 'Grains') return p.category == 'Grains';
                  if (_selectedCategory == 'Vegetables') return p.category == 'Vegetables';
                  if (_selectedCategory == 'Pulses') return p.category == 'Pulses';
                  if (_selectedCategory == 'Spices') return p.category == 'Spices';
                  if (_selectedCategory == 'Fruits') return p.category == 'Fruits';
                  if (_selectedCategory == 'Meat & Fish') {
                    return p.category == 'Livestock' ||
                        p.category == 'Fish' ||
                        p.category == 'Dairy';
                  }
                  return true;
                }).toList();
              }

              // Filter by query (English or Bangla)
              if (_query.isNotEmpty) {
                final q = _query.toLowerCase();
                filtered = filtered
                    .where(
                      (p) =>
                          p.commodity.toLowerCase().contains(q) ||
                          p.commodityBn.toLowerCase().contains(q),
                    )
                    .toList();
              }

              return Column(
                children: [
                  // Top Search & Controls Container
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Search Bar & AI Refresh Button
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  hintText: context.tr(
                                    'Search 50+ food products...',
                                    '৫০+ কৃষি পণ্যের নাম দিয়ে খুঁজুন...',
                                  ),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.divider),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.divider),
                                  ),
                                ),
                                onChanged: (v) => setState(() => _query = v.trim()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: prov.isLoading
                                  ? null
                                  : () => prov.refreshWithGemini(),
                              icon: prov.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome, size: 16),
                              label: Text(
                                context.tr('AI Update', 'এআই আপডেট'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Division Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final m in _markets)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(
                                      _marketLabel(context, m),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: prov.market == m
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    selected: prov.market == m,
                                    selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                    onSelected: (_) => prov.load(market: m),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Category Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCatChip('All', isBn ? 'সকল' : 'All'),
                              _buildCatChip('Grains', isBn ? 'ধান ও চাল' : 'Grains'),
                              _buildCatChip('Vegetables', isBn ? 'শাকসবজি' : 'Vegetables'),
                              _buildCatChip('Pulses', isBn ? 'ডালজাতীয়' : 'Pulses'),
                              _buildCatChip('Spices', isBn ? 'তেল ও মসলা' : 'Oils & Spices'),
                              _buildCatChip('Fruits', isBn ? 'ফলমূল' : 'Fruits'),
                              _buildCatChip('Meat & Fish', isBn ? 'মাংস, মাছ ও ডিম' : 'Meat & Fish'),
                            ],
                          ),
                        ),

                        // Info & Source Bar with 7-Day DB Sync Status
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  isBn
                                      ? '${filtered.length}টি খাদ্যপণ্যের দর'
                                      : '${filtered.length} items listed',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (prov.lastUpdated != null)
                                    Text(
                                      '${context.tr("Next AI update in", "পরবর্তী আপডেট")}: ${prov.daysUntilNextUpdate}${context.tr("d", "দিন")}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  _SourceChip(source: prov.source),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Commodity List View
                  Expanded(
                    child: () {
                      if (prov.isLoading && prov.prices.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Fetching market prices with Gemini AI...'),
                            ],
                          ),
                        );
                      }
                      if (filtered.isEmpty) {
                        return EmptyState(
                          title: context.tr(
                            AppStrings.noData,
                            AppStrings.noDataBn,
                          ),
                          subtitle: context.tr(
                            'No commodity matched your search.',
                            'আপনার অনুসন্ধানের সাথে কোনো পণ্য মেলেনি।',
                          ),
                          icon: Icons.trending_up,
                          action: TextButton.icon(
                            onPressed: prov.isLoading
                                ? null
                                : () => prov.refreshWithGemini(),
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              context.tr(
                                AppStrings.retry,
                                AppStrings.retryBn,
                              ),
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () => prov.refreshWithGemini(),
                        child: AdaptiveCardList(
                          minItemWidth: 380,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          // The price cards carry their own side margins.
                          spacing: 0,
                          separator: const Divider(height: 1),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) =>
                              _PriceTile(price: filtered[i]),
                        ),
                      );
                    }(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCatChip(String key, String label) {
    final selected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = key),
      ),
    );
  }

  String _marketLabel(BuildContext context, String m) {
    if (!context.isBn) return m;
    switch (m) {
      case 'Dhaka':
        return 'ঢাকা';
      case 'Chittagong':
        return 'চট্টগ্রাম';
      case 'Khulna':
        return 'খুলনা';
      case 'Rajshahi':
        return 'রাজশাহী';
      case 'Sylhet':
        return 'সিলেট';
      case 'Rangpur':
        return 'রংপুর';
      case 'Barishal':
        return 'বরিশাল';
      case 'Mymensingh':
        return 'ময়মনসিংহ';
      default:
        return m;
    }
  }
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({required this.price});
  final MarketPrice price;

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    final up = price.changePercent >= 0;
    final isNeutral = price.changePercent == 0;
    final color = isNeutral
        ? AppTheme.textSecondary
        : up
            ? AppTheme.danger
            : AppTheme.success;

    final primaryName = isBn ? price.displayNameBn : price.displayName;
    final secondaryName = isBn ? price.commodity : price.commodityBn;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _catColor(price.category).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _catIcon(price.category),
              color: _catColor(price.category),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        primaryName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _catColor(price.category).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _catLabel(context, price.category),
                        style: TextStyle(
                          fontSize: 10,
                          color: _catColor(price.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        secondaryName.isNotEmpty && secondaryName != primaryName
                            ? '$secondaryName • ${price.market}'
                            : price.market,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${price.pricePerKg.toStringAsFixed(0)} ৳ / ${_unitLabel(context, price.unit)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isNeutral)
                  Icon(
                    up ? Icons.arrow_upward : Icons.arrow_downward,
                    color: color,
                    size: 12,
                  ),
                Text(
                  '${price.changePercent.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Grains':
        return Icons.eco;
      case 'Vegetables':
        return Icons.grass;
      case 'Pulses':
        return Icons.scatter_plot;
      case 'Spices':
        return Icons.local_florist;
      case 'Fruits':
        return Icons.apple;
      case 'Livestock':
      case 'Meat':
        return Icons.pets;
      case 'Fish':
        return Icons.water;
      case 'Dairy':
        return Icons.local_drink;
      default:
        return Icons.shopping_basket;
    }
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Grains':
        return AppTheme.primaryGreen;
      case 'Vegetables':
        return Colors.green.shade700;
      case 'Pulses':
        return Colors.brown.shade600;
      case 'Spices':
        return Colors.deepOrange;
      case 'Fruits':
        return Colors.orange.shade800;
      case 'Livestock':
      case 'Meat':
        return AppTheme.danger;
      case 'Fish':
        return AppTheme.skyBlue;
      case 'Dairy':
        return Colors.indigo;
      default:
        return AppTheme.primaryGreen;
    }
  }

  String _catLabel(BuildContext context, String cat) {
    if (!context.isBn) return cat;
    switch (cat) {
      case 'Grains':
        return 'খাদ্যশস্য';
      case 'Vegetables':
        return 'শাকসবজি';
      case 'Pulses':
        return 'ডাল';
      case 'Spices':
        return 'মসলা ও তেল';
      case 'Fruits':
        return 'ফলমূল';
      case 'Livestock':
        return 'মাংস ও ডিম';
      case 'Fish':
        return 'মাছ';
      case 'Dairy':
        return 'দুগ্ধজাত';
      default:
        return 'পণ্য';
    }
  }

  String _unitLabel(BuildContext context, String unit) {
    if (!context.isBn) return unit;
    switch (unit) {
      case 'kg':
        return 'কেজি';
      case 'liter':
        return 'লিটার';
      case 'piece':
        return 'টি';
      case 'hali':
        return 'হালি';
      case 'dozen':
        return 'ডজন';
      case 'ton':
        return 'টন';
      default:
        return unit;
    }
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});
  final PriceSource source;

  @override
  Widget build(BuildContext context) {
    final (label, icon, fg, bg) = switch (source) {
      PriceSource.geminiAi => (
        context.tr('Gemini AI Live', 'জেমিনি এআই লাইভ দর'),
        Icons.auto_awesome,
        Colors.purple.shade700,
        Colors.purple.withValues(alpha: 0.12),
      ),
      PriceSource.cached => (
        context.tr('Cloud DB (7-Day)', 'ক্লাউড ডাটাবেজ (৭ দিন)'),
        Icons.cloud_done_rounded,
        const Color(0xFF00796B),
        const Color(0xFF00796B).withValues(alpha: 0.12),
      ),
      PriceSource.mock => (
        context.tr('Market Standard', 'বাজারের মানদণ্ড দর'),
        Icons.storefront_rounded,
        AppTheme.primaryGreen,
        AppTheme.primaryGreen.withValues(alpha: 0.12),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
