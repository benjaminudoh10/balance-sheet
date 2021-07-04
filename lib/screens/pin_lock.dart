import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:balance_sheet/widgets/inputs.dart';

class Pin extends StatelessWidget {
  final SecurityController _securityController = Get.find();

  @override
  Widget build(BuildContext context) {
    bool setNewPin = _securityController.currentStoredPin.value == "";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Security PIN',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: true,
      ),
      body: setNewPin ? NewPinScreen() : ChangePinScreen(),
    );
  }
}

class NewPinScreen extends StatelessWidget {
  final SecurityController _securityController = Get.find();

  inputIsValid() {
    return _securityController.newPin.value != "" &&
      _securityController.newPin.value.length == 4 &&
      _securityController.verifyPin.value != "" &&
      _securityController.verifyPin.value.length == 4;
  }

  setNewPin() async {
    // snackbar refuse to display inside the controller, hence, I'm putting it here
    if (!inputIsValid()) {
      Get.snackbar(
        "Error",
        "All input is required",
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
      );
      return;
    }

    bool pinSet = await _securityController.setNewPin();
    if (pinSet) {
      Get.snackbar(
        "Success",
        "PIN has been set successfully",
        backgroundColor: AppColors.GREEN,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.LIGHT_1_GREY,
      padding: EdgeInsets.all(20.0),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter New PIN",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.0),
          PinInput(
            onCompleted: (value) => _securityController.showVerifyInput.value = true,
            onChanged: (value) => _securityController.newPin.value = value,
            controller: _securityController.newPinController.value,
          ),
          SizedBox(height: 30.0),
          _securityController.showVerifyInput.value ? Text(
            "Verify PIN",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            )
          ): SizedBox(),
          SizedBox(height: 10.0),
          _securityController.showVerifyInput.value ? PinInput(
            onCompleted: (value) {},
            onChanged: (value) => _securityController.verifyPin.value = value,
            controller: _securityController.verifiedPinController.value,
          ) : SizedBox(),
          SizedBox(height: 30.0),
          GestureDetector(
            onTap: setNewPin,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: inputIsValid() ? AppColors.PRIMARY : Colors.grey,
                boxShadow: [BoxShadow()]
              ),
              margin: EdgeInsets.symmetric(vertical: 10.0),
              padding: EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 20.0
              ),
              child: Center(
                child: Text(
                  "Set new PIN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}

class ChangePinScreen extends StatelessWidget {
  final SecurityController _securityController = Get.find();

  inputIsValid() {
    return _securityController.currentPinEnteredByUser.value != "" &&
      _securityController.currentPinEnteredByUser.value.length == 4 &&
      _securityController.newPin.value != "" &&
      _securityController.newPin.value.length == 4 &&
      _securityController.verifyPin.value != "" &&
      _securityController.verifyPin.value.length == 4;
  }

  changePin() async {
    // snackbar refuse to display inside the controller, hence, I'm putting it here
    if (!inputIsValid()) {
      Get.snackbar(
        "Error",
        "All input is required",
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
      );
      return;
    }

    bool pinSet = await _securityController.changePin();
    if (pinSet) {
      Get.snackbar(
        "Success",
        "PIN has been set successfully",
        backgroundColor: AppColors.GREEN,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.LIGHT_1_GREY,
      padding: EdgeInsets.all(20.0),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter Current PIN",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.0),
          PinInput(
            onCompleted: (value) => _securityController.showNewPin.value = true,
            onChanged: (value) => _securityController.currentPinEnteredByUser.value = value,
            controller: _securityController.enteredPinController.value,
          ),
          SizedBox(height: 30.0),
          _securityController.showNewPin.value ? Text(
            "Enter New PIN",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ) : SizedBox(),
          SizedBox(height: _securityController.showNewPin.value ? 10.0 : 0.0),
          _securityController.showNewPin.value ? PinInput(
            onCompleted: (value) => _securityController.showVerifyInput.value = true,
            onChanged: (value) => _securityController.newPin.value = value,
            controller: _securityController.newPinController.value,
          ) : SizedBox(),
          SizedBox(height: _securityController.showNewPin.value ? 30.0 : 0.0),
          _securityController.showVerifyInput.value ? Text(
            "Verify PIN",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            )
          ): SizedBox(),
          SizedBox(height: 10.0),
          _securityController.showVerifyInput.value ? PinInput(
            onCompleted: (value) {},
            onChanged: (value) => _securityController.verifyPin.value = value,
            controller: _securityController.verifiedPinController.value,
          ) : SizedBox(),
          SizedBox(height: 30.0),
          GestureDetector(
            onTap: changePin,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: inputIsValid() ? AppColors.PRIMARY : Colors.grey,
                boxShadow: [BoxShadow()]
              ),
              margin: EdgeInsets.symmetric(vertical: 10.0),
              padding: EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 20.0
              ),
              child: Center(
                child: Text(
                  "Set new PIN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
