import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactDialog extends StatelessWidget {
  final ContactController _contactController = Get.find();
  final AppController _appController = Get.find();

  final dynamic controller;

  ContactDialog({@required this.controller});

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
        child: _contactController.contacts.length != 0 ? ListView.builder(
          shrinkWrap: true,
          itemCount: _contactController.contacts.length,
          itemBuilder: (context, index) {
            return _buildDialogItem(
              _contactController.contacts[index].name,
              index,
              this.controller.contact.value.id == _contactController.contacts[index].id
            );
          },
        ) : Column(
          children: [
            EmptyState(
              icon: Icon(
                Icons.person_outline,
                color: Color(0xFFAF47FF),
                size: 48.0,
              ),
              primaryText: Text(
                'No contact has been added',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              secondaryText: Text(
                'Click the button below to add a contact',
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.back();
                Get.to(Home());
                _appController.setIndex(1);
              },
              child: Text('Add contact'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDialogItem(String text, int index, bool highlight) {
    return GestureDetector(
      onTap: () {
        this.controller.contact.value = _contactController.contacts[index];
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
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
