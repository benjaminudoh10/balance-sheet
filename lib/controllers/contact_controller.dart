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
  Rxn<Contact> contact = Rxn<Contact>();

  @override
  void onReady() {
    super.onReady();

    getContacts();
  }

  addContact(Contact contact) async {
    addingContact.value = true;
    int id;
    try {
      List<Map<String, dynamic>> exists =
          await db.getContactWithName(contact.name);
      if (exists.isNotEmpty) {
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
      debugPrint('$error');
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

  Future<void> updateContact(Contact updated) async {
    final String trimmed = updated.name.trim();
    if (trimmed.isEmpty) {
      Get.snackbar(
        "Error",
        "Name is required",
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
      );
      return;
    }
    if (updated.id <= 0) {
      return;
    }
    try {
      final List<Map<String, dynamic>> existing =
          await db.getContactWithName(trimmed);
      final bool duplicate = existing.any((Map<String, dynamic> row) {
        final dynamic rawId = row['id'];
        final int id = rawId is int
            ? rawId
            : rawId is num
                ? rawId.toInt()
                : int.tryParse('$rawId') ?? 0;
        return id != updated.id;
      });
      if (duplicate) {
        Get.snackbar(
          "Error",
          "Contact with given name already exist.",
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.SNACKBAR_RED,
        );
        return;
      }

      await db.updateContact(Contact(id: updated.id, name: trimmed));

      final int idx = contacts.indexWhere((Contact c) => c.id == updated.id);
      if (idx >= 0) {
        contacts[idx] = Contact(id: updated.id, name: trimmed);
        contacts.sort((a, b) => a.name.compareTo(b.name));
      }

      Get.back();
      Get.snackbar(
        "Successful",
        "Contact updated successfully",
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.GREEN,
      );
    } catch (error) {
      debugPrint('$error');
      Get.snackbar(
        "Error",
        "Error occured while updating contact",
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
      );
    }
  }

  Future<bool> hasLinkedItems(int contactId) async {
    final int txCount = await db.countTransactionsForContact(contactId);
    final int budgetCount = await db.countBudgetLinesForContact(contactId);
    return txCount > 0 || budgetCount > 0;
  }

  deleteContact(Contact contact) async {
    await db.deleteContact(contact);
    contacts.value = contacts
        .where((existingContact) => contact.id != existingContact.id)
        .toList();

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

  /// Clears the add-contact draft (used after backup import / debug data clear).
  void resetNewContactDraft() {
    name.value = '';
    nameController.value.text = '';
  }
}
