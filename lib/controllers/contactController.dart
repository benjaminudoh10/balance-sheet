import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactController extends GetxController {
  RxBool addingContact = false.obs;
  RxString name = "".obs;

  var nameController = TextEditingController().obs;
  var contacts = [].obs;

  @override
  void onReady() {
    super.onReady();

    getContacts();
  }

  addContact(Contact contact) async {
    addingContact.value = true;
    int id;
    try {
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
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0x55FF0000),
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
      snackPosition: SnackPosition.TOP,
      backgroundColor: Color(0xdd5DAC7F),
    );
  }

  readd(Contact contact) {
    contacts.removeWhere((_contact) => contact.id == _contact.id);
    Future.delayed(const Duration(milliseconds: 500), () {
      contacts.add(contact);
      contacts.sort((a, b) => a.name.compareTo(b.name));
    });
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
    //   backgroundColor: Color(0xdd5DAC7F),
    // );
  }

  deleteContact(Contact contact) async {
    await db.deleteContact(contact);
    // remove txn from UI
    contacts.value = contacts.where((_contact) => contact.id != _contact.id).toList();
    updateControllerDataAfterDeletion(contact);

    Get.snackbar(
      "Successful",
      "Contact deleted successfully",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Color(0xdd5DAC7F),
    );
  }

  getContacts() async {
    contacts.value = await db.getContacts();
  }

  updateControllerDataAfterDeletion(Contact contact) {
    
  }
}
