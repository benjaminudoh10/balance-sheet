import 'package:balance_sheet/screens/home.dart';
import 'package:get/get.dart';

class AppController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _setInitialScreen();
  }

  _setInitialScreen() {
    Future.delayed(const Duration(milliseconds: 3000), () => Get.offAll(Home()));
  }
}
