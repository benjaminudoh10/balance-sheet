import 'package:balance_sheet/controllers/report_controller.dart';
import 'package:balance_sheet/database/operations.dart' as db_ops;
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers/database_test_setup.dart';

void main() {
  group('ReportController Multi-select', () {
    setUpAll(() {
      initializeSqfliteFfiForTests();
    });

    setUp(() async {
      await resetAppDatabaseFile();
      Get.testMode = true;
      Get.reset();
    });

    tearDown(() {
      Get.reset();
    });

    test('selects and deselects transactions', () async {
      final rc = Get.put(ReportController());
      
      // Add transactions
      for (int i = 0; i < 3; i++) {
        await db_ops.addTransaction(Transaction(
          id: i + 1,
          description: 'row $i',
          type: TransactionType.expenditure,
          amount: 10,
          date: DateTime.now(),
          category: 'misc',
          contactId: 0,
        ));
      }
      await rc.getTransactions();

      rc.toggleTransactionSelection(1);
      expect(rc.selectedTransactionIds, {1});
      expect(rc.isMultiSelectMode, isTrue);

      rc.toggleTransactionSelection(2);
      expect(rc.selectedTransactionIds, {1, 2});

      rc.toggleTransactionSelection(1);
      expect(rc.selectedTransactionIds, {2});

      rc.clearSelection();
      expect(rc.selectedTransactionIds, isEmpty);
      expect(rc.isMultiSelectMode, isFalse);
    });

    test('deletes selected transactions', () async {
      final rc = Get.put(ReportController());
      
      // Add transactions
      for (int i = 0; i < 3; i++) {
        await db_ops.addTransaction(Transaction(
          id: i + 1,
          description: 'row $i',
          type: TransactionType.expenditure,
          amount: 10,
          date: DateTime.now(),
          category: 'misc',
          contactId: 0,
        ));
      }

      // Ensure report controller covers the current day
      rc.type.value = ReportType.today;
      rc.timeFrames = rc.getTimeFrame();
      
      await rc.getTransactions();
      expect(rc.transactions.length, 3);
      // This line is failing?

      rc.toggleTransactionSelection(1);
      rc.toggleTransactionSelection(3);
      await rc.deleteSelectedTransactions();

      expect(rc.transactions.length, 1);
      expect(rc.transactions.first.id, 2);
      expect(rc.selectedTransactionIds, isEmpty);
    });
  });
}
