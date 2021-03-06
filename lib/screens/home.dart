import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/screens/contact_screen.dart';
import 'package:balance_sheet/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Home extends StatelessWidget {
  final AppController _appController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() => WillPopScope(
      onWillPop: () async {
        if (_appController.index.value == 1) {
          _appController.setIndex(0);
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        body: _appController.index.value == 0
          ? MainView()
          : ContactView(),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color(0xffE6E2F4),
          selectedItemColor: AppColors.PRIMARY,
          unselectedItemColor: AppColors.LIGHT_PRIMARY,
          type: BottomNavigationBarType.fixed,
          currentIndex: _appController.index.value,
          onTap: _appController.setIndex,
          items: [
            _buildBottomNavigationBarItem(icon: Icons.money_outlined, label: "Transactions"),
            _buildBottomNavigationBarItem(icon: Icons.people_outline, label: "Contacts"),
          ],
        ),
      ),
    ));
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({IconData icon, String label}) {
    return BottomNavigationBarItem(
      activeIcon: Icon(
        icon,
        size: 36.0,
      ),
      icon: Icon(
        icon,
        size: 36.0,
      ),
      label: label,
      tooltip: label
    );
  }
}
