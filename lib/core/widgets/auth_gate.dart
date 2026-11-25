import 'package:flutter/material.dart';

/// Wraps any screen that requires a signed-in user.
///
/// For testing purposes, authentication is bypassed so that all features
/// (crops, expenses, market prices, AI advice, chatbot, community feed, etc.)
/// are immediately accessible and testable.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child, this.featureName});

  /// The widget tree to render.
  final Widget child;

  /// Optional human-readable label used in sign-in prompt copy.
  final String? featureName;

  @override
  Widget build(BuildContext context) {
    // For testing: bypass authentication check so all features can be accessed
    return child;
  }
}
