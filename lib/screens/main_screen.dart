import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/screens/new_income_form.dart';
import 'package:balance_sheet/screens/report.dart';
import 'package:balance_sheet/screens/settings_screen.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const double APP_WIDTH = 20.0;

class MainView extends StatelessWidget {
  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat.yMMMd().format(DateTime.now());

    return Container(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              left: APP_WIDTH,
              right: APP_WIDTH,
              bottom: 5.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.PRIMARY,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance Sheet',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.to(Settings()),
                        child: roundedWidget(
                          widget: Row(
                            children: [
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10.0),
                              Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 22.0,
                              ),
                            ],
                          ),
                          containerColor: Color(0x44ffffff),
                          padding: EdgeInsets.symmetric(
                            vertical: 7.0,
                            horizontal: 15.0,
                          ),
                          shadow: BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TotalContainer(),
                  GestureDetector(
                    onTap: () => Get.to(ReportView()),
                    child: Container(
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
                              color: AppColors.PRIMARY,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          roundedWidget(
                            widget: Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.PRIMARY,
                              size: 20.0,
                            ),
                            containerColor: AppColors.SECONDARY,
                            padding: EdgeInsets.all(2.0)
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 30.0,
                horizontal: 20.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.SECONDARY,
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
                      _buildButton(TransactionType.expenditure),
                      _buildButton(TransactionType.income),
                    ],
                  ),
                  Obx(() => totalDayTransaction(
                    formattedDate,
                    _transactionController.todaysIncome.value,
                    _transactionController.todaysExpense.value
                  )),
                  Obx(() => Expanded(
                    child: _transactionController.transactions.length == 0
                      ? ListView(
                          children: [
                            EmptyState(
                              icon: Icon(
                                Icons.money,
                                size: 48.0,
                                color: AppColors.PRIMARY,
                              ),
                              primaryText: Text(
                                'Add your first transaction today',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              secondaryText: Text(
                                'Click "Income" or "Expenditure" above.',
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(top: 0.0),
                          itemCount: _transactionController.transactions.length,
                          itemBuilder: (context, index) {
                            return singleTransactionContainer(_transactionController.transactions[index]);
                          },
                        ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showNewTransactionModal(TransactionType type) async {
  final TransactionController _transactionController = Get.find();

  BuildContext context = Get.context;
  await showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    barrierColor: Color(0x22AF47FF),
    isScrollControlled: true,
    context: context,
    builder: (context) => IncomeForm(type: type),
  ).whenComplete(() => _transactionController.resetFieldValues());
}

Widget _buildButton(TransactionType type) {
  return GestureDetector(
    onTap: () => showNewTransactionModal(type),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7.0),
        color: type == TransactionType.income ? AppColors.GREEN : AppColors.RED,
      ),
      padding: EdgeInsets.symmetric(
        vertical: 10.0,
        horizontal: 20.0,
      ),
      width: Get.width * .5 - APP_WIDTH - 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          roundedWidget(
            widget: type == TransactionType.income ? Icon(
              Icons.add,
              color: Colors.white,
              size: 20.0,
            ) : Icon(
              Icons.remove,
              color: Colors.white,
              size: 20.0,
            ),
            containerColor: Color(0x22ffffff),
          ),
          SizedBox(width: 15.0),
          Text(
            type == TransactionType.income ? "Income" : "Expenditure",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class TotalContainer extends StatelessWidget {
  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      margin: EdgeInsets.only(top: 10.0),
      width: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceSection(
            'Total Balance',
            _transactionController.total.value,
            Colors.white,
            true,
          ),
          _buildBalanceSection(
            "Today's Balance",
            _transactionController.todaysIncome.value - _transactionController.todaysExpense.value,
            AppColors.PURPLE_GREY,
            false,
          ),
        ],
      ),
    ));
  }

  Widget _buildBalanceSection(String text, int amount, Color color, bool leftPosition) {
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
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              padding: EdgeInsets.only(
                bottom: 5.0,
              ),
            ),
            Text('${formatAmount(amount)}', style: TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }
}
