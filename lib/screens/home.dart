import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(child: Text('Home'),),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Color(0xffC77DFF),
        unselectedItemColor: Color(0xffECCAFF),
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
