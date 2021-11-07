import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/organizationController.dart';
import 'package:balance_sheet/screens/new_organization_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Organizations extends StatelessWidget {
  final OrganizationController _organizationController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.0),
      height: Get.height * 0.5,
      decoration: new BoxDecoration(
        color: AppColors.PRIMARY,
        borderRadius: new BorderRadius.only(
          topLeft: const Radius.circular(25.0),
          topRight: const Radius.circular(25.0),
        ),
      ),
      child: Obx(() => Column(
        children: _organizationController.organizations.map((organization) => Container(
          padding: const EdgeInsets.all(5.0),
          margin: const EdgeInsets.only(bottom: 10.0),
          decoration: BoxDecoration(
            color: AppColors.PURPLE_GREY,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Row(
            children: [
              Radio(
                value: organization,
                groupValue: _organizationController.organization.value,
                onChanged: (value) {
                  _organizationController.organization.value = value;
                  Get.back();
                }
              ),
              Expanded(
                child: Text(
                  organization.name,
                  style: TextStyle(
                    color: AppColors.PRIMARY,
                    fontSize: 18.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 20.0,
                  color: AppColors.PRIMARY,
                ),
                onPressed: () async => await showModalBottomSheet<void>(
                  backgroundColor: Colors.transparent,
                  barrierColor: Color(0x22AF47FF),
                  isScrollControlled: true,
                  context: context,
                  builder: (context) => OrganizationForm(organization: organization),
                ).whenComplete(() => null),
              ),
              // IconButton(
              //   icon: Icon(
              //     Icons.delete,
              //     size: 20.0,
              //     color: AppColors.RED,
              //   ),
              //   onPressed: () async => await _organizationController.deleteOrganization(organization)
              // ),
            ],
          ),
        )).toList(),
      )),
    );
  }
}
