import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/screens/splash.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(SecurityController());
  Get.put(AppController());
  Get.put(TransactionController());
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
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        primarySwatch: Colors.purple,
      ),
      home: Splash(),
      debugShowCheckedModeBanner: false,
    );
  }
}
