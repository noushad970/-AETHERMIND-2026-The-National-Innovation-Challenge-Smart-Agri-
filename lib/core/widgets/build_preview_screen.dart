import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'header_action_bar.dart';

/// Temporary start screen used while features are added one by one.
/// It is replaced by the real splash and home screens.
class BuildPreviewScreen extends StatelessWidget {
  const BuildPreviewScreen({super.key});

  static const List<(String, String)> _routes = [
    ('onboarding', AppRoutes.onboarding),
    ('appTutorial', AppRoutes.appTutorial),
    ('login', AppRoutes.login),
    ('cropList', AppRoutes.cropList),
    ('addCrop', AppRoutes.addCrop),
    ('cropLibrary', AppRoutes.cropLibrary),
    ('diseaseDetect', AppRoutes.diseaseDetect),
    ('chatbot', AppRoutes.chatbot),
    ('weatherScreen', AppRoutes.weatherScreen),
    ('marketPrices', AppRoutes.marketPrices),
    ('farmRecords', AppRoutes.farmRecords),
    ('expenseList', AppRoutes.expenseList),
    ('addExpense', AppRoutes.addExpense),
    ('notifications', AppRoutes.notifications),
    ('livestockList', AppRoutes.livestockList),
    ('addLivestock', AppRoutes.addLivestock),
    ('fishList', AppRoutes.fishList),
    ('addFish', AppRoutes.addFish),
    ('settings', AppRoutes.settings),
    ('krishiHelpline', AppRoutes.krishiHelpline),
    ('yieldForecaster', AppRoutes.yieldForecaster),
    ('smartIrrigation', AppRoutes.smartIrrigation),
    ('communityFeed', AppRoutes.communityFeed),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: const [HeaderActionBar()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.eco, size: 64, color: AppTheme.primaryGreenLight),
          const SizedBox(height: 12),
          const Text(
            'Features are being added one at a time.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          for (final (label, route) in _routes)
            Card(
              child: ListTile(
                title: Text(label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, route),
              ),
            ),
        ],
      ),
    );
  }
}
