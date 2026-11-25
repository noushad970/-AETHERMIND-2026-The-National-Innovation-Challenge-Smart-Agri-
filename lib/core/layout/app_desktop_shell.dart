import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'app_navigation.dart';
import 'desktop_shell.dart';
import 'desktop_sidebar.dart';

/// [DesktopShell] connected to the app's navigator and providers.
class AppDesktopShell extends StatelessWidget {
  const AppDesktopShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DesktopShell(
      currentRoute: AppNavigation.routeTracker.current,
      barrier: AppNavigation.routeTracker.barrier,
      sidebarBuilder: (_, route) => _ConnectedSidebar(route: route),
      child: child,
    );
  }
}

class _ConnectedSidebar extends StatelessWidget {
  const _ConnectedSidebar({required this.route});

  final String route;

  /// Opens [target] directly above the home page.
  void _open(String target) {
    final navigator = AppNavigation.navigatorKey.currentState;
    if (navigator == null) return;
    if (target == AppRoutes.home) {
      navigator.pushNamedAndRemoveUntil(target, (_) => false);
      return;
    }
    navigator.pushNamedAndRemoveUntil(
      target,
      (r) => r is AppPageRoute && r.routeName == AppRoutes.home,
    );
  }

  Future<void> _logout(BuildContext context, bool isBn) async {
    final navigator = AppNavigation.navigatorKey.currentState;
    if (navigator == null) return;
    final auth = context.read<AuthProvider>();

    final confirmed = await showDialog<bool>(
      context: navigator.overlay!.context,
      builder: (ctx) => AlertDialog(
        title: Text(isBn ? 'লগআউট করতে চান?' : 'Confirm Logout?'),
        content: Text(
          isBn
              ? 'আপনি কি নিশ্চিত যে আপনার অ্যাকাউন্ট থেকে লগআউট করতে চান?'
              : 'Are you sure you want to logout from your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isBn ? 'লগআউট' : 'Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await auth.signOut();
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isBn = context.watch<LocaleProvider>().isBangla;
    final theme = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final unread = context.watch<NotificationProvider>().unreadCount;

    final name = auth.user?.displayName?.trim().isNotEmpty == true
        ? auth.user!.displayName!
        : (auth.user?.email?.split('@').first ?? (isBn ? 'কৃষক' : 'Farmer'));

    return DesktopSidebar(
      currentRoute: route,
      isBn: isBn,
      isDark: theme.isDarkMode,
      userName: name,
      unreadCount: unread,
      onSelect: _open,
      onToggleTheme: theme.toggleTheme,
      onToggleLanguage: context.read<LocaleProvider>().toggleLanguage,
      onLogout: () => _logout(context, isBn),
    );
  }
}
