import 'package:flutter/material.dart';

import 'desktop_scope.dart';

/// How many columns of cards fit in [width].
///
/// Smaller than desktop windows always get one column.
int adaptiveColumns(
  BuildContext context,
  double width, {
  required double minItemWidth,
  double spacing = 12,
  int maxColumns = 3,
}) {
  if (!DesktopScope.of(context)) return 1;
  final fitting = ((width + spacing) / (minItemWidth + spacing)).floor();
  return fitting.clamp(1, maxColumns);
}

/// One row of a card grid whose rows grow to fit their content.
class AdaptiveCardRow extends StatelessWidget {
  const AdaptiveCardRow({
    super.key,
    required this.row,
    required this.columns,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 12,
  });

  final int row;
  final int columns;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing;

  /// The number of rows needed for [itemCount] cards.
  static int rowCount(int itemCount, int columns) =>
      (itemCount + columns - 1) ~/ columns;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) return itemBuilder(context, row);
    final first = row * columns;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var column = 0; column < columns; column++) ...[
          if (column > 0) SizedBox(width: spacing),
          Expanded(
            child: first + column < itemCount
                ? itemBuilder(context, first + column)
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

/// A scrolling list that places its cards side by side on desktop windows.
class AdaptiveCardList extends StatelessWidget {
  const AdaptiveCardList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.minItemWidth,
    this.header = const [],
    this.footer = const [],
    this.padding = const EdgeInsets.all(16),
    this.spacing = 12,
    this.separator,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// A column is only added while every card can stay this wide.
  final double minItemWidth;

  /// Full-width widgets above and below the cards.
  final List<Widget> header;
  final List<Widget> footer;

  final EdgeInsets padding;
  final double spacing;

  /// Replaces the spacing between cards while there is a single column.
  final Widget? separator;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = adaptiveColumns(
          context,
          constraints.maxWidth - padding.horizontal,
          minItemWidth: minItemWidth,
          spacing: spacing,
        );
        final rows = AdaptiveCardRow.rowCount(itemCount, columns);

        return ListView.builder(
          // Pull to refresh must work even when the cards do not fill the page.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          itemCount: header.length + rows + footer.length,
          itemBuilder: (context, index) {
            if (index < header.length) return header[index];
            final row = index - header.length;
            if (row >= rows) return footer[row - rows];

            final cards = AdaptiveCardRow(
              row: row,
              columns: columns,
              itemCount: itemCount,
              itemBuilder: itemBuilder,
              spacing: spacing,
            );
            if (row == rows - 1) return cards;
            if (columns == 1 && separator != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [cards, separator!],
              );
            }
            return Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: cards,
            );
          },
        );
      },
    );
  }
}
