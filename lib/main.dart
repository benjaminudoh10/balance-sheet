import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/controllers/budgetController.dart';
import 'package:balance_sheet/controllers/investment_controller.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/controllers/insights_controller.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/controllers/summary_amounts_privacy_controller.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:balance_sheet/screens/splash.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(CurrencyController());
  Get.put(TransactionController());
  Get.put(SecurityController());
  Get.put(AppController());
  Get.put(SummaryAmountsPrivacyController());
  Get.put(ContactController());
  Get.put(BudgetController());
  Get.put(InvestmentController());
  Get.put(InsightsController());
  Get.config(
    // enableLog: true,
    // defaultPopGesture: true,
    defaultTransition: Transition.downToUp,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _privacyOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  AppPalette _privacyPalette(AppController app) {
    switch (app.themeMode.value) {
      case ThemeMode.dark:
        return AppPalette.dark;
      case ThemeMode.light:
        return AppPalette.light;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark
            ? AppPalette.dark
            : AppPalette.light;
    }
  }

  /// Shown over the UI in the app switcher when a PIN is set — no sensitive data, only branding.
  Widget _privacyBrandedOverlay(AppController app) {
    final AppPalette p = _privacyPalette(app);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: p.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 56, color: p.mint),
              const SizedBox(height: 16),
              Text(
                'Balanced',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _onLeavingForeground();
        break;
      case AppLifecycleState.resumed:
        if (mounted) {
          setState(() => _privacyOverlayVisible = false);
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onLeavingForeground() {
    final SecurityController security = Get.find<SecurityController>();
    if (!security.pinIsSet.value) return;

    if (mounted) {
      setState(() => _privacyOverlayVisible = true);
    }

    if (!security.sessionUnlocked.value) return;

    security.onRequireScreenLock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<SecurityController>()) return;
      if (Get.key.currentContext == null) return;
      Get.offAll(LockScreen(), transition: Transition.noTransition);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppController app = Get.find();
    return Obx(
      () => Stack(
        // Above [GetMaterialApp]: no [Directionality] until [MaterialApp] builds below.
        alignment: Alignment.topLeft,
        fit: StackFit.expand,
        children: [
          GetMaterialApp(
            navigatorKey: Get.key,
            title: 'Balanced',
            theme: buildLightAppTheme(app.fontId.value),
            darkTheme: buildDarkAppTheme(app.fontId.value),
            themeMode: app.themeMode.value,
            home: Splash(),
            debugShowCheckedModeBanner: false,
            builder: (BuildContext context, Widget? child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppPalette.of(context).systemUiOverlayStyle,
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
          if (_privacyOverlayVisible)
            Positioned.fill(
              child: _privacyBrandedOverlay(app),
            ),
        ],
      ),
    );
  }
}
