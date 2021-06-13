import 'package:flutter/material.dart';

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

Widget totalDayTransaction() {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Color(0x11000000)),
      borderRadius: BorderRadius.circular(7.0)
    ),
    margin: EdgeInsets.symmetric(
      vertical: 15.0,
    ),
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
              '12 Jun (21)',
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
              '₦0.00',
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
              '₦0.00',
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

Widget singleTransactionContainer(Map<String, String> details) {
  return Row(
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
                "${details['title']}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5.0),
              Text(
                "${details['time']}",
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
            color: details['type'] == 'income' ? Color(0x335DAC7F) : Color(0x11ff0000),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(7.0),
              bottomRight: Radius.circular(7.0)
            ),
          ),
          child: Center(
            child: Text(
              '₦${details['amount']}',
              style: TextStyle(
                color: details['type'] == 'income' ? Color(0xff5DAC7F) : Color(0xffff0000),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
