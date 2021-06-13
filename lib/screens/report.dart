import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

const double APP_WIDTH = 20.0;

class ReportView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("Report"),
            SizedBox(width: 20.0),
            Icon(Icons.bar_chart)
          ],
        ),
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: APP_WIDTH,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFAF47FF),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            "SALES",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 15.0),
                          Text(
                            "₦81,000.00",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            "EXPENSES",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 15.0),
                          Text(
                            "₦24,000.00",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Get.dialog(
                      Dialog(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(10.0),
                          height: 180.0,
                          child: ListView(
                            physics: ScrollPhysics(),
                            children: [
                              _buildDialogItem("Today's entries", () => Get.back()),
                              _buildDialogItem("This month", () => Get.back()),
                              _buildDialogItem("Last week", () => Get.back()),
                              _buildDialogItem("Last month", () => Get.back()),
                              _buildDialogItem("Single day", () => Get.back()),
                              _buildDialogItem("Date range...", () => Get.back()),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      margin: EdgeInsets.symmetric(vertical: 20.0),
                      decoration: BoxDecoration(
                        color: Color(0x22ffffff),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      width: Get.width * 0.8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Today's entries",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 5.0),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 30.0,
                  horizontal: 20.0,
                ),
                decoration: BoxDecoration(
                  color: Color(0x22AF47FF),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Transactions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 15.0,
                      ),
                      margin: EdgeInsets.only(
                        bottom: 25.0,
                        top: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0x11000000),
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "DATE",
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                          Text(
                            "(₦) OUT",
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                          Text(
                            "(₦) IN",
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTransactionContainer({})
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogItem(String text, Function action) {
    return GestureDetector(
      onTap: action,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionContainer(Map<String, String> details) {
    return GestureDetector(
      onTap: _showTransactions,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7.0),
          border: Border.all(color: Color(0x11000000)),
        ),
        padding: EdgeInsets.all(12.0),
        margin: EdgeInsets.only(bottom: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "13 Jun",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
            Text(
              "₦0.00",
              style: TextStyle(
                // fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                fontSize: 12.0,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₦81,000.00",
                  style: TextStyle(
                    // fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 12.0,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  "View",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAF47FF),
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showTransactions() {
  BuildContext context = Get.context;
  showCupertinoModalBottomSheet(
    context: context,
    expand: true,
    builder: (context) => Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "13 June 2021",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: Get.back,
                      child: roundedIcon(
                        icon: Icons.close,
                        iconColor: Color(0xbbAF47FF),
                        iconSize: 24.0,
                        containerColor: Color(0x22AF47FF),
                        padding: EdgeInsets.all(3.0)
                      ),
                    ),
                  ],
                ),
                totalDayTransaction(),
                singleTransactionContainer({"title": "Newest", "time": "11:07 PM", "amount": "5000.00", "type": "income"}),
                singleTransactionContainer({"title": "Newest", "time": "11:07 PM", "amount": "5000.00", "type": "expenditure"}),
                singleTransactionContainer({"title": "Newest", "time": "11:07 PM", "amount": "5000.00", "type": "expenditure"}),
                singleTransactionContainer({"title": "Newest", "time": "11:07 PM", "amount": "5000.00", "type": "income"}),
                singleTransactionContainer({"title": "Newest", "time": "11:07 PM", "amount": "5000.00", "type": "income"}),
                singleTransactionContainer({"title": "Newest", "time": "11:07 PM", "amount": "5000.00", "type": "expenditure"}),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
