import 'package:balance_sheet/controllers/bottomNavController.dart';
import 'package:balance_sheet/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Home extends StatelessWidget {
  final BottomNavController _bottomNavController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      body: _bottomNavController.index.value == 0
        ? MainView()
        : Container(color: Colors.green,),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xffE6E2F4),
        selectedItemColor: Color(0xFFC77DFF),
        unselectedItemColor: Color(0xFFECCAFF),
        type: BottomNavigationBarType.fixed,
        currentIndex: _bottomNavController.index.value,
        onTap: _bottomNavController.setIndex,
        items: [
          _buildBottomNavigationBarItem(icon: Icons.money_outlined, label: "Base"),
          _buildBottomNavigationBarItem(icon: Icons.people_outline, label: "People"),
        ],
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
