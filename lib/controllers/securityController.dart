import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SecurityController extends GetxController {
  RxString currentStoredPin = "".obs;
  RxString currentPinEnteredByUser = "".obs;
  Rx<TextEditingController> enteredPinController = TextEditingController().obs;

  RxString newPin = "".obs;
  Rx<TextEditingController> newPinController = TextEditingController().obs;

  RxString verifyPin = "".obs;
  Rx<TextEditingController> verifiedPinController = TextEditingController().obs;

  Rx<TextEditingController> lockScreenController = TextEditingController().obs;

  RxBool showNewPin = false.obs;
  RxBool showVerifyInput = false.obs;

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
    enteredPinController.value.text = "";
    verifiedPinController.value.text = "";
    newPinController.value.text = "";
    lockScreenController.value.text = "";
  }

  Future<bool> setNewPin() async {
    if (newPin.value != verifyPin.value) {
      reset();
      Get.snackbar(
        "Error",
        "PINs do not match",
        backgroundColor: AppColors.RED,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    GetStorage box = GetStorage();
    box.write(AppConstants.USER_PIN_KEY, newPin.value);
    currentStoredPin.value = newPin.value;
    reset();
    Get.back();

    return true;
  }

  Future<bool> changePin() async {
    if (currentPinEnteredByUser.value != currentStoredPin.value) {
      reset();
      Get.snackbar(
        "Error",
        "Invalid PIN provided",
        backgroundColor: AppColors.RED,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    } else if (newPin.value != verifyPin.value) {
      reset();
      Get.snackbar(
        "Error",
        "PINs do not match",
        backgroundColor: AppColors.RED,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    GetStorage box = GetStorage();
    box.write(AppConstants.USER_PIN_KEY, newPin.value);
    currentStoredPin.value = newPin.value;
    reset();
    Get.back();

    return true;
  }

  confirmPin(String value) {
    if (currentStoredPin.value != value) {
      reset();
      Get.snackbar(
        "Error",
        "Invalid PIN provided. Try again.",
        backgroundColor: AppColors.RED,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.offAll(Home());
    }
  }
}
