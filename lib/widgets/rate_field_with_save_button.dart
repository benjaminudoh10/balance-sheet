import 'dart:math' as math;

import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:flutter/material.dart';

/// Single visual: text field + trailing control that looks like one outlined control.
/// Use the button to commit (e.g. persist); editing alone does not save.
class RateFieldWithSaveButton extends StatefulWidget {
  const RateFieldWithSaveButton({
    super.key,
    required this.controller,
    required this.onSave,
    this.labelText,
    this.helperText,
    this.saveTooltip = 'Save rate',
    this.focusNode,
  });

  final TextEditingController controller;
  final VoidCallback onSave;
  final String? labelText;
  final String? helperText;
  final String saveTooltip;

  /// If null, an internal [FocusNode] is created and disposed by this widget.
  final FocusNode? focusNode;

  @override
  State<RateFieldWithSaveButton> createState() => _RateFieldWithSaveButtonState();
}

class _RateFieldWithSaveButtonState extends State<RateFieldWithSaveButton> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final bool f = _focusNode.hasFocus;
    if (f != _focused) {
      setState(() => _focused = f);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color borderColor = _focused ? p.mint.withValues(alpha: 0.85) : p.border;
    final double strokeWidth = _focused ? 2.0 : 1.0;
    const double radius = 12;

    /// Matches the inner curve of [RoundedRectangleBorder] so the save area follows the outline.
    final double innerR = math.max(1.0, radius - strokeWidth);
    final BorderRadius saveStripRadius = BorderRadius.only(
      topRight: Radius.circular(innerR),
      bottomRight: Radius.circular(innerR),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: textTheme.bodySmall!.copyWith(
              color: p.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Material(
          color: p.surface,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: borderColor, width: strokeWidth),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: textTheme.bodyLarge!.copyWith(color: p.textPrimary),
                    decoration: InputDecoration(
                      hintText: '1400',
                      hintStyle: textTheme.bodyLarge!.copyWith(color: p.textSecondary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: p.border.withValues(alpha: 0.85),
                ),
                ClipRRect(
                  borderRadius: saveStripRadius,
                  child: Material(
                    color: p.surfaceElevated,
                    child: InkWell(
                      onTap: AppHaptics.wrap(widget.onSave),
                      borderRadius: saveStripRadius,
                      child: Tooltip(
                        message: widget.saveTooltip,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: p.mint,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: textTheme.bodySmall!.copyWith(
              color: p.textSecondary.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
