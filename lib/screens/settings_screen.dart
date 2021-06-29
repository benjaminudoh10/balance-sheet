import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class Settings extends StatelessWidget {
  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: true,
      ),
      body: Container(
        color: Color(0x11000000),
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            roundedIcon(
              icon: Icons.person,
              iconSize: 34.0,
              iconColor: Colors.white,
              containerColor: Color(0x22AF47FF),
              padding: EdgeInsets.all(20.0),
            ),
            _buildSettingRow(
              'Export to CSV',
              Icons.assignment_outlined,
              Colors.purple,
              () => exportToCSV(),
            ),
            _buildSettingRow(
              'Import from CSV',
              Icons.assignment_returned_outlined,
              Colors.green,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  void exportToCSV() async {
    showCustomModalBottomSheet(
      context: Get.context,
      // isDismissible: false,
      builder: (context) => Container(
        height: Get.height * 0.2,
        color: Colors.white,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      containerWidget: (_, animation, child) => Padding(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 0.0,
          bottom: 40.0, // (Get.height * 0.8) / 2,
        ),
        child: Material(
          color: Colors.grey,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(20.0),
          child: child,
        ),
      )
    );
    await _transactionController.exportTransactions();
    print('no whoops!!!!!!');
    Get.to(Settings());
  }

  Widget _buildSettingRow(String title, IconData icon, Color iconColor, Function action) {
    return GestureDetector(
      onTap: action,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40.0),
          boxShadow: [
            BoxShadow(
              color: Color(0x22AF47FF),
              blurRadius: 5.0,
            )
          ]
        ),
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.only(top: 15.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
            ),
            SizedBox(width: 10.0),
            Expanded(
              child: Text(
                title,
              ),
            ),
            roundedIcon(
              icon: Icons.chevron_right_outlined,
              containerColor: Color(0x22AF47FF),
              padding: EdgeInsets.all(5.0),
            ),
          ],
        ),
      ),
    );
  }
}
