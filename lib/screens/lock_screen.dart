import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:balance_sheet/widgets/inputs.dart';

class LockScreen extends StatelessWidget {
  final SecurityController _securityController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Enter your PIN',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        automaticallyImplyLeading: true,
      ),
      body: Container(
        color: AppColors.LIGHT_1_GREY,
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 200.0,
              color: AppColors.PRIMARY,
            ),
            SizedBox(height: 35.0),
            Flexible(
              child: PinInput(
                onCompleted: (value) => _securityController.confirmPin(value),
                onChanged: (value) {},
                controller: TextEditingController(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
