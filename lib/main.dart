import 'dart:async' show unawaited;

import 'package:balance_sheet/controllers/app_controller.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/controllers/budget_controller.dart';
import 'package:balance_sheet/controllers/investment_controller.dart';
import 'package:balance_sheet/controllers/contact_controller.dart';
import 'package:balance_sheet/controllers/insights_controller.dart';
import 'package:balance_sheet/controllers/security_controller.dart';
import 'package:balance_sheet/controllers/summary_amounts_privacy_controller.dart';
import 'package:balance_sheet/controllers/tag_controller.dart';
import 'package:balance_sheet/controllers/transaction_controller.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:balance_sheet/screens/splash.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:workmanager/workmanager.dart';
import 'package:balance_sheet/backup/auto_backup_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case AutoBackupService.taskName:
        return await AutoBackupService.performBackup();
      default:
        return true;
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  await Workmanager().initialize(
    callbackDispatcher,
  );

  Get.put(CurrencyController());
  Get.put(TransactionController());
  Get.put(TagController());
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
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const MethodChannel _privacyChannel =
      MethodChannel('balanced/privacy');

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
        return AppPalette.forScheme(app.themeScheme.value, Brightness.dark);
      case ThemeMode.light:
        return AppPalette.forScheme(app.themeScheme.value, Brightness.light);
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark
            ? AppPalette.forScheme(app.themeScheme.value, Brightness.dark)
            : AppPalette.forScheme(app.themeScheme.value, Brightness.light);
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
        _showPrivacyOverlay();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _onLeavingForeground();
        break;
      case AppLifecycleState.resumed:
        unawaited(_setNativeAppSwitcherPrivacy(false));
        if (mounted) {
          setState(() => _privacyOverlayVisible = false);
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _setNativeAppSwitcherPrivacy(bool enabled) async {
    try {
      await _privacyChannel.invokeMethod<void>(
        'setAppSwitcherPrivacy',
        enabled,
      );
    } on MissingPluginException {
      // Android handles Recents snapshots natively; other platforms keep using the Flutter overlay.
    } on PlatformException {
      // Privacy overlay remains as a fallback if the native flag cannot be changed.
    }
  }

  bool _showPrivacyOverlay() {
    final SecurityController security = Get.find<SecurityController>();
    if (!security.pinIsSet.value) return false;

    unawaited(_setNativeAppSwitcherPrivacy(true));

    if (mounted) {
      setState(() => _privacyOverlayVisible = true);
    }

    return true;
  }

  void _onLeavingForeground() {
    if (!_showPrivacyOverlay()) return;

    final SecurityController security = Get.find<SecurityController>();
    if (!security.sessionUnlocked.value) return;
    // Backup import/export (and other system pickers) briefly background the Flutter activity.
    // Locking here would unmount the originating widget and silently abort the in-flight flow.
    if (security.isSubFlowActive) return;

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
            theme: buildLightAppTheme(app.fontId.value, app.themeScheme.value),
            darkTheme:
                buildDarkAppTheme(app.fontId.value, app.themeScheme.value),
            themeMode: app.themeMode.value,
            home: Splash(),
            getPages: [
              GetPage(name: '/lock', page: () => LockScreen()),
            ],
            debugShowCheckedModeBanner: false,
            builder: (BuildContext context, Widget? child) {
              final Widget screen = child ?? const SizedBox.shrink();
              if (!kDebugMode) {
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: AppPalette.of(context).systemUiOverlayStyle,
                  child: screen,
                );
              }

              final AppPalette palette = AppPalette.of(context);
              final bool isDark = palette.brightness == Brightness.dark;

              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: palette.systemUiOverlayStyle,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? palette.mint.withValues(alpha: 0.15)
                            : Color.lerp(palette.mint, Colors.white, 0.50),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? palette.mint.withValues(alpha: 0.4)
                                : palette.mint.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'TEST APP (DEBUG)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: palette.mint,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: screen,
                    ),
                  ],
                ),
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
