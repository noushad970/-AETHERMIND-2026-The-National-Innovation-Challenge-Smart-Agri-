import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_theme.dart';
import 'header_action_bar.dart';

/// Temporary start screen used while features are added one by one.
/// It is replaced by the real splash and home screens.
class BuildPreviewScreen extends StatelessWidget {
  const BuildPreviewScreen({super.key});

  static const List<(String, String)> _routes = [
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
