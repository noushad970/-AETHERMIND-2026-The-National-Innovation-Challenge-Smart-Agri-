import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../providers/expenses_provider.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpensesProvider>().load();
    });
  }

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
              errorBuilder: (_, _, _) => const Icon(Icons.list_alt, size: 22),
            ),
            const SizedBox(width: 8),
            Text(context.tr('All Expenses', 'সকল খরচের তালিকা')),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: AuthGate(
          featureName: context.tr('expenses', 'ব্যয় হিসাব'),
          child: Consumer<ExpensesProvider>(
            builder: (context, prov, _) {
              if (prov.expenses.isEmpty) {
                return EmptyState(
                  title: context.tr('No expenses yet', 'কোনো ব্যয়ের রেকর্ড নেই'),
                  subtitle: context.tr(
                    'Add your first farm expense to start tracking.',
                    'হিসাব রাখতে আপনার প্রথম ব্যয়ের তথ্য যুক্ত করুন।',
                  ),
                  icon: Icons.receipt_long_outlined,
                  action: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.addExpense),
                    icon: const Icon(Icons.add),
                    label: Text(
                      context.tr(AppStrings.addExpense, AppStrings.addExpenseBn),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => prov.load(),
                child: ListView.separated(
                  itemCount: prov.expenses.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = prov.expenses[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGreenLight.withValues(
                          alpha: 0.2,
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      title: Text(
                        '৳ ${e.amount.toStringAsFixed(0)}  •  ${_localizeCategory(context, e.category)}',
                      ),
                      subtitle: Text(
                        '${Formatters.date.format(e.date)}'
                        '${e.description.isNotEmpty ? '  •  ${e.description}' : ''}',
                      ),
                      trailing: IconButton(
                        tooltip: context.tr(AppStrings.delete, AppStrings.deleteBn),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.danger,
                        ),
                        onPressed: () => _confirmDelete(context, e.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addExpense),
        child: const Icon(Icons.add),
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

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('Delete Expense', 'ব্যয় মুছুন')),
        content: Text(
          context.tr('Delete this expense?', 'আপনি কি এই ব্যয়ের রেকর্ডটি মুছে ফেলতে চান?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr(AppStrings.cancel, AppStrings.cancelBn)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.tr(AppStrings.delete, AppStrings.deleteBn),
              style: const TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!context.mounted) return;
      await context.read<ExpensesProvider>().remove(id);
    }
  }
}
