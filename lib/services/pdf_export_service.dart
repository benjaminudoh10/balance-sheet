import 'dart:typed_data';

import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/controllers/budgetController.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/controllers/insights_controller.dart';
import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/budget_line.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  PdfExportService._();

  static const PdfColor _ink = PdfColor.fromInt(0xFF0D1117);
  static const PdfColor _muted = PdfColor.fromInt(0xFF57606A);
  static const PdfColor _border = PdfColor.fromInt(0xFFD0D7DE);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF6F8FA);
  static const PdfColor _mint = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor _coral = PdfColor.fromInt(0xFFC2410C);

  static Future<void> shareReport(ReportController controller) async {
    final Map<int, String> contacts = await _contactNamesById();
    final DateTime generatedAt = DateTime.now();
    final String subtitle =
        '${controller.label.value} - ${_rangeLabel(controller.timeFrames[0], controller.timeFrames[1])}';

    await _share(
      filename: _filename('all-transactions', generatedAt),
      title: 'All transactions',
      subtitle: subtitle,
      metrics: <_Metric>[
        _Metric('Income', _formatPdfAmount(controller.income.value), _mint),
        _Metric('Expenses', _formatPdfAmount(controller.expense.value), _coral),
        _Metric(
            'Net',
            _formatPdfSignedNet(
                controller.income.value - controller.expense.value),
            _ink),
        _Metric('Transactions', '${controller.transactions.length}', _ink),
      ],
      sections: <pw.Widget>[
        _detailsList(
          <String, String>{
            'Period': controller.label.value,
            'Category': controller.category.value == 'Category'
                ? 'All categories'
                : controller.categoryLabel.value,
            'Contact': controller.contact.value.id > 0
                ? controller.contact.value.name
                : 'All contacts',
          },
        ),
        _sectionTitle('Transactions'),
        _table(
          headers: <String>[
            'Date',
            'Type',
            'Description',
            'Category',
            'Contact',
            'Amount'
          ],
          rows: controller.transactions.map((Transaction t) {
            return <String>[
              DateFormat.yMMMd().format(t.date),
              t.type == TransactionType.income ? 'Income' : 'Expense',
              _clip(t.description.isEmpty ? 'Untitled' : t.description, 42),
              _categoryLabel(t.category),
              contacts[t.contactId] ??
                  (t.contactId > 0 ? 'Contact #${t.contactId}' : '-'),
              _formatPdfTransactionAmount(t),
            ];
          }).toList(),
          emptyText: 'No transactions in this snapshot.',
        ),
      ],
    );
  }

  static Future<void> shareInsights(InsightsController controller) async {
    if (controller.loading.value) {
      await controller.load();
    }
    final DateTime generatedAt = DateTime.now();
    final int net =
        controller.incomeTotal.value - controller.expenseTotal.value;

    await _share(
      filename: _filename('insights', generatedAt),
      title: 'Insights',
      subtitle:
          '${InsightsController.periodLabel(controller.period.value)} - ${_rangeLabel(controller.rangeStartMs.value, controller.rangeEndMs.value)}',
      metrics: <_Metric>[
        _Metric(
            'Income', _formatPdfAmount(controller.incomeTotal.value), _mint),
        _Metric('Expenses', _formatPdfAmount(controller.expenseTotal.value),
            _coral),
        _Metric('Net', _formatPdfSignedNet(net), _ink),
        _Metric('Previous expenses',
            _formatPdfAmount(controller.expensePreviousPeriod.value), _muted),
      ],
      sections: <pw.Widget>[
        _sectionTitle('Takeaways'),
        if (controller.insightLines.isEmpty)
          _emptyText('No takeaways for this snapshot.')
        else
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: controller.insightLines
                .map((String line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Text(_ascii('- $line'),
                          style: const pw.TextStyle(fontSize: 10)),
                    ))
                .toList(),
          ),
        _sectionTitle('Expenses by category'),
        _table(
          headers: <String>['Category', 'Amount'],
          rows: controller.categoryBarRows
              .map((CategoryBarRow r) =>
                  <String>[r.label, _formatPdfAmount(r.amountMinor)])
              .toList(),
          emptyText: 'No category expenses in this snapshot.',
        ),
        _sectionTitle(controller.cashflowPdfSectionTitle),
        _table(
          headers: <String>[
            controller.cashflowBucketHeader,
            'Income',
            'Expenses',
            'Net',
          ],
          rows: controller.weeklyCashRows.map((WeeklyCashRow r) {
            return <String>[
              controller.useMonthlyBuckets
                  ? DateFormat.yMMM().format(r.bucketStart)
                  : DateFormat.yMMMd().format(r.bucketStart),
              _formatPdfAmount(r.incomeMinor),
              _formatPdfAmount(r.expenseMinor),
              _formatPdfSignedNet(r.incomeMinor - r.expenseMinor),
            ];
          }).toList(),
          emptyText: controller.useMonthlyBuckets
              ? 'No monthly activity in this snapshot.'
              : 'No weekly activity in this snapshot.',
        ),
        _sectionTitle(controller.netTrendPdfSectionTitle),
        _table(
          headers: <String>[controller.netTrendBucketHeader, 'Net'],
          rows: controller.dailyNet
              .map((DailyNetPoint p) => <String>[
                    controller.useMonthlyBuckets
                        ? DateFormat.yMMM().format(p.bucketStart)
                        : DateFormat.yMMMd().format(p.bucketStart),
                    _formatPdfSignedNet(p.netMinor),
                  ])
              .toList(),
          emptyText: controller.useMonthlyBuckets
              ? 'No monthly activity in this snapshot.'
              : 'No daily activity in this snapshot.',
        ),
        _sectionTitle('Top expenses'),
        _table(
          headers: <String>['Date', 'Description', 'Category', 'Amount'],
          rows: controller.topExpenses.map((Transaction t) {
            return <String>[
              DateFormat.yMMMd().format(t.date),
              _clip(t.description.isEmpty ? 'Untitled' : t.description, 54),
              _categoryLabel(t.category),
              _formatPdfTransactionAmount(t),
            ];
          }).toList(),
          emptyText: 'No expenses in this snapshot.',
        ),
      ],
    );
  }

  static Future<void> shareBudget(BudgetController controller) async {
    if (controller.loading.value) {
      await controller.reloadFocusMonth();
    }
    final Map<int, String> contacts = await _contactNamesById();
    final DateTime month = controller.focusMonth.value;
    final DateTime generatedAt = DateTime.now();
    final int remaining =
        controller.plannedTotalMinor - controller.trackedSpentTotalMinor;

    await _share(
      filename: _filename(
          'budget-${DateFormat('yyyy-MM').format(month)}', generatedAt),
      title: 'Budget',
      subtitle: DateFormat('MMMM yyyy').format(month),
      metrics: <_Metric>[
        _Metric(
            'Planned', _formatPdfAmount(controller.plannedTotalMinor), _ink),
        _Metric('Spent tracked',
            _formatPdfAmount(controller.trackedSpentTotalMinor), _coral),
        _Metric('Remaining', _formatPdfSignedNet(remaining),
            remaining < 0 ? _coral : _mint),
        _Metric('Lines', '${controller.lines.length}', _ink),
      ],
      sections: <pw.Widget>[
        _sectionTitle('Planned items'),
        _table(
          headers: <String>[
            'Item',
            'Category',
            'Contact',
            'Planned',
            'Spent',
            'Remaining'
          ],
          rows: controller.lines.map((BudgetLine line) {
            final int? spent = line.hasSpendTracker
                ? controller.spentMinorByLineId[line.id] ?? 0
                : null;
            final int lineRemaining = line.plannedAmount - (spent ?? 0);
            return <String>[
              _clip(
                  line.description.isEmpty ? 'Untitled' : line.description, 42),
              line.categoryKey.isEmpty ? '-' : _categoryLabel(line.categoryKey),
              line.contactId > 0
                  ? contacts[line.contactId] ?? 'Contact #${line.contactId}'
                  : '-',
              _formatPdfBudgetPlanned(line),
              spent == null ? 'Not tracked' : _formatPdfAmount(spent),
              spent == null ? '-' : _formatPdfSignedNet(lineRemaining),
            ];
          }).toList(),
          emptyText: 'No budget lines in this snapshot.',
        ),
        _detailsList(
          <String, String>{
            'Spent tracking':
                'Category and contact trackers use the same rules as the Budget screen.',
            'Generated': DateFormat.yMMMd().add_jm().format(generatedAt),
          },
        ),
      ],
    );
  }

  static Future<void> _share({
    required String filename,
    required String title,
    required String subtitle,
    required List<_Metric> metrics,
    required List<pw.Widget> sections,
  }) async {
    final DateTime generatedAt = DateTime.now();
    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 36),
        footer: (pw.Context context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ),
        build: (pw.Context context) => <pw.Widget>[
          _header(title, subtitle, generatedAt),
          if (metrics.isNotEmpty) _metricsGrid(metrics),
          ...sections,
        ],
      ),
    );

    final Uint8List bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static pw.Widget _header(
      String title, String subtitle, DateTime generatedAt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          _ascii(title),
          style: pw.TextStyle(
            color: _ink,
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(_ascii(subtitle),
            style: const pw.TextStyle(color: _muted, fontSize: 11)),
        pw.SizedBox(height: 2),
        pw.Text(
          'Generated ${DateFormat.yMMMd().add_jm().format(generatedAt)}',
          style: const pw.TextStyle(color: _muted, fontSize: 9),
        ),
        pw.SizedBox(height: 18),
      ],
    );
  }

  static pw.Widget _metricsGrid(List<_Metric> metrics) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _surface,
        border: pw.Border.all(color: _border, width: 0.7),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Wrap(
        spacing: 12,
        runSpacing: 10,
        children: metrics
            .map((_Metric m) => pw.SizedBox(
                  width: 112,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        _ascii(m.label.toUpperCase()),
                        style: const pw.TextStyle(color: _muted, fontSize: 7),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        _ascii(m.value),
                        style: pw.TextStyle(
                          color: m.color,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
      child: pw.Text(
        _ascii(title),
        style: pw.TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _detailsList(Map<String, String> values) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.7),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: values.entries.map((MapEntry<String, String> e) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.RichText(
              text: pw.TextSpan(
                children: <pw.TextSpan>[
                  pw.TextSpan(
                    text: '${_ascii(e.key)}: ',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                        fontSize: 9),
                  ),
                  pw.TextSpan(
                    text: _ascii(e.value),
                    style: const pw.TextStyle(color: _muted, fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required String emptyText,
  }) {
    if (rows.isEmpty) {
      return _emptyText(emptyText);
    }
    return pw.TableHelper.fromTextArray(
      headers: headers.map(_ascii).toList(),
      data: rows.map((List<String> row) => row.map(_ascii).toList()).toList(),
      border: pw.TableBorder.all(color: _border, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: _surface),
      headerStyle: pw.TextStyle(
        color: _ink,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(color: _ink, fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      oddRowDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFAFBFC)),
    );
  }

  static pw.Widget _emptyText(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(_ascii(text),
          style: const pw.TextStyle(color: _muted, fontSize: 10)),
    );
  }

  static Future<Map<int, String>> _contactNamesById() async {
    final List<Contact> contacts = await db.getContacts();
    return <int, String>{
      for (final Contact c in contacts)
        if (c.id > 0 && c.name.trim().isNotEmpty) c.id: c.name.trim(),
    };
  }

  static String _categoryLabel(String key) {
    if (key.trim().isEmpty || key == 'Category') {
      return '-';
    }
    for (final Map<String, Object> c in Categories.CATEGORIES) {
      if (c['key'] == key) {
        return c['label']! as String;
      }
    }
    return key;
  }

  static String _rangeLabel(int startMs, int endMs) {
    final DateTime start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final DateTime end = DateTime.fromMillisecondsSinceEpoch(endMs);
    final String startLabel = DateFormat.yMMMd().format(start);
    final String endLabel = DateFormat.yMMMd().format(end);
    if (startLabel == endLabel) {
      return startLabel;
    }
    return '$startLabel - $endLabel';
  }

  static String _formatPdfAmount(int minor, {String? code}) {
    final String currencyCode = _currencyCode(code);
    final String amount = NumberFormat('#,##0.00', 'en_US').format(minor / 100);
    return '$currencyCode $amount';
  }

  static String _formatPdfSignedNet(int minor) {
    if (minor == 0) {
      return _formatPdfAmount(0);
    }
    final String sign = minor > 0 ? '+' : '-';
    return '$sign ${_formatPdfAmount(minor.abs())}';
  }

  static String _formatPdfTransactionAmount(Transaction transaction) {
    if (transaction.entryIsFcy) {
      return _formatPdfAmount(transaction.entryAmountMinor, code: _fcyCode());
    }
    return _formatPdfAmount(transaction.amount);
  }

  static String _formatPdfBudgetPlanned(BudgetLine line) {
    if (line.planEntryIsFcy) {
      return _formatPdfAmount(line.planEntryAmountMinor, code: _fcyCode());
    }
    return _formatPdfAmount(line.plannedAmount);
  }

  static String _currencyCode(String? code) {
    final String raw = code ?? _lcyCode();
    final String normalized = raw.trim().toUpperCase();
    return normalized.isEmpty ? 'LCY' : _ascii(normalized);
  }

  static String _lcyCode() {
    if (Get.isRegistered<CurrencyController>()) {
      return Get.find<CurrencyController>().lcyCode.value;
    }
    return 'NGN';
  }

  static String _fcyCode() {
    if (Get.isRegistered<CurrencyController>()) {
      return Get.find<CurrencyController>().fcyCode.value;
    }
    return 'USD';
  }

  static String _filename(String stem, DateTime generatedAt) {
    final String date = DateFormat('yyyyMMdd-HHmm').format(generatedAt);
    final String safeStem = stem
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return '${safeStem.isEmpty ? 'export' : safeStem}-$date.pdf';
  }

  static String _clip(String value, int maxChars) {
    final String trimmed = _ascii(value).trim();
    if (trimmed.length <= maxChars) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxChars - 3)}...';
  }

  static String _ascii(String value) {
    return value
        .replaceAll('₦', 'NGN ')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'[^\x09\x0A\x0D\x20-\x7E]'), '?');
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.color);

  final String label;
  final String value;
  final PdfColor color;
}
