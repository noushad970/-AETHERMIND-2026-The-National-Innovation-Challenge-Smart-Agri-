import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'desktop_scope.dart';

/// Places the sidebar next to the app on wide windows.
///
/// The widget tree keeps the same shape at every width, so resizing the window
/// never resets the pages.
class DesktopShell extends StatelessWidget {
  const DesktopShell({
    super.key,
    required this.currentRoute,
    required this.sidebarBuilder,
    required this.child,
    this.barrier,
  });

  static const double sidebarWidth = 264;

  /// Full-window pages that come before the user is inside the app.
  static const Set<String> routesWithoutSidebar = {
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.appTutorial,
    AppRoutes.login,
    AppRoutes.register,
  };

  final ValueListenable<String?> currentRoute;
  final Widget Function(BuildContext context, String route) sidebarBuilder;
  final Widget child;

  /// While this holds a color, a dialog is open and the sidebar is shaded.
  final ValueListenable<Color?>? barrier;

  Widget _shaded(Widget sidebar) {
    final barrier = this.barrier;
    if (barrier == null) return sidebar;
    return ValueListenableBuilder<Color?>(
      valueListenable: barrier,
      child: sidebar,
      builder: (context, color, content) => Stack(
        fit: StackFit.expand,
        children: [
          content!,
          if (color != null)
            ColoredBox(key: const ValueKey('sidebar-barrier'), color: color),
        ],
      ),
    );
  }

  ThemeData _desktopTheme(ThemeData base) => base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      shape: const Border(),
      centerTitle: false,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= DesktopScope.breakpoint;
    final theme = Theme.of(context);

    return DesktopScope(
      isDesktop: isDesktop,
      child: Theme(
        data: isDesktop ? _desktopTheme(theme) : theme,
        child: ValueListenableBuilder<String?>(
          valueListenable: currentRoute,
          child: child,
          builder: (context, route, content) {
            final showSidebar =
                isDesktop &&
                route != null &&
                !routesWithoutSidebar.contains(route);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: showSidebar ? sidebarWidth : 0,
                  child: showSidebar
                      ? _shaded(sidebarBuilder(context, route))
                      : null,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final media = MediaQuery.of(context);
                      return MediaQuery(
                        // Pages beside the sidebar see their real width.
                        data: showSidebar
                            ? media.copyWith(
                                size: Size(
                                  constraints.maxWidth,
                                  media.size.height,
                                ),
                              )
                            : media,
                        child: content!,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
