import 'package:balance_sheet/screens/home.dart';
import 'package:get/get.dart';

class AppController extends GetxController {
  RxInt index = 0.obs;

  @override
  void onReady() {
    super.onReady();
    _setInitialScreen();
  }

  _setInitialScreen() {
    Future.delayed(const Duration(milliseconds: 2000), () => Get.offAll(Home()));
  }

  setIndex(int i) {
    index.value = i;
  }
}
