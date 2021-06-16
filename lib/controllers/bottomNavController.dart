import 'package:get/get.dart';

class BottomNavController extends GetxController {
  RxInt index = 0.obs;

  setIndex(int i) {
    index.value = i;
  }
}
