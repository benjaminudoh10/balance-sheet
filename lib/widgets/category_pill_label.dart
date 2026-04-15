import 'package:balance_sheet/constants/category.dart';
import 'package:flutter/material.dart';

/// Category chip — same styling on transaction rows and in the category dropdown.
class CategoryPillLabel extends StatelessWidget {
  const CategoryPillLabel({
    super.key,
    required this.categoryKey,
    required this.label,
    this.compact = false,
  });

  final String categoryKey;
  final String label;

  /// Smaller padding and type — day headers, tight toolbars.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final CategoryPillStyle style = Categories.pillStyleForKey(categoryKey);
    final EdgeInsets pad = compact
        ? const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0)
        : const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0);
    final double fontSize = compact ? 9.5 : 11.0;
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: style.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: style.foreground,
        ),
      ),
    );
  }
}
