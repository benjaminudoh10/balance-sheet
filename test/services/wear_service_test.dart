import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:balance_sheet/services/wear_service.dart';
import 'package:balance_sheet/controllers/transaction_controller.dart';
import 'package:balance_sheet/controllers/investment_controller.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';

class StubTransactionController extends GetxController
    implements TransactionController {
  @override
  final RxInt total = 0.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubInvestmentController extends GetxController
    implements InvestmentController {
  @override
  final RxInt stocksTotalMinor = 0.obs;
  @override
  final RxInt otherInvestmentsTotalMinor = 0.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubCurrencyController extends GetxController
    implements CurrencyController {
  @override
  final RxString lcyCode = 'USD'.obs;

  @override
  String symbolFor(String iso4217) => '\$';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WearService.sync', () {
    const MethodChannel channel = MethodChannel('balanced/wear');
    final List<MethodCall> log = [];

    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });
    });

    setUp(() {
      log.clear();
      Get.reset();
    });

    test('sync does nothing if controllers are not registered', () async {
      await WearService.sync();
      expect(log, isEmpty);
    });

    test(
        'sync invokes method channel with correct values when controllers are registered',
        () async {
      final tx = StubTransactionController();
      final inv = StubInvestmentController();
      final cur = StubCurrencyController();

      Get.put<TransactionController>(tx);
      Get.put<InvestmentController>(inv);
      Get.put<CurrencyController>(cur);

      tx.total.value = 10000; // $100.00
      inv.stocksTotalMinor.value = 5000; // $50.00
      inv.otherInvestmentsTotalMinor.value = 2500; // $25.00
      // Net worth = 10000 + 5000 + 2500 = 17500 ($175.00)

      await WearService.sync();

      expect(log, hasLength(1));
      expect(log.first.method, equals('syncWearData'));
      expect(
          log.first.arguments,
          equals({
            'balance': '100.00',
            'investments': '75.00',
            'netWorth': '175.00',
            'currency': '\$',
          }));
    });
  });
}
