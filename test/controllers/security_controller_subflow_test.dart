import 'dart:async';

import 'package:balance_sheet/controllers/securityController.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityController.runWithSubFlow', () {
    test('marks isSubFlowActive only while body runs', () async {
      final SecurityController c = SecurityController();
      expect(c.isSubFlowActive, isFalse);

      bool sawActive = false;
      await c.runWithSubFlow(() async {
        sawActive = c.isSubFlowActive;
      });
      expect(sawActive, isTrue);
      expect(c.isSubFlowActive, isFalse);
    });

    test('balances depth on exception', () async {
      final SecurityController c = SecurityController();
      await expectLater(
        c.runWithSubFlow<void>(() async {
          throw StateError('boom');
        }),
        throwsA(isA<StateError>()),
      );
      expect(c.isSubFlowActive, isFalse);
    });

    test('nests correctly', () async {
      final SecurityController c = SecurityController();
      await c.runWithSubFlow(() async {
        expect(c.isSubFlowActive, isTrue);
        await c.runWithSubFlow(() async {
          expect(c.isSubFlowActive, isTrue);
        });
        expect(c.isSubFlowActive, isTrue);
      });
      expect(c.isSubFlowActive, isFalse);
    });

    test('long-running body stays active across awaits', () async {
      final SecurityController c = SecurityController();
      final Completer<void> gate = Completer<void>();
      final Future<void> done = c.runWithSubFlow(() async {
        await gate.future;
      });
      // Mid-flow snapshot — must still be active before [body] returns.
      expect(c.isSubFlowActive, isTrue);
      gate.complete();
      await done;
      expect(c.isSubFlowActive, isFalse);
    });
  });
}
