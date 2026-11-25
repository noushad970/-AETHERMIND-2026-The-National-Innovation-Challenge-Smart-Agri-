import 'package:flutter/widgets.dart';

/// Tells the widgets below whether to use the desktop layout.
///
/// The decision is based on the window width, so it stays true inside narrower
/// areas such as the space next to the sidebar.
class DesktopScope extends InheritedWidget {
  const DesktopScope({
    super.key,
    required this.isDesktop,
    required super.child,
  });

  /// Windows at least this wide get the desktop layout.
  static const double breakpoint = 1024;

  final bool isDesktop;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesktopScope>()?.isDesktop ??
      false;

  @override
  bool updateShouldNotify(DesktopScope oldWidget) =>
      oldWidget.isDesktop != isDesktop;
}
