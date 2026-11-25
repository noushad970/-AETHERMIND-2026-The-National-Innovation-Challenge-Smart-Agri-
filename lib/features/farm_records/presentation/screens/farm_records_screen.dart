import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/layout/adaptive_two_pane.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../providers/expenses_provider.dart';

class FarmRecordsScreen extends StatelessWidget {
  const FarmRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) => const Icon(Icons.receipt_long, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                AppStrings.farmRecords,
                AppStrings.farmRecordsBn,
              ),
            ),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: AuthGate(
          featureName: context.tr('farm records', 'খামার হিসাব'),
          child: Consumer<ExpensesProvider>(
            builder: (context, prov, _) {
              return AdaptiveTwoPane(
                primary: [
                  _SummaryCard(total: prov.total, monthly: prov.monthlyTotal),
                  const SizedBox(height: 16),
                ],
                secondary: [
                  _CategoryCard(categories: prov.totalsByCategory),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.list_alt,
                        color: AppTheme.primaryGreen,
                      ),
                      title: Text(
                        context.tr('All Expenses', 'সকল ব্যয়ের তালিকা'),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.expenseList),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(
          context.tr(AppStrings.addExpense, AppStrings.addExpenseBn),
        ),
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addExpense),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.monthly});
  final double total;
  final double monthly;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Total spent', 'মোট খরচ'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳ ${total.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('This month', 'চলতি মাস'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳ ${monthly.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.categories});
  final Map<String, double> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.tr(
              'No expenses recorded yet.',
              'এখনো কোনো ব্যয়ের রেকর্ড যোগ করা হয়নি।',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final entries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = entries.first.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('By category', 'বিভাগ অনুযায়ী খরচ'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final e in entries) ...[
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      _localizeCategory(context, e.key),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: maxValue == 0 ? 0 : e.value / maxValue,
                      minHeight: 8,
                      backgroundColor: AppTheme.divider,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('৳ ${e.value.toStringAsFixed(0)}'),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  String _localizeCategory(BuildContext context, String cat) {
    if (!context.isBn) return cat;
    switch (cat.toLowerCase()) {
      case 'seeds':
      case 'seed':
        return 'বীজ';
      case 'fertilizer':
      case 'fertilizers':
        return 'সার';
      case 'pesticide':
      case 'pesticides':
        return 'কীটনাশক';
      case 'labor':
        return 'শ্রমিক';
      case 'irrigation':
        return 'সেচ';
      case 'equipment':
        return 'যন্ত্রপাতি';
      case 'feed':
        return 'পশুখাদ্য';
      case 'medicine':
        return 'ওষুধ';
      case 'other':
        return 'অন্যান্য';
      default:
        return cat;
    }
  }
}
