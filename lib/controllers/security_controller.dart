import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:balance_sheet/screens/pin_lock.dart';
import 'package:balance_sheet/security/pin_hash.dart';
import 'package:balance_sheet/utils/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityController extends GetxController {
  /// True when a PIN is configured (hash + salt in storage).
  final RxBool pinIsSet = false.obs;
  RxString currentPinEnteredByUser = "".obs;
  RxString newPin = "".obs;
  RxString verifyPin = "".obs;

  RxBool showNewPin = false.obs;
  RxBool showVerifyInput = false.obs;
  RxBool fromSettings = false.obs;
  RxBool fingerprintInUse = false.obs;

  /// When [pinIsSet] is true: user has unlocked to main content this session, until
  /// [onRequireScreenLock] or app backgrounding.
  final RxBool sessionUnlocked = false.obs;

  /// Counts in-flight sub-flows (system file pickers, biometric prompts, etc.) that briefly
  /// background the Flutter activity but should NOT trigger auto-lock.
  ///
  /// Without this, opening a system picker on Android pauses the Flutter activity, which would
  /// otherwise navigate the user to [LockScreen] behind the picker. When the picker returns, the
  /// originating widget is unmounted and any downstream flow (e.g. import, export) silently aborts.
  int _subFlowDepth = 0;

  /// True while a sub-flow is in progress; auto-lock should be suppressed.
  bool get isSubFlowActive => _subFlowDepth > 0;

  /// Wraps a sub-flow that opens a system UI (file picker, document save, biometrics) so the
  /// app does NOT relock when the host activity briefly backgrounds.
  ///
  /// Always pairs push/pop, even if [body] throws.
  Future<T> runWithSubFlow<T>(Future<T> Function() body) async {
    _subFlowDepth++;
    try {
      return await body();
    } finally {
      if (_subFlowDepth > 0) {
        _subFlowDepth--;
      }
    }
  }

  @override
  void onReady() {
    super.onReady();

    // for overriding the password
    // GetStorage box = GetStorage();
    // box.write(AppConstants.USER_PIN_KEY, null);
    _init();
  }

  _init() {
    reloadFromStorage();
  }

  /// Reloads PIN state and fingerprint flags from [GetStorage] (e.g. after backup import).
  ///
  /// Does not change [sessionUnlocked]; clearing it here broke autolock when the user was still
  /// on [Home] after a data-only refresh (lifecycle only navigates to [LockScreen] when the
  /// session had been unlocked). Use [onRequireScreenLock] when trust boundaries change.
  void reloadFromStorage() {
    final GetStorage box = GetStorage();
    pinIsSet.value = PinHash.hasPin(box);
    fingerprintInUse.value = box.read(AppConstants.USE_FINGERPRINT) ?? false;
  }

  void onRequireScreenLock() {
    sessionUnlocked.value = false;
  }

  /// Call when the user may see [Home] while a PIN is configured (unlock or in-app PIN flows).
  void markSessionUnlocked() {
    if (!pinIsSet.value) return;
    sessionUnlocked.value = true;
  }

  reset() {
    showVerifyInput.value = false;
    verifyPin.value = "";
    newPin.value = "";
    showNewPin.value = false;
    currentPinEnteredByUser.value = "";
  }

  setValueInStorage(String key, value) {
    GetStorage box = GetStorage();
    box.write(key, value);
  }

  Future<bool> setNewPin() async {
    if (newPin.value != verifyPin.value) {
      /* this is a hack. find a better solution by understanding why reset does not work */
      Get.back();
      Get.to(Pin(), transition: Transition.noTransition);
      /* end of hack */
      AppSnack.show(
        "Error",
        "PINs do not match",
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      reset();
      return false;
    }

    final GetStorage box = GetStorage();
    await PinHash.persistPin(box, newPin.value);
    pinIsSet.value = true;
    setValueInStorage(AppConstants.USE_FINGERPRINT, false);
    fingerprintInUse.value = false;
    markSessionUnlocked();

    reset();
    Get.back();

    return true;
  }

  Future<bool> changePin() async {
    final GetStorage box = GetStorage();
    if (!PinHash.verify(box, currentPinEnteredByUser.value)) {
      reset();
      /* this is a hack. find a better solution by understanding why reset does not work */
      Get.back();
      Get.to(Pin(), transition: Transition.noTransition);
      /* end of hack */
      AppSnack.show(
        "Error",
        "Invalid PIN provided",
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      return false;
    } else if (newPin.value != verifyPin.value) {
      reset();
      /* this is a hack. find a better solution by understanding why reset does not work */
      Get.back();
      Get.to(Pin(), transition: Transition.noTransition);
      /* end of hack */
      AppSnack.show(
        "Error",
        "PINs do not match",
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      return false;
    }

    await PinHash.persistPin(box, newPin.value);
    pinIsSet.value = true;
    markSessionUnlocked();
    reset();
    Get.back();

    return true;
  }

  Future<void> confirmPin(String value) async {
    final GetStorage box = GetStorage();
    if (!PinHash.verify(box, value)) {
      /* this is a hack. find a better solution by understanding why reset does not work */
      if (fromSettings.value) {
        Get.back();
        Get.to(LockScreen(), transition: Transition.noTransition);
      } else {
        Get.offAll(LockScreen(), transition: Transition.noTransition);
      }
      /* end of hack */
      AppSnack.show(
        "Error",
        "Invalid PIN provided. Try again.",
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } else {
      final Map<String, dynamic>? args = Get.arguments as Map<String, dynamic>?;
      final bool pinOnly = args?['pin_only'] ?? false;

      // If it's a re-auth request that ISN'T the PIN removal flow, return early.
      if (args != null && args.containsKey('reason') && !pinOnly) {
        Get.back(result: true);
        return;
      }

      if (fromSettings.value) {
        await PinHash.clearPin(box);
        pinIsSet.value = false;
        sessionUnlocked.value = false;
        Get.back();
        AppSnack.show(
          "Success",
          "PIN removed successfully.",
          backgroundColor: AppColors.GREEN,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        fromSettings.value = false;
      } else {
        markSessionUnlocked();
        Get.offAll(Home());
      }
    }
  }

  /// Force re-authentication (PIN only) to confirm a security change.
  Future<void> activateFingerPrint(bool value) async {
    if (!value) {
      // Disabling Fingerprint: Requires Biometric auth.
      final bool confirmed =
          await authenticateUser('Use fingerprint to disable biometric unlock');
      if (!confirmed) return;
    } else {
      if (!pinIsSet.value) {
        AppSnack.show(
          "Error",
          "Setup PIN to make use of fingerprint lock",
          backgroundColor: AppColors.SNACKBAR_RED,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
    }
    setValueInStorage(AppConstants.USE_FINGERPRINT, value);
    fingerprintInUse.value = value;
  }

  Future<bool> requestPinConfirmation(String reason) async {
    // If fingerprint is enabled, try that first.
    if (fingerprintInUse.value) {
      final bool biometricsConfirmed =
          await authenticateUser('Use fingerprint to proceed with PIN removal');
      if (!biometricsConfirmed) return false;
    }

    // Always follow up with explicit PIN entry.
    final dynamic result = await Get.toNamed('/lock', arguments: {
      'reason': reason,
      'pin_only': true,
    });
    return result == true;
  }

  /// Prompts for authentication (Biometric or PIN) and returns true if successful.
  /// Used for protecting sensitive views like Trash.
  Future<bool> authenticateUser(String reason) async {
    if (!pinIsSet.value) return true;

    // Try fingerprint first if enabled
    if (fingerprintInUse.value) {
      final LocalAuthentication localAuth = LocalAuthentication();
      final bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      if (canCheckBiometrics) {
        try {
          final bool didAuthenticate =
              await runWithSubFlow<bool>(() => localAuth.authenticate(
                    localizedReason: reason,
                    biometricOnly: true,
                    persistAcrossBackgrounding: true,
                  ));
          if (didAuthenticate) return true;

          // If biometrics were attempted but failed/canceled, don't automatically
          // fallback to PIN screen to avoid redundant UI steps.
          return false;
        } catch (e) {
          debugPrint('Biometric auth failed: $e');
          return false;
        }
      }
    }

    // Fallback or explicit PIN request
    final dynamic result =
        await Get.toNamed('/lock', arguments: {'reason': reason});
    return result == true;
  }

  unlockWithFingerprint({bool isSettingsFlow = false}) async {
    if (!fingerprintInUse.value) return;

    LocalAuthentication localAuth = LocalAuthentication();
    bool canCheckBiometrics = await localAuth.canCheckBiometrics;
    if (canCheckBiometrics) {
      try {
        bool didAuthenticate =
            await runWithSubFlow<bool>(() => localAuth.authenticate(
                  localizedReason: 'Use your fingerprint to unlock app',
                  biometricOnly: true,
                  persistAcrossBackgrounding: true,
                ));
        if (didAuthenticate) {
          if (isSettingsFlow) {
            Get.back(result: true);
            return;
          }

          markSessionUnlocked();
          Get.offAll(Home());
        } else {
          AppSnack.show(
            "Error",
            "Fingerprint auth failed",
            backgroundColor: AppColors.SNACKBAR_RED,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
      } catch (error) {
        AppSnack.show(
          "Error",
          "Fingerprint auth failed",
          backgroundColor: AppColors.SNACKBAR_RED,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    }
  }
}
