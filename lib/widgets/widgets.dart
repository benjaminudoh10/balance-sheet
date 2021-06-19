import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/screens/details.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      border: Border.all(color: Color(0x11000000)),
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
                  color: Color(0x55000000)
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
                  color: Color(0x55000000)
                ),
              ),
            ),
            Text(
              '${formatAmount(expense)}',
              style: TextStyle(
                color: Color(0xaaff0000)
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
                  color: Color(0x55000000)
                ),
              ),
            ),
            Text(
              '${formatAmount(income)}',
              style: TextStyle(
                color: Color(0xdd5DAC7F)
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
              border: Border.all(color: Color(0x22000000))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5.0),
                Text(
                  "${transaction.date}",
                  style: TextStyle(
                    color: Color(0xaa000000),
                    fontSize: 10.0,
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
              color: transaction.type == TransactionType.income ? Color(0x335DAC7F) : Color(0x11ff0000),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(7.0),
                bottomRight: Radius.circular(7.0)
              ),
            ),
            child: Center(
              child: Text(
                '${formatAmount(transaction.amount)}',
                style: TextStyle(
                  color: transaction.type == TransactionType.income ? Color(0xff5DAC7F) : Color(0xffff0000),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget noTransaction(String primaryText, String secondaryText) {
  return Center(
    child: Container(
      child: Column(
        children: [
          roundedIcon(
            icon: Icons.money,
            iconColor: Color(0xbbAF47FF),
            iconSize: 48.0,
            containerColor: Color(0x11000000),
            padding: EdgeInsets.all(25.0)
          ),
          SizedBox(height: 15.0),
          Text(primaryText),
          SizedBox(height: 15.0),
          Text(secondaryText),
        ],
      ),
    ),
  );
}
