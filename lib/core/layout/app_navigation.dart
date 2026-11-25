import 'package:flutter/material.dart';

/// A page route that remembers which named route created it.
///
/// The name is kept separately from [RouteSettings] so that browser URLs and
/// route arguments behave exactly as before.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({required this.routeName, required super.builder});

  final String? routeName;
}

/// Publishes the name of the top-most [AppPageRoute] for the sidebar.
class RouteTracker extends NavigatorObserver {
  final ValueNotifier<String?> current = ValueNotifier<String?>(null);

  /// The shade of the dialog or sheet on top, or null when none is open.
  final ValueNotifier<Color?> barrier = ValueNotifier<Color?>(null);

  final List<Route<dynamic>> _stack = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _publish();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _publish();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _publish();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index >= 0) _stack.removeAt(index);
    if (newRoute != null) {
      _stack.insert(index >= 0 ? index : _stack.length, newRoute);
    }
    _publish();
  }

  void _publish() {
    String? name;
    for (final route in _stack.reversed) {
      if (route is AppPageRoute && route.routeName != null) {
        name = route.routeName;
        break;
      }
    }
    final top = _stack.isEmpty ? null : _stack.last;
    final shade = top is ModalRoute && top is! PageRoute
        ? top.barrierColor
        : null;

    // Observers can fire while the tree is building, so update afterwards.
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      current.value = name;
      barrier.value = shade;
    });
    binding.ensureVisualUpdate();
  }
}

/// App-wide navigation handles, used by widgets that sit outside the navigator.
class AppNavigation {
  AppNavigation._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final RouteTracker routeTracker = RouteTracker();
}
