import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:balance_sheet/screens/new_organization_form.dart';
import 'package:balance_sheet/screens/pin_lock.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Settings extends StatelessWidget {
  final SecurityController _securityController = Get.find();

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
        color: AppColors.LIGHT_1_GREY,
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            roundedWidget(
              widget: Icon(
                Icons.person,
                size: 34.0,
                color: Colors.white,
              ),
              containerColor: AppColors.SECONDARY,
              padding: EdgeInsets.all(20.0),
            ),
            Obx(() => SettingsItem(
              title: _securityController.currentStoredPin.value == "" ? 'Setup access PIN' : 'Change access PIN',
              icon: Icons.lock_outline,
              iconColor: Colors.red,
              action: goToPinView,
              containerAction: () => Get.to(Pin()),
              switchDisabled: false,
              switchValue: _securityController.currentStoredPin.value != "",
            )),
            Obx(() => SettingsItem(
              title: _securityController.fingerprintInUse.value ? "Disable fingerprint" : "Use fingerprint?",
              icon: Icons.lock_outline_rounded,
              iconColor: Colors.red,
              action: toggleFingerPrintLock,
              containerAction: null,
              switchDisabled: _securityController.currentStoredPin.value == "",
              switchValue: _securityController.fingerprintInUse.value,
            )),
            SettingsItem(
              title: 'Add organization',
              icon: Icons.business,
              containerAction: addOrganization,
              iconColor: AppColors.PRIMARY,
              hideSwitch: true,
            ),
          ],
        ),
      ),
    );
  }

  goToPinView(bool value) {
    _securityController.reset();
    if (value) Get.to(Pin());
    else {
      _securityController.fromSettings.value = true;
      Get.to(LockScreen());
    }
  }

  addOrganization() async {
    await showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x22AF47FF),
      isScrollControlled: true,
      context: Get.context,
      builder: (context) => OrganizationForm(),
    ).whenComplete(() => null);
  }

  toggleFingerPrintLock(bool value) {
    _securityController.activateFingerPrint(value);
  }

  // void exportToCSV() async {
  //   showCustomModalBottomSheet(
  //     context: Get.context,
  //     // isDismissible: false,
  //     builder: (context) => Container(
  //       height: Get.height * 0.2,
  //       color: Colors.white,
  //       child: Center(
  //         child: CircularProgressIndicator(),
  //       ),
  //     ),
  //     containerWidget: (_, animation, child) => Padding(
  //       padding: EdgeInsets.only(
  //         left: 20.0,
  //         right: 20.0,
  //         top: 0.0,
  //         bottom: 40.0, // (Get.height * 0.8) / 2,
  //       ),
  //       child: Material(
  //         color: Colors.grey,
  //         clipBehavior: Clip.antiAlias,
  //         borderRadius: BorderRadius.circular(20.0),
  //         child: child,
  //       ),
  //     )
  //   );
  //   await _transactionController.exportTransactions();
  //   print('no whoops!!!!!!');
  //   Get.to(Settings());
  // }
}

class SettingsItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Function(bool) action;
  final Function containerAction;
  final bool switchDisabled;
  final bool switchValue;
  final bool hideSwitch;

  SettingsItem({
    this.title,
    this.icon,
    this.iconColor,
    this.action,
    this.containerAction,
    this.switchDisabled = false,
    this.switchValue = false,
    this.hideSwitch = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: containerAction,
      child: Container(
        height: 50.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.SECONDARY,
              blurRadius: 5.0,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.0),
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
            if (!this.hideSwitch) Switch(
              value: this.switchValue,
              onChanged: this.switchDisabled ? null : action,
            ),
          ],
        ),
      ),
    );
  }
}
