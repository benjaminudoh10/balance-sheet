import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction', () {
    test('toJson round-trips with fromJson', () {
      final DateTime d = DateTime.utc(2024, 6, 15, 12);
      final Transaction t = Transaction(
        id: 7,
        description: 'Coffee',
        type: TransactionType.expenditure,
        amount: 1500,
        date: d,
        category: 'food',
        contactId: 2,
      );
      final Transaction back = Transaction.fromJson(t.toJson());
      expect(back.id, 7);
      expect(back.description, 'Coffee');
      expect(back.type, TransactionType.expenditure);
      expect(back.amount, 1500);
      expect(back.date.millisecondsSinceEpoch, d.millisecondsSinceEpoch);
      expect(back.category, 'food');
      expect(back.contactId, 2);
      expect(back.entryIsFcy, false);
      expect(back.entryAmountMinor, 1500);
    });

    test('fromJson maps income type', () {
      final Transaction t = Transaction.fromJson(<String, dynamic>{
        'id': 1,
        'description': 'Pay',
        'type': 'income',
        'amount': 5000,
        'date': 0,
        'category': 'salary',
        'contactId': 0,
      });
      expect(t.type, TransactionType.income);
    });

    test('fromJson maps non-income to expenditure', () {
      final Transaction t = Transaction.fromJson(<String, dynamic>{
        'id': 1,
        'description': 'x',
        'type': 'expenditure',
        'amount': 1,
        'date': 0,
        'category': 'misc',
        'contactId': 0,
      });
      expect(t.type, TransactionType.expenditure);
    });

    test('fromJson uses defaults for missing fields', () {
      final Transaction t = Transaction.fromJson(<String, dynamic>{});
      expect(t.id, 0);
      expect(t.amount, 0);
      expect(t.description, '');
      expect(t.category, '');
    });
  });

  group('Contact', () {
    test('toJson round-trips', () {
      final Contact c = Contact(id: 3, name: 'Ada');
      final Contact back = Contact.fromJson(c.toJson());
      expect(back.id, 3);
      expect(back.name, 'Ada');
    });

    test('fromJson defaults', () {
      final Contact c = Contact.fromJson(<String, dynamic>{});
      expect(c.id, 0);
      expect(c.name, '');
    });
  });
}
