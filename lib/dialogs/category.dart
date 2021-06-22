import 'package:balance_sheet/constants.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryDialog extends StatelessWidget {
  final TransactionController _transactionController = Get.find();
  final List<Map<String, Object>> categories = Constants.CATEGORIES;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Color(0xffAF47FF),
        ),
        padding: EdgeInsets.all(10.0),
        height: 450.0,
        child: ListView.builder(
          itemCount: this.categories.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(this.categories[index]["key"]),
              onTap: () {
                _transactionController.category.value = this.categories[index]["key"];
                Get.back();
              },
            );
          },
        ),
      ),
    );
  }
}
