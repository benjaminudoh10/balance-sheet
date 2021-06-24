import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactDialog extends StatelessWidget {
  final ContactController _contactController = Get.find();
  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(10.0),
        height: 250.0,
        child: Column(
          children: [
            Text(
              "Attach contact to transaction",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _contactController.contacts.length,
              itemBuilder: (context, index) {
                return _buildDialogItem(
                  _contactController.contacts[index].name,
                  index,
                  _transactionController.contact.value?.id == _contactController.contacts[index].id
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogItem(String text, int index, bool highlight) {
    return GestureDetector(
      onTap: () {
        _transactionController.contact.value = _contactController.contacts[index];
        Get.back();
      },
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Container(
          width: Get.width,
          decoration: BoxDecoration(
            color: highlight ? Color(0x33AF47FF) : Color(0x44000000),
            borderRadius: BorderRadius.circular(15.0),
          ),
          padding: EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 20.0,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
