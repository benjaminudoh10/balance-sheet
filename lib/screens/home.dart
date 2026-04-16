import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/screens/contact_screen.dart';
import 'package:balance_sheet/screens/insights_screen.dart';
import 'package:balance_sheet/screens/main_screen.dart';
import 'package:balance_sheet/screens/placeholder_tab.dart';
import 'package:balance_sheet/screens/profile_screen.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/widgets/midnight_bottom_nav.dart';
import 'package:balance_sheet/widgets/plan_hub_fab.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AppController _appController = Get.find();
  bool _planHubOpen = false;
  Worker? _navHubWorker;

  @override
  void initState() {
    super.initState();
    _navHubWorker = ever<int>(_appController.index, (_) {
      if (!mounted) return;
      if (_planHubOpen) {
        setState(() => _planHubOpen = false);
      }
    });
  }

  @override
  void dispose() {
    _navHubWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => PopScope(
          canPop: _appController.index.value == 0,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop && _appController.index.value != 0) {
              _appController.setIndex(0);
            }
          },
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _bodyForIndex(_appController.index.value),
                if (_planHubOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _planHubOpen = false),
                      child: ColoredBox(color: AppPalette.of(context).overlay),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: const MidnightBottomNav(),
            floatingActionButton: PlanHubFab(
              expanded: _planHubOpen,
              onExpandedChanged: (bool v) => setState(() => _planHubOpen = v),
            ),
          ),
        ));
  }

  Widget _bodyForIndex(int index) {
    switch (index) {
      case 0:
        return MainView();
      case 1:
        return ContactView();
      case 2:
        return const PlaceholderTab(title: 'Activity');
      case 3:
        return const InsightsView();
      case 4:
        return ProfileView();
      default:
        return MainView();
    }
  }
}
