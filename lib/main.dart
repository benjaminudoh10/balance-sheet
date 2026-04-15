import 'package:balance_sheet/constants/midnight_theme.dart';
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
    final ThemeData darkBase = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
    );
    return GetMaterialApp(
      title: 'Balanced',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: MidnightTheme.background,
        colorScheme: ColorScheme.dark(
          surface: MidnightTheme.surface,
          primary: MidnightTheme.mint,
          secondary: MidnightTheme.coral,
          onPrimary: Colors.black87,
          onSecondary: Colors.white,
          onSurface: MidnightTheme.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: MidnightTheme.background,
          foregroundColor: MidnightTheme.textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: MidnightTheme.surfaceElevated,
        ),
        textTheme: GoogleFonts.robotoTextTheme(darkBase.textTheme).apply(
          bodyColor: MidnightTheme.textPrimary,
          displayColor: MidnightTheme.textPrimary,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: MidnightTheme.surfaceElevated,
          contentTextStyle: const TextStyle(color: MidnightTheme.textPrimary),
        ),
      ),
      home: Splash(),
      debugShowCheckedModeBanner: false,
    );
  }
}
