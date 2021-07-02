import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/screens/details.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

Widget roundedIcon({IconData icon, Color iconColor, double iconSize, Color containerColor, EdgeInsets padding}) {
  return Container(
    padding: padding,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: containerColor,
    ),
    child: Icon(
      icon,
      color: iconColor,
      size: iconSize ?? 20.0,
    ),
  );
}

Widget totalDayTransaction(String date, int income, int expense) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.LIGHT_1_GREY),
      borderRadius: BorderRadius.circular(7.0)
    ),
    margin: EdgeInsets.symmetric(vertical: 15.0),
    padding: EdgeInsets.all(10.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                'Date',
                style: TextStyle(
                  color: AppColors.LIGHT_5_GREY,
                ),
              ),
            ),
            Text(
              date,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                'Cash out',
                style: TextStyle(
                  color: AppColors.LIGHT_5_GREY,
                ),
              ),
            ),
            Text(
              '${formatAmount(expense)}',
              style: TextStyle(
                color: AppColors.RED,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                'Cash in',
                style: TextStyle(
                  color: AppColors.LIGHT_5_GREY,
                ),
              ),
            ),
            Text(
              '${formatAmount(income)}',
              style: TextStyle(
                color: AppColors.GREEN,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget roundedButton({String text, Color textColor, Color color, Function action}) {
  return GestureDetector(
    onTap: action,
    child: Container(
      width: Get.width,
      padding: EdgeInsets.all(15.0),
      margin: EdgeInsets.only(top: 25.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

Widget singleTransactionContainer(Transaction transaction) {
  return GestureDetector(
    onTap: () => Get.to(
      TransactionDetails(transaction: transaction),
      preventDuplicates: false,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Container(
            margin: EdgeInsets.only(top: 10.0),
            padding: EdgeInsets.all(15.0),
            height: 70.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7.0),
                bottomLeft: Radius.circular(7.0)
              ),
              border: Border.all(color: AppColors.LIGHT_2_GREY)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                SizedBox(height: 2.0),
                Text(
                  "${DateFormat.yMMMMd().add_Hm().format(transaction.date)}",
                  style: TextStyle(
                    color: AppColors.TEXT_GREY,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            height: 70.0,
            margin: EdgeInsets.only(top: 10.0),
            padding: EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: transaction.type == TransactionType.income ? AppColors.LIGHT_GREEN : AppColors.LIGHT_RED,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(7.0),
                bottomRight: Radius.circular(7.0)
              ),
            ),
            child: Center(
              child: Text(
                '${formatAmount(transaction.amount)}',
                style: TextStyle(
                  color: transaction.type == TransactionType.income ? AppColors.GREEN : AppColors.RED,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final Icon icon;
  final Text primaryText;
  final Text secondaryText;

  EmptyState({this.icon, this.primaryText, this.secondaryText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Column(
          children: [
            roundedIcon(
              icon: icon.icon,
              iconColor: icon.color,
              iconSize: 48.0,
              containerColor: AppColors.LIGHT_1_GREY,
              padding: EdgeInsets.all(25.0)
            ),
            SizedBox(height: 15.0),
            primaryText,
            SizedBox(height: 15.0),
            secondaryText,
          ],
        ),
      ),
    );
  }
}

