import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:balance_sheet/screens/pin_lock.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SecurityController extends GetxController {
  RxString currentStoredPin = "".obs;
  RxString currentPinEnteredByUser = "".obs;
  RxString newPin = "".obs;
  RxString verifyPin = "".obs;

  RxBool showNewPin = false.obs;
  RxBool showVerifyInput = false.obs;
  RxBool fromSettings = false.obs;

  @override
  void onReady() {
    super.onReady();

    // for overriding the password
    // GetStorage box = GetStorage();
    // box.write(AppConstants.USER_PIN_KEY, null);
    _getCurrentPin();
  }

  _getCurrentPin() {
    GetStorage box = GetStorage();
    currentStoredPin.value = box.read(AppConstants.USER_PIN_KEY) ?? "";
  }

  reset() {
    showVerifyInput.value = false;
    verifyPin.value = "";
    newPin.value = "";
    showNewPin.value = false;
    currentPinEnteredByUser.value = "";
  }

  setPinInStorage(String pin) {
    GetStorage box = GetStorage();
    box.write(AppConstants.USER_PIN_KEY, pin);
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

    setPinInStorage(newPin.value);
    currentStoredPin.value = newPin.value;
    reset();
    Get.back();

    return true;
  }

  Future<bool> changePin() async {
    if (currentPinEnteredByUser.value != currentStoredPin.value) {
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

    setPinInStorage(newPin.value);
    currentStoredPin.value = newPin.value;
    reset();
    Get.back();

    return true;
  }

  confirmPin(String value) {
    if (currentStoredPin.value != value) {
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
        setPinInStorage(null);
        currentStoredPin.value = "";
        Get.back();
        Get.snackbar(
          "Success",
          "PIN removed successfully.",
          backgroundColor: AppColors.GREEN,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.offAll(Home());
      }
      fromSettings.value = false;
    }
  }
}
