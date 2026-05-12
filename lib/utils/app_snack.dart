import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App-wide snackbar utility that ensures only one snackbar is visible at a time
/// by closing any existing ones before showing a new one.
abstract final class AppSnack {
  static void show(
    String title,
    String message, {
    Color? colorText,
    Duration? duration,
    SnackPosition? snackPosition,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    bool? shouldIconPulse,
    double? maxWidth,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? borderRadius,
    Color? backgroundColor,
    Color? leftBarIndicatorColor,
    List<BoxShadow>? boxShadows,
    Gradient? backgroundGradient,
    TextButton? mainButton,
    OnTap? onTap,
    bool? isDismissible,
    bool? showProgressIndicator,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    SnackStyle? snackStyle,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    Duration? animationDuration,
    double? barBlur,
    double? overlayBlur,
    Color? overlayColor,
  }) {
    // Close any open or queued snackbars before showing the new one.
    Get.closeAllSnackbars();
    Get.snackbar(
      title,
      message,
      colorText: colorText,
      duration: duration ?? const Duration(seconds: 2),
      snackPosition: snackPosition,
      titleText: titleText,
      messageText: messageText,
      icon: icon,
      shouldIconPulse: shouldIconPulse,
      maxWidth: maxWidth,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      isDismissible: isDismissible,
      showProgressIndicator: showProgressIndicator,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle,
      forwardAnimationCurve: forwardAnimationCurve,
      reverseAnimationCurve: reverseAnimationCurve,
      animationDuration: animationDuration,
      barBlur: barBlur,
      overlayBlur: overlayBlur,
      overlayColor: overlayColor,
    );
  }
}
