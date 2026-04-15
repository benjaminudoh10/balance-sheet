import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:balance_sheet/screens/pin_lock.dart';
import 'package:balance_sheet/security/pin_hash.dart';
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
  void reloadFromStorage() {
    final GetStorage box = GetStorage();
    pinIsSet.value = PinHash.hasPin(box);
    fingerprintInUse.value = box.read(AppConstants.USE_FINGERPRINT) ?? false;
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
      Get.snackbar(
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
      Get.snackbar(
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
      Get.snackbar(
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
      } else Get.offAll(LockScreen(), transition: Transition.noTransition);
      /* end of hack */
      Get.snackbar(
        "Error",
        "Invalid PIN provided. Try again.",
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } else {
      if (fromSettings.value) {
        await PinHash.clearPin(box);
        pinIsSet.value = false;
        Get.back();
        Get.snackbar(
          "Success",
          "PIN removed successfully.",
          backgroundColor: AppColors.GREEN,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        fromSettings.value = false;
      } else {
        Get.offAll(Home());
      }
    }
  }

  activateFingerPrint(bool value) {
    if (!pinIsSet.value && value) {
      Get.snackbar(
        "Error",
        "Setup PIN to make use of fingerprint lock",
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    setValueInStorage(AppConstants.USE_FINGERPRINT, value);
    fingerprintInUse.value = value;
  }

  unlockWithFingerprint() async {
    if (!fingerprintInUse.value) return;

    LocalAuthentication localAuth = LocalAuthentication();
    bool canCheckBiometrics = await localAuth.canCheckBiometrics;
    if (canCheckBiometrics) {
      try {
        bool didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Use your fingerprint to unlock app',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
        if (didAuthenticate) {
          if (fromSettings.value) {
            final GetStorage box = GetStorage();
            await PinHash.clearPin(box);
            pinIsSet.value = false;
            Get.back();
            Get.snackbar(
              "Success",
              "PIN removed successfully.",
              backgroundColor: AppColors.GREEN,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );
            fromSettings.value = false;
          } else Get.offAll(Home());
        } else {
          Get.snackbar(
            "Error",
            "Fingerprint auth failed",
            backgroundColor: AppColors.SNACKBAR_RED,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
      } catch (error) {
        Get.snackbar(
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
