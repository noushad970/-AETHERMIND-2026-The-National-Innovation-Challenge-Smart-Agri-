import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class HeaderActionBar extends StatelessWidget {
  const HeaderActionBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;

    return IconButton(
      onPressed: () => themeProv.toggleTheme(),
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode_outlined,
        color: isDark ? Colors.amber : Colors.white,
        size: 20,
      ),
      tooltip: isDark ? 'Light Mode (আলো)' : 'Dark Mode (ডার্ক)',
    );
  }
}
