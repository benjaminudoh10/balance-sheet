import 'package:balance_sheet/screens/enums.dart';
import 'package:balance_sheet/screens/new_income_form.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const double APP_WIDTH = 20.0;

class TransactionDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: 60.0,
                left: APP_WIDTH,
                right: APP_WIDTH,
                bottom: 20.0,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFAF47FF),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: Center(
                      child: Text(
                        "New stock",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: Get.back,
                      child: roundedIcon(
                        icon: Icons.close,
                        iconSize: 22.0,
                        iconColor: Colors.white,
                        containerColor: Color(0x22ffffff),
                        padding: EdgeInsets.all(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 20.0,
                ),
                decoration: BoxDecoration(
                  color: Color(0x22AF47FF),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Money in",
                          style: TextStyle(
                            fontSize: 12.0,
                          ),
                        ),
                        Text(
                          "Time",
                          style: TextStyle(
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₦81,000.00",
                          style: TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "1:21 PM",
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      "New stock",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    roundedButton(
                      text: "Edit",
                      color: Color(0xFFAF47FF),
                      action: () => showEditModal(TransactionType.income),
                    ),
                    roundedButton(
                      text: "Delete",
                      color: Color(0xaaff0000),
                      action: showDeleteModal,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showEditModal(TransactionType type) {
  BuildContext context = Get.context;
  showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    barrierColor: Color(0x22AF47FF),
    isScrollControlled: true,
    context: context,
    builder: (context) => IncomeForm(type: type),
  );
}

void showDeleteModal() {
  BuildContext context = Get.context;
  showModalBottomSheet(
    backgroundColor: Colors.transparent,
    barrierColor: Color(0x22AF47FF),
    context: context,
    builder: (context) => Container(
      height: 300.0,
      padding: EdgeInsets.all(45.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: Column(
        children: [
          Text(
            "Are you sure you want to delete this transaction?",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          roundedButton(
            text: "YES",
            color: Color(0xFFAF47FF),
            action: () {
              Get.back();
              Get.back();
              Get.snackbar(
                "Successful",
                "Transaction deleted successfully",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Color(0x22AF47FF),
              );
            }
          ),
          roundedButton(
            text: "NO",
            textColor: Color(0xFFAF47FF),
            color: Color(0x22AF47FF),
            action: () => Get.back(),
          ),
        ],
      ),
    ),
  );
}
