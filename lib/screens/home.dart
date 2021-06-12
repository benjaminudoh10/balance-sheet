import 'package:balance_sheet/screens/main_screen.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainView(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xffE6E2F4),
        selectedItemColor: Color(0xFFC77DFF),
        unselectedItemColor: Color(0xFFECCAFF),
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {},
        items: [
          _buildBottomNavigationBarItem(icon: Icons.money_outlined, label: "Base"),
          _buildBottomNavigationBarItem(icon: Icons.people_outline, label: "People"),
        ],
      ),
    );
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
