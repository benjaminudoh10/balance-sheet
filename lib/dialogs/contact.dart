import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactDialog extends StatelessWidget {
  final ContactController _contactController = Get.find();
  final AppController _appController = Get.find();

  final dynamic controller;

  ContactDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: p.surfaceElevated,
          border: Border.all(color: p.border),
        ),
        padding: EdgeInsets.all(10.0),
        height: 250.0,
        child: _contactController.contacts.length != 0 ? ListView.builder(
          shrinkWrap: true,
          itemCount: _contactController.contacts.length,
          itemBuilder: (context, index) {
            return _buildDialogItem(
              context,
              _contactController.contacts[index].name,
              index,
              this.controller.contact.value?.id == _contactController.contacts[index].id
            );
          },
        ) : Column(
          children: [
            EmptyState(
              icon: Icon(
                Icons.person_outline,
                color: p.mint.withValues(alpha: 0.7),
                size: 48.0,
              ),
              primaryText: Text(
                'No contact has been added',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
              secondaryText: Text(
                'Click the button below to add a contact',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: p.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.back();
                Get.to(Home());
                _appController.setIndex(1);
              },
              child: Text(
                'Add contact',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: p.mint,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDialogItem(BuildContext context, String text, int index, bool highlight) {
    final AppPalette p = AppPalette.of(context);
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
            color: highlight ? p.mint.withValues(alpha: 0.2) : p.surface,
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(color: p.border),
          ),
          padding: EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 20.0,
          ),
          child: Center(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: p.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
