import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactView extends StatelessWidget {
  final ContactController _contactController = Get.put(ContactController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      body: Container(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 70.0
        ),
        color: Color(0xFFC77DFF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contacts',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
                      padding: EdgeInsets.only(left: 15.0),
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.delete,
                        size: 24.0,
                        color: Colors.white,
                      ),
                    ),
                    secondaryBackground: Container(
                      padding: EdgeInsets.only(right: 15.0),
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.delete,
                        size: 24.0,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) {
                      _contactController.deleteContact(contact);
                    },
                    child: ListTile(
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                        width: 40.0,
                        height: 40.0,
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
                      title: Text(
                        "${contact.name}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                        ),
                      ),
                      contentPadding: EdgeInsets.all(5.0),
                    ),
                  );
                },
              ) : noTransaction(
                "No contact added",
                "Use the text field below to add a contact"
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
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Color(0x55FF0000),
                      );
                      return;
                    }
                    Contact contact = Contact(name: _contactController.name.value);
                    _contactController.addContact(contact);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: contactDataInvalid() ? Color(0x44000000) : Colors.green,
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
