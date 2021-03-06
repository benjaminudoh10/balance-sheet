import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactController extends GetxController {
  RxBool addingContact = false.obs;
  RxString name = "".obs;

  var nameController = TextEditingController().obs;
  RxList<Contact> contacts = <Contact>[].obs;
  Rx<Contact> contact = Rxn<Contact>();

  @override
  void onReady() {
    super.onReady();

    getContacts();
  }

  addContact(Contact contact) async {
    addingContact.value = true;
    int id;
    try {
      List<Map<String, dynamic>> exists = await db.getContactWithName(contact.name);
      if (exists.length > 0) {
        Get.snackbar(
          "Error",
          "Contact with given name already exist.",
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.SNACKBAR_RED,
        );
        return;
      }

      id = await db.addContact(contact);
      addingContact.value = false;
      name.value = "";
      nameController.value.text = "";
    } catch (error) {
      print(error);
      addingContact.value = false;
      Get.snackbar(
        "Error",
        "Error occured while adding contact",
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
      );
      return;
    }
    contact.id = id;

    // update data in controller
    contacts.add(contact);
    contacts.sort((a, b) => a.name.compareTo(b.name));
    Get.snackbar(
      "Successful",
      "Contact added successfully",
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.GREEN,
    );
  }

  updateContact(Contact contact, Contact previousContact) async {
    // Transaction update = Transaction.fromJson({
    //   "id": previousTransaction.id,
    //   "type": previousTransaction.type == TransactionType.expenditure ? 'expenditure' : 'income',
    //   "amount": transaction.amount,
    //   "category": transaction.category,
    //   "date": previousTransaction.date.millisecondsSinceEpoch,
    //   "description": transaction.description,
    // });

    // await db.updateTransaction(update);
    // updateControllerDataAfterUpdate(update, previousTransaction);
    // Get.back();
    // Get.back();
    // Get.snackbar(
    //   "Successful",
    //   "Transaction updated successfully",
    //   snackPosition: SnackPosition.TOP,
    //   backgroundColor: AppColors.GREEN,
    // );
  }

  deleteContact(Contact contact) async {
    await db.deleteContact(contact);
    // remove txn from UI
    contacts.value = contacts.where((_contact) => contact.id != _contact.id).toList();

    Get.snackbar(
      "Successful",
      "Contact deleted successfully",
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.GREEN,
    );
  }

  getContacts() async {
    contacts.value = await db.getContacts();
  }

  getContact(int id) async {
    if (id != null) contact.value = await db.getContact(id);
    else contact.value = null;
  }
}
