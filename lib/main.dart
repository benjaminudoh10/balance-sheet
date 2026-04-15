import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/screens/splash.dart';
import 'package:balance_sheet/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(TransactionController());
  Get.put(SecurityController());
  Get.put(AppController());
  Get.put(ContactController());
  Get.config(
    // enableLog: true,
    // defaultPopGesture: true,
    defaultTransition: Transition.downToUp,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppController app = Get.find();
    return Obx(
      () => GetMaterialApp(
        title: 'Balanced',
        theme: buildLightAppTheme(app.fontId.value),
        darkTheme: buildDarkAppTheme(app.fontId.value),
        themeMode: app.themeMode.value,
        home: Splash(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
