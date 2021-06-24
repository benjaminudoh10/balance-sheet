import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportTypeDialog extends StatelessWidget {
  final ReportController _reportController = Get.find();

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
            _buildDialogItem(
              "Today",
              () => _reportController.changeType(ReportType.today),
              _reportController.type.value == ReportType.today,
            ),
            _buildDialogItem(
              "This month",
              () => _reportController.changeType(ReportType.month),
              _reportController.type.value == ReportType.month,
            ),
            _buildDialogItem(
              "This week",
              () => _reportController.changeType(ReportType.thisWeek),
              _reportController.type.value == ReportType.thisWeek,
            ),
            _buildDialogItem(
              "Last month",
              () => _reportController.changeType(ReportType.lastMonth),
              _reportController.type.value == ReportType.lastMonth,
            ),
            _buildDialogItem(
              "Single day",
              () => _reportController.changeType(ReportType.singleDay),
              _reportController.type.value == ReportType.singleDay,
            ),
            _buildDialogItem(
              "Date range...",
              () => _reportController.changeType(ReportType.dateRange),
              _reportController.type.value == ReportType.dateRange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogItem(String text, Function action, bool highlight) {
    return GestureDetector(
      onTap: action,
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
