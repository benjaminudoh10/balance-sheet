import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/screens/contact_screen.dart';
import 'package:balance_sheet/screens/main_screen.dart';
import 'package:balance_sheet/screens/placeholder_tab.dart';
import 'package:balance_sheet/screens/profile_screen.dart';
import 'package:balance_sheet/widgets/midnight_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Home extends StatelessWidget {
  final AppController _appController = Get.find();

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
            body: _bodyForIndex(_appController.index.value),
            bottomNavigationBar: const MidnightBottomNav(),
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
        return const PlaceholderTab(title: 'Insights');
      case 4:
        return ProfileView();
      default:
        return MainView();
    }
  }
}
