import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/models/organization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrganizationController extends GetxController {
  RxList<Organization> organizations = <Organization>[].obs;
  Rx<Organization> organization = Rxn<Organization>();
  RxBool addingOrganization = false.obs;
  Rx<String> name = Rxn<String>();

  TransactionController _transactionController = Get.find();

  @override
  void onReady() {
    super.onReady();

    getOrganizations();

    organization.listen((value) {
      loadTransactionsForOrganization();

      _transactionController.getTotalBalance();
      _transactionController.getTodaysBalance();
    });
  }

  loadTransactionsForOrganization() {
    DateTime currentDate = DateTime.now();
    DateTime startOfToday = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    DateTime endOfToday = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      23,
      59,
      59,
      999,
    );

    _transactionController.getTransactions(
      startOfToday.millisecondsSinceEpoch,
      endOfToday.millisecondsSinceEpoch,
    );
  }

  getOrganizations() async {
    organizations.value = await db.getOrganizations();
    organization.value = organizations.firstWhere((organization) => organization.id == 1);
  }

  getOrganization(int id) async {
    organization.value = await db.getOrganization(id);
  }

  deleteOrganization(Organization organization) async {
    // check if transactions exist for org and show a modal for org reassignment
    await db.deleteOrganization(organization);
  }

  addOrganization(Organization organization) async {
    addingOrganization.value = true;
    int id;
    try {
      id = await db.addOrganization(organization);
      addingOrganization.value = false;
    } catch (error) {
      print(error);
      addingOrganization.value = false;
      Get.snackbar(
        "Error",
        "Error occured while adding organization",
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
      );
      return;
    }
    organization.id = id;
    Get.back();

    // update data in controller
    organizations.add(organization);
    // updateControllerData(transaction);
    Get.snackbar(
      "Successful",
      "Organization added successfully",
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.GREEN,
    );
  }

  updateOrganization(Organization organization, Organization previousOrganization) async {
    Organization update = Organization.fromJson({
      "id": previousOrganization.id,
      "name": organization.name,
    });

    await db.updateOrganization(update);
    updateControllerDataAfterUpdate(update, previousOrganization);
    Get.back();
    Get.back();
    Get.snackbar(
      "Successful",
      "Organization updated successfully",
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.GREEN,
    );
  }

  updateControllerDataAfterUpdate(Organization update, Organization previousOrganization) {
    if (organization.value.id == update.id) {
      organization.value = update;
    }

    int orgIndex = organizations.indexWhere((organization) => organization.id == update.id);
    if (orgIndex != -1) {
      organizations.replaceRange(orgIndex, orgIndex + 1, [update]);
    }
  }
}
