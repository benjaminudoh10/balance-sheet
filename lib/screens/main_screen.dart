import 'package:flutter/material.dart';
import 'package:get/get.dart';

const double APP_WIDTH = 20.0;

class MainView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: 70.0,
              left: APP_WIDTH,
              right: APP_WIDTH,
              bottom: 5.0,
            ),
            decoration: BoxDecoration(
              color: Color(0xFFAF47FF),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance Sheet',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TotalContainer(),
                Container(
                  margin: EdgeInsets.symmetric(
                    vertical: 15.0
                  ),
                  padding: EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7.0)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SEE ALL YOUR TRANSACTIONS',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Color(0xFFAF47FF),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      _roundedIcon(
                        icon: Icons.chevron_right_rounded,
                        iconColor: Color(0xFFAF47FF),
                        containerColor: Color(0x22AF47FF),
                        padding: EdgeInsets.all(2.0)
                      ),
                    ],
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
                children: [
                  Container(
                    width: 45.0,
                    height: 3.0,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                    margin: EdgeInsets.only(
                      bottom: 15.0,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildButton("New Expense", Icons.remove, Color(0xaaff0000)),
                      _buildButton("New Sale", Icons.add, Color(0xdd5DAC7F)),
                    ],
                  ),
                  Container(
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
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        Container(
                          child: Column(
                            children: [
                              _roundedIcon(
                                icon: Icons.money,
                                iconColor: Color(0xbbAF47FF),
                                iconSize: 48.0,
                                containerColor: Color(0x11000000),
                                padding: EdgeInsets.all(25.0)
                              ),
                              SizedBox(height: 15.0),
                              Text(
                                'Add your first transaction today.'
                              ),
                              SizedBox(height: 15.0),
                              Text(
                                'Click "New Expense" or "New Sale" above.'
                              ),
                            ],
                          ),
                        ),
                        _buildTransactionContainer({"title": "Newest", "time": "11:07 PM", "amount": "5000.00", "type": "income"}),
                        _buildTransactionContainer({"title": "Newest", "time": "11:07 PM", "amount": "5000.00"}),
                        _buildTransactionContainer({"title": "Newest", "time": "11:07 PM", "amount": "5000.00"}),
                        _buildTransactionContainer({"title": "Newest", "time": "11:07 PM", "amount": "5000.00"}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionContainer(Map<String, String> details) {
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
}

Widget _roundedIcon({IconData icon, Color iconColor, double iconSize, Color containerColor, EdgeInsets padding}) {
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

Widget _buildButton(String text, IconData icon, Color color) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(7.0),
      color: color,
    ),
    padding: EdgeInsets.symmetric(
      vertical: 10.0,
      horizontal: 20.0,
    ),
    width: Get.width * .5 - APP_WIDTH - 5,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _roundedIcon(
          icon: icon,
          containerColor: Color(0x22ffffff),
          iconColor: Colors.white,
        ),
        SizedBox(width: 15.0),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class TotalContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10.0),
      width: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceSection('Total Balance', 0.00, Colors.white, true),
          _buildBalanceSection("Today's Balance", 0.00, Color(0xffdedeff), false),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(String text, double amount, Color color, bool leftPosition) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(
          top: 10.0,
          left: 15.0,
          bottom: 30.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: leftPosition ? Radius.circular(7.0) : Radius.zero,
            bottomLeft: leftPosition ? Radius.circular(7.0) : Radius.zero,
            topRight: leftPosition ? Radius.zero : Radius.circular(7.0),
            bottomRight: leftPosition ? Radius.zero : Radius.circular(7.0),
          ),
          color: color,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              child: Text(text, style: TextStyle(fontSize: 12.0)),
              padding: EdgeInsets.only(
                bottom: 5.0,
              ),
            ),
            Text('₦$amount', style: TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }
}