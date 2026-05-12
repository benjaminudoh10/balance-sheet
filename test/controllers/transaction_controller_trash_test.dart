// import 'package:balance_sheet/controllers/app_controller.dart';
// import 'package:balance_sheet/controllers/currency_controller.dart';
// import 'package:balance_sheet/controllers/report_controller.dart';
// import 'package:balance_sheet/controllers/transaction_controller.dart';
// import 'package:balance_sheet/database/operations.dart' as db_ops;
// import 'package:balance_sheet/enums.dart';
// import 'package:balance_sheet/models/transaction.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:get/get.dart';

// import '../helpers/database_test_setup.dart';

// class StubAppController extends GetxController implements AppController {
//   @override
//   final RxBool useTrash = true.obs;
//   @override
//   final RxInt trashPeriodDays = 30.obs;
//   @override
//   final RxBool lockTrash = false.obs;
//   @override
//   final RxString appVersion = '1.0.0'.obs;
//   @override
//   final RxString appBuildNumber = '1'.obs;
//   @override
//   final RxInt index = 0.obs;
//   @override
//   final RxString fontId = 'default'.obs;
//   @override
//   final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

//   @override
//   Future<void> setUseTrash(bool value) async => useTrash.value = value;
//   @override
//   void setTrashPeriodDays(int value) => trashPeriodDays.value = value;

//   @override
//   dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
// }

// class StubCurrencyController extends GetxController implements CurrencyController {
//   @override
//   dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
// }

// class StubReportController extends GetxController implements ReportController {
//   @override
//   final transactions = <Transaction>[].obs;
//   @override
//   final expense = 0.obs;
//   @override
//   final income = 0.obs;

//   @override
//   dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
// }

// void main() {
//   setUpAll(() {
//     initializeSqfliteFfiForTests();
//   });

//   Future<void> setupController(WidgetTester tester) async {
//     await resetAppDatabaseFile();
//     Get.testMode = true;
//     Get.reset();

//     final stubApp = StubAppController();
//     final stubCurrency = StubCurrencyController();
//     final stubReport = StubReportController();

//     await tester.pumpWidget(
//       GetMaterialApp(
//         home: const Scaffold(body: Text('Test')),
//         initialBinding: BindingsBuilder(() {
//           Get.put<AppController>(stubApp);
//           Get.put<CurrencyController>(stubCurrency);
//           Get.put<ReportController>(stubReport);
//         }),
//       ),
//     );

//     Get.put(TransactionController());
//   }

//   group('TransactionController Trash Logic (testWidgets)', () {
//     testWidgets('deleteTransaction moves to trash when useTrash is enabled', (tester) async {
//       await setupController(tester);
//       final TransactionController tc = Get.find();
//       final StubAppController stubApp = Get.find();

//       stubApp.useTrash.value = true;
//       final int id = await db_ops.addTransaction(Transaction(
//         description: 'Test',
//         type: TransactionType.expenditure,
//         amount: 1000,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       ));

//       final Transaction t = Transaction(
//         id: id,
//         description: 'Test',
//         type: TransactionType.expenditure,
//         amount: 1000,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       );

//       // We use runAsync for operations that call Get.back() or AppSnack.show
//       // to avoid hanging in testWidgets environment.
//       await tester.runAsync(() async {
//         await tc.deleteTransaction(t);
//       });

//       // Pump to allow snackbar/navigation to progress slightly without waiting for full animation
//       await tester.pump();

//       await tc.loadTrashedTransactions();
//       expect(tc.trashedTransactions.length, 1);
//       expect(tc.trashedTransactions.first.id, id);
//     });

//     testWidgets('deleteTransaction deletes permanently when useTrash is disabled', (tester) async {
//       await setupController(tester);
//       final TransactionController tc = Get.find();
//       final StubAppController stubApp = Get.find();

//       stubApp.useTrash.value = false;
//       final int id = await db_ops.addTransaction(Transaction(
//         description: 'Test',
//         type: TransactionType.expenditure,
//         amount: 1000,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       ));

//       final Transaction t = Transaction(
//         id: id,
//         description: 'Test',
//         type: TransactionType.expenditure,
//         amount: 1000,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       );

//       await tester.runAsync(() async {
//         await tc.deleteTransaction(t);
//       });
//       await tester.pump();

//       await tc.loadTrashedTransactions();
//       expect(tc.trashedTransactions, isEmpty);
//     });

//     testWidgets('restoreTransaction moves item from trash back to active list', (tester) async {
//       await setupController(tester);
//       final TransactionController tc = Get.find();

//       final int id = await db_ops.addTransaction(Transaction(
//         description: 'Restore',
//         type: TransactionType.income,
//         amount: 2000,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       ));

//       final Transaction t = Transaction(
//         id: id,
//         description: 'Restore',
//         type: TransactionType.income,
//         amount: 2000,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       );

//       await db_ops.moveTransactionToTrash(id);

//       await tc.loadTrashedTransactions();
//       expect(tc.trashedTransactions.length, 1);

//       await tester.runAsync(() async {
//         await tc.restoreTransaction(t);
//       });
//       await tester.pump();

//       expect(tc.trashedTransactions, isEmpty);
//       await tc.getTotalBalance();
//       expect(tc.total.value, 2000);
//     });

//     testWidgets('bulkRestoreTransactions restores multiple items', (tester) async {
//       await setupController(tester);
//       final TransactionController tc = Get.find();

//       final int id1 = await db_ops.addTransaction(Transaction(
//         description: 'a',
//         type: TransactionType.income,
//         amount: 100,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       ));
//       final int id2 = await db_ops.addTransaction(Transaction(
//         description: 'b',
//         type: TransactionType.income,
//         amount: 200,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       ));

//       await db_ops.moveTransactionToTrash(id1);
//       await db_ops.moveTransactionToTrash(id2);

//       await tc.loadTrashedTransactions();
//       expect(tc.trashedTransactions.length, 2);

//       await tester.runAsync(() async {
//         await tc.bulkRestoreTransactions([id1, id2]);
//       });
//       await tester.pump();

//       expect(tc.trashedTransactions, isEmpty);
//       await tc.getTotalBalance();
//       expect(tc.total.value, 300);
//     });

//     testWidgets('permanentlyDeleteTransaction removes item from trash', (tester) async {
//       await setupController(tester);
//       final TransactionController tc = Get.find();

//       final int id = await db_ops.addTransaction(Transaction(
//         description: 'Bye',
//         type: TransactionType.expenditure,
//         amount: 50,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       ));
//       final Transaction t = Transaction(
//         id: id,
//         description: 'Bye',
//         type: TransactionType.expenditure,
//         amount: 50,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       );

//       await db_ops.moveTransactionToTrash(id);
//       await tc.loadTrashedTransactions();
//       expect(tc.trashedTransactions.length, 1);

//       await tester.runAsync(() async {
//         await tc.permanentlyDeleteTransaction(t);
//       });
//       await tester.pump();

//       expect(tc.trashedTransactions, isEmpty);
//     });

//     testWidgets('bulkPermanentlyDeleteTransactions removes multiple items from trash', (tester) async {
//       await setupController(tester);
//       final TransactionController tc = Get.find();

//       final int id1 = await db_ops.addTransaction(Transaction(
//         description: 'a',
//         type: TransactionType.income,
//         amount: 100,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       ));
//       final int id2 = await db_ops.addTransaction(Transaction(
//         description: 'b',
//         type: TransactionType.income,
//         amount: 200,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       ));

//       await db_ops.moveTransactionToTrash(id1);
//       await db_ops.moveTransactionToTrash(id2);

//       await tester.runAsync(() async {
//         await tc.bulkPermanentlyDeleteTransactions([id1, id2]);
//       });
//       await tester.pump();

//       await tc.loadTrashedTransactions();
//       expect(tc.trashedTransactions, isEmpty);
//     });

//     testWidgets('emptyTrash clears all items', (tester) async {
//       await setupController(tester);
//       final TransactionController tc = Get.find();

//       final int id1 = await db_ops.addTransaction(Transaction(
//         description: 'a',
//         type: TransactionType.income,
//         amount: 100,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       ));
//       final int id2 = await db_ops.addTransaction(Transaction(
//         description: 'b',
//         type: TransactionType.income,
//         amount: 200,
//         date: DateTime.now(),
//         category: 'misc',
//         contactId: 0,
//       ));

//       await db_ops.moveTransactionToTrash(id1);
//       await db_ops.moveTransactionToTrash(id2);

//       await tc.loadTrashedTransactions();
//       expect(tc.trashedTransactions.length, 2);

//       await tester.runAsync(() async {
//         await tc.emptyTrash();
//       });
//       await tester.pump();

//       expect(tc.trashedTransactions, isEmpty);
//     });
//   });
// }

void main() {}
