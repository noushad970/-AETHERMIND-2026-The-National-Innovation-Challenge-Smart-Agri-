import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/expense.dart';
import '../providers/expenses_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _category = 'seeds';
  DateTime _date = DateTime.now();

  static const _categories = [
    'seeds',
    'fertilizer',
    'pesticide',
    'labor',
    'equipment',
    'other',
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final e = Expense(
      id: const Uuid().v4(),
      cropId: '',
      amount: double.parse(_amountCtrl.text.trim()),
      category: _category,
      date: _date,
      description: _descriptionCtrl.text.trim(),
    );
    await context.read<ExpensesProvider>().save(e);
    if (!mounted) return;
    Navigator.of(context).pop();
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
              errorBuilder: (_, _, _) => const Icon(Icons.add_card, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                AppStrings.addExpense,
                AppStrings.addExpenseBn,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.tr(AppStrings.amount, AppStrings.amountBn),
                    prefixIcon: const Icon(Icons.payments_outlined),
                    prefixText: '৳ ',
                  ),
                  validator: (v) => Validators.positiveNumber(
                    v,
                    fieldName: context.tr('Amount', 'পরিমাণ'),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: context.tr(AppStrings.category, AppStrings.categoryBn),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final c in _categories)
                      DropdownMenuItem(
                        value: c,
                        child: Text(_localizeCategory(context, c)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? 'seeds'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(context.tr('Expense Date', 'খরচের তারিখ')),
                  subtitle: Text(
                    '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.tr(AppStrings.description, AppStrings.descriptionBn),
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(context.tr(AppStrings.save, AppStrings.saveBn)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _localizeCategory(BuildContext context, String cat) {
    if (!context.isBn) return cat;
    switch (cat.toLowerCase()) {
      case 'seeds':
        return 'বীজ (Seeds)';
      case 'fertilizer':
        return 'সার (Fertilizer)';
      case 'pesticide':
        return 'কীটনাশক (Pesticide)';
      case 'labor':
        return 'শ্রমিক (Labor)';
      case 'equipment':
        return 'যন্ত্রপাতি (Equipment)';
      case 'other':
        return 'অন্যান্য (Other)';
      default:
        return cat;
    }
  }
}
