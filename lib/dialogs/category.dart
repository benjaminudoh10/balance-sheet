import 'package:balance_sheet/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryDialog extends StatelessWidget {
  final List<Map<String, Object>> categories = Constants.CATEGORIES;

  final dynamic controller;

  CategoryDialog({@required this.controller});

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
        child: ListView.builder(
          itemCount: this.categories.length,
          itemBuilder: (context, index) {
            return _buildDialogItem(
              this.categories[index]["key"],
              index,
              this.controller.category.value == this.categories[index]["key"]
            );
          },
        ),
      ),
    );
  }

  Widget _buildDialogItem(String text, int index, bool highlight) {
    return GestureDetector(
      onTap: () {
        this.controller.category.value = this.categories[index]["key"];
        Get.back();
      },
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: highlight ? Color(0x33AF47FF) : null,
              borderRadius: BorderRadius.circular(15.0),
            ),
            padding: EdgeInsets.symmetric(
              vertical: 5.0,
              horizontal: 20.0,
            ),
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
