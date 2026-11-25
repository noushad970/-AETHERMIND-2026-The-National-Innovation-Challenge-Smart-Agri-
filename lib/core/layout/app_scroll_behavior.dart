import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Lets a mouse drag scrollable areas, such as rows of filter chips.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}
