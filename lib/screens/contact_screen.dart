import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactView extends StatelessWidget {
  final ContactController _contactController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      body: Container(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 70.0
        ),
        color: AppColors.PRIMARY,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.LIGHT_5_GREY,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 55.0,
                ),
                margin: EdgeInsets.only(bottom: 25.0),
                child: Text(
                  'Contacts',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _contactController.contacts.length != 0 ? ListView.builder(
                padding: EdgeInsets.only(top: 0),
                itemCount: _contactController.contacts.length,
                itemBuilder: (context, index) {
                  Contact contact = _contactController.contacts[index];

                  return Dismissible(
                    key: Key('${contact.id}'),
                    background: Container(
                      margin: EdgeInsets.only(
                        top: 5.0,
                        bottom: 5.0,
                      ),
                      padding: EdgeInsets.only(left: 15.0),
                      color: AppColors.SNACKBAR_RED,
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.delete,
                        size: 24.0,
                        color: Colors.white,
                      ),
                    ),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) {
                      _contactController.deleteContact(contact);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: AppColors.LIGHT_6_GREY,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.GREEN,
                              ),
                              width: 40.0,
                              height: 40.0,
                              margin: EdgeInsets.only(left: 10.0, right: 10.0),
                              child: Center(
                                child: Text(
                                  '${contact.name.substring(0, 1)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "${contact.name}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ) : Center(
                child: EmptyState(
                  icon: Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 48.0,
                  ),
                  primaryText: Text(
                    'No contact added',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  secondaryText: Text(
                    'Use the text field below to add a contact',
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: ContactInput()),
                GestureDetector(
                  onTap: () {
                    if (contactDataInvalid()) {
                      Get.snackbar(
                        "Error",
                        "Name is required",
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: AppColors.SNACKBAR_RED,
                      );
                      return;
                    }
                    Contact contact = Contact(name: _contactController.name.value);
                    _contactController.addContact(contact);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: contactDataInvalid() ? AppColors.LIGHT_5_GREY : AppColors.GREEN,
                      shape: BoxShape.circle,
                    ),
                    margin: EdgeInsets.only(left: 10.0),
                    width: 40.0,
                    height: 40.0,
                    child: Icon(
                      Icons.add,
                      size: 20.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  bool contactDataInvalid() {
    return _contactController.name.value == "" || _contactController.name.value == null;
  }
}
