import 'package:balance_sheet/constants/app.dart';
import 'package:flutter/material.dart';

/// Sliver list of cards: one column on narrow widths, two columns (same pattern as home
/// recent transactions) when [contentWidth] ≥ [twoColumnMinWidth].
SliverPadding adaptiveCardListSliver({
  required double contentWidth,
  required EdgeInsets padding,
  required int itemCount,
  required Widget Function(BuildContext context, int index) itemBuilder,
  double twoColumnMinWidth = AppConstants.homeTransactionTwoColumnMinWidth,
}) {
  if (itemCount == 0) {
    return SliverPadding(
      padding: padding,
      sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  final bool twoCol = contentWidth >= twoColumnMinWidth;
  if (!twoCol) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 10),
              child: itemBuilder(context, index),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }

  final int rowCount = (itemCount + 1) ~/ 2;
  return SliverPadding(
    padding: padding,
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int rowIndex) {
          final int i0 = rowIndex * 2;
          final int? i1 = i0 + 1 < itemCount ? i0 + 1 : null;
          return Padding(
            padding: EdgeInsets.only(bottom: rowIndex == rowCount - 1 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: itemBuilder(context, i0)),
                const SizedBox(width: 10),
                Expanded(
                  child: i1 != null ? itemBuilder(context, i1) : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
        childCount: rowCount,
      ),
    ),
  );
}
