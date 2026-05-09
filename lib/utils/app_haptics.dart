import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// App-wide haptics for taps, navigation, and lightweight confirmations.
abstract final class AppHaptics {
  static void light() => HapticFeedback.lightImpact();

  static void selection() => HapticFeedback.selectionClick();

  static void medium() => HapticFeedback.mediumImpact();

  static void heavy() => HapticFeedback.heavyImpact();

  static VoidCallback? wrap(VoidCallback? callback) {
    if (callback == null) return null;
    return () {
      light();
      callback();
    };
  }

  static void Function(BuildContext context) wrapSlidable(
    void Function(BuildContext context) fn,
  ) {
    return (BuildContext context) {
      light();
      fn(context);
    };
  }
}
