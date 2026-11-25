import 'package:flutter/material.dart';

import 'desktop_scope.dart';

/// A scrolling page of sections that uses two columns on desktop windows.
///
/// On smaller windows the sections form one column in the order [top],
/// [primary], [secondary], [bottom].
class AdaptiveTwoPane extends StatelessWidget {
  const AdaptiveTwoPane({
    super.key,
    required this.primary,
    required this.secondary,
    this.top = const [],
    this.bottom = const [],
    this.padding = const EdgeInsets.all(16),
    this.lazy = true,
    this.secondaryOnLeft = false,
  });

  /// The narrowest space that still holds two columns.
  static const double minTwoColumnWidth = 700;

  /// The widest a desktop page grows when there is no second column.
  static const double singleColumnWidth = 760;

  static const double _gap = 20;

  final List<Widget> primary;
  final List<Widget> secondary;

  /// Full-width sections above and below the columns.
  final List<Widget> top;
  final List<Widget> bottom;

  final EdgeInsets padding;

  /// Whether the small-window column is a [ListView]. Otherwise every section
  /// is kept built, with its natural width, which suits forms.
  final bool lazy;

  /// Shows [secondary] in the left desktop column, for example to put the
  /// inputs before the result.
  final bool secondaryOnLeft;

  @override
  Widget build(BuildContext context) {
    final all = [...top, ...primary, ...secondary, ...bottom];

    if (!DesktopScope.of(context)) {
      if (lazy) return ListView(padding: padding, children: all);
      return SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: all,
        ),
      );
    }

    Widget column(List<Widget> children) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns =
            secondary.isNotEmpty &&
            constraints.maxWidth - padding.horizontal >= minTwoColumnWidth;

        Widget content = column(
          twoColumns
              ? [
                  ...top,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: column(secondaryOnLeft ? secondary : primary),
                      ),
                      const SizedBox(width: _gap),
                      Expanded(
                        child: column(secondaryOnLeft ? primary : secondary),
                      ),
                    ],
                  ),
                  ...bottom,
                ]
              : all,
        );
        if (secondary.isEmpty) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: singleColumnWidth),
              child: content,
            ),
          );
        }

        // Fills the height like a ListView, also when the content is short.
        return SizedBox(
          height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            child: content,
          ),
        );
      },
    );
  }
}
