import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:balance_sheet/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AppController extends GetxController {
  SecurityController _securityController = Get.find();
  RxInt index = 0.obs;

  /// Persisted key from [AppFontIds] — drives [buildMidnightAppTheme].
  final RxString fontId = AppFontIds.defaultId.obs;

  @override
  void onInit() {
    super.onInit();
    final GetStorage box = GetStorage();
    final String? stored = box.read<String>(AppConstants.APP_FONT_KEY);
    if (stored != null && AppFontIds.isValid(stored)) {
      fontId.value = stored;
    }
  }

  void setAppFont(String id) {
    if (!AppFontIds.isValid(id)) return;
    fontId.value = id;
    GetStorage().write(AppConstants.APP_FONT_KEY, id);
  }

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
