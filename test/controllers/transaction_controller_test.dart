import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../helpers/database_test_setup.dart';
import '../helpers/path_provider_mock.dart';

void main() {
  setUpAll(() async {
    setupPathProviderMock();
    initializeSqfliteFfiForTests();
    await GetStorage.init();
  });

  setUp(() async {
    await resetAppDatabaseFile();
    GetStorage().erase();
    Get.testMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  Future<TransactionController> pumpController() async {
    if (!Get.isRegistered<ReportController>()) {
      Get.put(ReportController(), permanent: true);
    }
    Get.put(TransactionController());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return Get.find<TransactionController>();
  }

  group('TransactionController balance updates', () {
    test('updateControllerData adds expense to todaysExpense and subtracts total', () async {
      final TransactionController c = await pumpController();
      c.total.value = 10000;
      c.todaysExpense.value = 0;
      c.todaysIncome.value = 0;

      final Transaction t = Transaction(
        description: 'Bus',
        type: TransactionType.expenditure,
        amount: 500,
        date: DateTime.now(),
        category: 'transport',
        contactId: 0,
      );
      c.updateControllerData(t);

      expect(c.todaysExpense.value, 500);
      expect(c.total.value, 9500);
      expect(c.description.value, '');
    });

    test('updateControllerData adds income to todaysIncome and total', () async {
      final TransactionController c = await pumpController();
      c.total.value = 0;
      c.todaysExpense.value = 0;
      c.todaysIncome.value = 0;

      final Transaction t = Transaction(
        description: 'Pay',
        type: TransactionType.income,
        amount: 2000,
        date: DateTime.now(),
        category: 'salary',
        contactId: 0,
      );
      c.updateControllerData(t);

      expect(c.todaysIncome.value, 2000);
      expect(c.total.value, 2000);
    });

    test('updateControllerDataAfterDeletion reverses expense from today', () async {
      final TransactionController c = await pumpController();
      c.total.value = 9000;
      c.todaysExpense.value = 400;
      c.todaysIncome.value = 100;

      final Transaction t = Transaction(
        id: 1,
        description: 'x',
        type: TransactionType.expenditure,
        amount: 400,
        date: DateTime.now(),
        category: 'food',
        contactId: 0,
      );
      c.updateControllerDataAfterDeletion(t);

      expect(c.todaysExpense.value, 0);
      expect(c.total.value, 9400);
    });

    test('updateControllerDataAfterDeletion skips today adjustment when date differs', () async {
      final TransactionController c = await pumpController();
      c.total.value = 5000;
      c.todaysExpense.value = 100;

      final Transaction t = Transaction(
        id: 2,
        description: 'old',
        type: TransactionType.expenditure,
        amount: 200,
        date: DateTime(2020, 1, 1),
        category: 'misc',
        contactId: 0,
      );
      c.updateControllerDataAfterDeletion(t);

      expect(c.todaysExpense.value, 100);
      expect(c.total.value, 5200);
    });

    test('updateControllerDataAfterUpdate patches report list and resets fields', () async {
      final TransactionController c = await pumpController();
      c.total.value = 10000;
      c.todaysExpense.value = 300;
      c.todaysIncome.value = 0;
      c.transactions.value = [
        Transaction(
          id: 5,
          description: 'a',
          type: TransactionType.expenditure,
          amount: 300,
          date: DateTime.now(),
          category: 'food',
          contactId: 0,
        ),
      ];

      final Transaction prev = c.transactions.first;
      final ReportController report = Get.find<ReportController>();
      report.transactions.value = <Transaction>[prev];
      report.expense.value = 300;
      report.income.value = 0;

      final Transaction next = Transaction(
        id: 5,
        description: 'b',
        type: TransactionType.expenditure,
        amount: 500,
        date: DateTime.now(),
        category: 'food',
        contactId: 0,
      );
      c.updateControllerDataAfterUpdate(next, prev);

      expect(report.transactions.first.amount, 500);
      expect(report.expense.value, 500);
      expect(c.description.value, '');
    });
  });

  group('TransactionController contact helpers', () {
    test('resetContact clears selection', () async {
      final TransactionController c = await pumpController();
      c.contact.value = Contact(id: 1, name: 'X');
      c.resetContact();
      expect(c.contact.value?.name, '');
    });
  });
}
