import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

CrossAxisAlignment _crossAxisForTextAlign(TextAlign textAlign) {
  return switch (textAlign) {
    TextAlign.end => CrossAxisAlignment.end,
    TextAlign.start => CrossAxisAlignment.start,
    _ => CrossAxisAlignment.center,
  };
}

/// Placeholder lines matching [DualCurrencyTotal] single vs dual layout.
class ObscuredAggregateAmount extends StatelessWidget {
  const ObscuredAggregateAmount({
    super.key,
    required this.textAlign,
    required this.primaryStyle,
    required this.secondaryStyle,
    this.compactSecondary = false,
    required this.dualLine,
  });

  final TextAlign textAlign;
  final TextStyle primaryStyle;
  final TextStyle secondaryStyle;
  final bool compactSecondary;
  final bool dualLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: _crossAxisForTextAlign(textAlign),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '*****',
          textAlign: textAlign,
          style: primaryStyle.copyWith(letterSpacing: 2.5),
        ),
        if (dualLine) ...<Widget>[
          SizedBox(height: compactSecondary ? 2 : 4),
          Text(
            '****',
            textAlign: textAlign,
            style: secondaryStyle.copyWith(letterSpacing: 2),
          ),
        ],
      ],
    );
  }
}

/// For aggregate amounts: primary line in LCY, secondary line as FCY equivalent.
class DualCurrencyTotal extends StatelessWidget {
  const DualCurrencyTotal({
    super.key,
    required this.lcyMinor,
    required this.primaryStyle,
    this.secondaryStyle,
    this.textAlign = TextAlign.center,
    this.compactSecondary = false,
    this.showFcyEquivalent = true,
    this.obscureAmount = false,
  });

  final int lcyMinor;
  final TextStyle primaryStyle;
  final TextStyle? secondaryStyle;
  final TextAlign textAlign;
  final bool compactSecondary;

  /// When false, only the LCY line is shown (no `≈` FCY line).
  final bool showFcyEquivalent;

  /// When true, shows masked bullets instead of figures (still respects dual-line layout).
  final bool obscureAmount;

  @override
  Widget build(BuildContext context) {
    final CurrencyController c = Get.find<CurrencyController>();
    return Obx(() {
      final TextStyle sec = secondaryStyle ??
          Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
              );
      final bool dual = showFcyEquivalent && c.showDualTotals;
      if (obscureAmount) {
        return ObscuredAggregateAmount(
          textAlign: textAlign,
          primaryStyle: primaryStyle,
          secondaryStyle: sec,
          compactSecondary: compactSecondary,
          dualLine: dual,
        );
      }
      if (!showFcyEquivalent || !c.showDualTotals) {
        return Text(
          formatMinorUnits(lcyMinor, c.lcyCode.value),
          textAlign: textAlign,
          style: primaryStyle,
        );
      }
      final int fcy = c.fcyMinorFromLcyMinor(lcyMinor);
      return Column(
        crossAxisAlignment: _crossAxisForTextAlign(textAlign),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMinorUnits(lcyMinor, c.lcyCode.value),
            textAlign: textAlign,
            style: primaryStyle,
          ),
          SizedBox(height: compactSecondary ? 2 : 4),
          Text(
            '≈ ${formatMinorUnits(fcy, c.fcyCode.value)}',
            textAlign: textAlign,
            style: sec,
          ),
        ],
      );
    });
  }
}

/// Signed net totals (e.g. today) with dual currency.
class DualCurrencySignedNet extends StatelessWidget {
  const DualCurrencySignedNet({
    super.key,
    required this.netMinor,
    required this.primaryStyle,
    this.secondaryStyle,
    this.textAlign = TextAlign.center,
  });

  final int netMinor;
  final TextStyle primaryStyle;
  final TextStyle? secondaryStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final CurrencyController c = Get.find<CurrencyController>();
    return Obx(() {
      final TextStyle sec = secondaryStyle ??
          Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
              );
      if (netMinor == 0) {
        if (!c.showDualTotals) {
          return Text(
            formatMinorUnits(0, c.lcyCode.value),
            textAlign: textAlign,
            style: primaryStyle,
          );
        }
        return Column(
          crossAxisAlignment: textAlign == TextAlign.center
              ? CrossAxisAlignment.center
              : textAlign == TextAlign.end
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatMinorUnits(0, c.lcyCode.value),
              textAlign: textAlign,
              style: primaryStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '≈ ${formatMinorUnits(0, c.fcyCode.value)}',
              textAlign: textAlign,
              style: sec,
            ),
          ],
        );
      }
      final bool neg = netMinor < 0;
      final String sign = neg ? '−' : '+';
      final int absLcy = netMinor.abs();
      if (!c.showDualTotals) {
        return Text(
          '$sign ${formatMinorUnits(absLcy, c.lcyCode.value)}',
          textAlign: textAlign,
          style: primaryStyle,
        );
      }
      final int absFcy = c.fcyMinorFromLcyMinor(absLcy);
      return Column(
        crossAxisAlignment: textAlign == TextAlign.center
            ? CrossAxisAlignment.center
            : textAlign == TextAlign.end
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$sign ${formatMinorUnits(absLcy, c.lcyCode.value)}',
            textAlign: textAlign,
            style: primaryStyle,
          ),
          const SizedBox(height: 4),
          Text(
            '≈ $sign ${formatMinorUnits(absFcy, c.fcyCode.value)}',
            textAlign: textAlign,
            style: sec,
          ),
        ],
      );
    });
  }
}
