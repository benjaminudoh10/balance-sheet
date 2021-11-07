import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:get/get.dart';

class AppController extends GetxController {
  SecurityController _securityController = Get.find();
  RxInt index = 0.obs;

  @override
  void onReady() {
    super.onReady();
    _setInitialScreen();
  }

  _setInitialScreen() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      print('[PIN VALUE] ${_securityController.currentStoredPin.value}');
      if (_securityController.currentStoredPin.value != "") {
        Get.offAll(LockScreen());
      } else {
        Get.offAll(Home());
      }
    });
  }

  setIndex(int i) {
    index.value = i;
  }
}
