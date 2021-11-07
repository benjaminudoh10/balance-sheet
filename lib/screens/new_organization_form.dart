import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/organizationController.dart';
import 'package:balance_sheet/models/organization.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

class OrganizationForm extends StatelessWidget {
  OrganizationForm({this.organization});

  final Organization organization;
  final OrganizationController _organizationController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: EdgeInsets.all(20.0),
      decoration: new BoxDecoration(
        color: AppColors.PRIMARY,
        borderRadius: new BorderRadius.only(
          topLeft: const Radius.circular(25.0),
          topRight: const Radius.circular(25.0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 30.0,
            ),
            margin: EdgeInsets.only(bottom: 7.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: AppColors.LIGHT_3_GREY,
            ),
            child: Text(
              "${this.organization != null ? 'Update' : 'Add'} organization",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Organization name",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              OrganizationInput(),
              GestureDetector(
                onTap: () async {
                  if (!validInput()) {
                    Get.snackbar(
                      "Error",
                      "Organization name is required",
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppColors.SNACKBAR_RED,
                    );
                    return;
                  }

                  Organization organization = Organization(
                    name: _organizationController.name.value,
                  );
                  if (this.organization != null) {
                    await _organizationController.updateOrganization(
                      organization,
                      this.organization,
                    );
                  } else {
                    await _organizationController.addOrganization(organization);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: validInput() ? AppColors.GREEN : Color(0xAAAF47FF),
                    boxShadow: [BoxShadow()]
                  ),
                  margin: EdgeInsets.symmetric(vertical: 10.0),
                  padding: EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0
                  ),
                  child: Center(
                    child: _organizationController.addingOrganization.value
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 20.0,
                        )
                      : Text(
                          "${this.organization != null ? 'Update' : 'Add'} organization",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                        ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SizedBox(),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  bool validInput() {
    return _organizationController.name.value != null && _organizationController.name.value != "";
  }
}
