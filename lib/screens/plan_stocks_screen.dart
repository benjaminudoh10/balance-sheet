import 'dart:math' as math;

import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/controllers/investment_controller.dart';
import 'package:balance_sheet/database/investment_operations.dart' as inv;
import 'package:balance_sheet/investment/investment_days.dart';
import 'package:balance_sheet/models/investment_holding.dart';
import 'package:balance_sheet/models/investment_lot_entry.dart';
import 'package:balance_sheet/models/investment_price_point.dart';
import 'package:balance_sheet/models/other_investment.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/dual_currency_total.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/slidable_peek_hint.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const Color _kInvestAccent = Color(0xFF818CF8);

/// Same floating card treatment as the budget planned-item editor.
Widget _floatingModalCard({
  required BuildContext context,
  required AppPalette palette,
  required Widget child,
}) {
  final double inset = MediaQuery.viewInsetsOf(context).bottom;
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    ),
  );
}

/// Avoid calling [Get.snackbar] synchronously right after [Navigator.pop]: the overlay /
/// [ScaffoldMessenger] can rebuild while the route subtree is still tearing down, which
/// triggers framework assertions on inherited widgets.
void _snackbarAfterRouteSettled(String title, String message) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Get.snackbar(title, message);
  });
}

/// Bottom sheet for add/edit other investments. Controllers are owned by [State] and disposed
/// after the route is unmounted — disposing them in the caller after [showModalBottomSheet]
/// returns can assert (TextFields still listening during dismiss animation).
class _OtherInvestmentEditorContent extends StatefulWidget {
  const _OtherInvestmentEditorContent({
    required this.palette,
    required this.inv,
    required this.existing,
  });

  final AppPalette palette;
  final InvestmentController inv;
  final OtherInvestment? existing;

  @override
  State<_OtherInvestmentEditorContent> createState() => _OtherInvestmentEditorContentState();
}

class _OtherInvestmentEditorContentState extends State<_OtherInvestmentEditorContent> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _amountCtrl;
  late final FocusNode _labelFocus;
  late final FocusNode _amountFocus;
  bool _entryIsFcy = false;
  final CurrencyController _cur = Get.find<CurrencyController>();

  @override
  void initState() {
    super.initState();
    _labelFocus = FocusNode();
    _amountFocus = FocusNode();
    final OtherInvestment? e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _amountCtrl = TextEditingController(
      text: e != null
          ? (e.entryIsFcy ? e.entryMinor : e.valueLcyMinor) != 0
              ? ((e.entryIsFcy ? e.entryMinor : e.valueLcyMinor) / 100).toStringAsFixed(2)
              : ''
          : '',
    );
    _entryIsFcy = e?.entryIsFcy ?? false;
    if (e == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _labelFocus.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _labelFocus.dispose();
    _amountFocus.dispose();
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String lab = _labelCtrl.text.trim();
    if (lab.isEmpty) {
      Get.snackbar('Label', 'Enter a short name for this investment.');
      return;
    }
    final int? entryMinor = parseMoneyStringToMinor(_amountCtrl.text);
    if (entryMinor == null || entryMinor <= 0) {
      Get.snackbar('Amount', 'Enter a value greater than zero.');
      return;
    }
    final int lcy = _entryIsFcy ? _cur.lcyMinorFromFcyMinor(entryMinor) : entryMinor;
    final OtherInvestment? existing = widget.existing;
    if (existing == null) {
      await widget.inv.addOtherInvestment(
        label: lab,
        valueLcyMinor: lcy,
        entryIsFcy: _entryIsFcy,
        entryMinor: entryMinor,
      );
    } else {
      await widget.inv.updateOtherInvestment(
        OtherInvestment(
          id: existing.id,
          label: lab,
          valueLcyMinor: lcy,
          entryCurrency: _entryIsFcy ? 'fcy' : 'lcy',
          entryMinor: entryMinor,
          sortOrder: existing.sortOrder,
          updatedAtMs: existing.updatedAtMs,
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    _snackbarAfterRouteSettled('Saved', existing == null ? 'Investment added' : 'Investment updated');
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = widget.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            widget.existing == null ? 'Add other investment' : 'Edit investment',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(color: p.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Name it (e.g. Cash, Land, Gold) and enter the value in local or foreign currency.',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: p.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelCtrl,
            focusNode: _labelFocus,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              labelText: 'Label',
              labelStyle: TextStyle(color: p.textSecondary),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: p.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _kInvestAccent)),
            ),
            onSubmitted: (_) {
              _amountFocus.requestFocus();
            },
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              final String code = _entryIsFcy ? _cur.fcyCode.value : _cur.lcyCode.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Value ($code)',
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: p.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<bool>(
                        segments: <ButtonSegment<bool>>[
                          ButtonSegment<bool>(value: false, label: Text(_cur.lcyCode.value)),
                          ButtonSegment<bool>(value: true, label: Text(_cur.fcyCode.value)),
                        ],
                        selected: <bool>{_entryIsFcy},
                        onSelectionChanged: (Set<bool> next) {
                          if (next.isEmpty) return;
                          final bool toFcy = next.single;
                          if (toFcy == _entryIsFcy) return;
                          AppHaptics.selection();
                          setState(() {
                            final int m = parseMoneyStringToMinor(_amountCtrl.text) ?? 0;
                            if (m <= 0) {
                              _entryIsFcy = toFcy;
                              return;
                            }
                            if (toFcy) {
                              _amountCtrl.text = (_cur.fcyMinorFromLcyMinor(m) / 100).toStringAsFixed(2);
                              _entryIsFcy = true;
                            } else {
                              _amountCtrl.text = (_cur.lcyMinorFromFcyMinor(m) / 100).toStringAsFixed(2);
                              _entryIsFcy = false;
                            }
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          selectedBackgroundColor: _kInvestAccent,
                          selectedForegroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    focusNode: _amountFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: <TextInputFormatter>[DecimalTextInputFormatter()],
                    style: TextStyle(color: p.textPrimary),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: p.textSecondary),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: p.border)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _kInvestAccent)),
                    ),
                    onSubmitted: (_) async {
                      AppHaptics.light();
                      await _save();
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              AppHaptics.light();
              await _save();
            },
            style: FilledButton.styleFrom(backgroundColor: _kInvestAccent, foregroundColor: Colors.white),
            child: Text(widget.existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _AddHoldingEditorContent extends StatefulWidget {
  const _AddHoldingEditorContent({
    required this.palette,
    required this.onSave,
  });

  final AppPalette palette;
  final Future<void> Function(String ticker, String displayName) onSave;

  @override
  State<_AddHoldingEditorContent> createState() => _AddHoldingEditorContentState();
}

class _AddHoldingEditorContentState extends State<_AddHoldingEditorContent> {
  late final TextEditingController _tickerCtrl;
  late final TextEditingController _nameCtrl;
  late final FocusNode _tickerFocus;
  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _tickerFocus = FocusNode();
    _nameFocus = FocusNode();
    _tickerCtrl = TextEditingController();
    _nameCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tickerFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _tickerFocus.dispose();
    _nameFocus.dispose();
    _tickerCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String t = _tickerCtrl.text.trim();
    if (t.isEmpty) {
      Get.snackbar('Ticker', 'Enter a ticker symbol for this holding.');
      return;
    }
    await widget.onSave(t, _nameCtrl.text.trim());
    if (!mounted) return;
    Navigator.of(context).pop();
    _snackbarAfterRouteSettled('Saved', 'Holding added');
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = widget.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Add holding', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: p.textPrimary)),
          const SizedBox(height: 16),
          TextField(
            controller: _tickerCtrl,
            focusNode: _tickerFocus,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              labelText: 'Ticker',
              labelStyle: TextStyle(color: p.textSecondary),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: p.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _kInvestAccent)),
            ),
            onSubmitted: (_) => _nameFocus.requestFocus(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              labelText: 'Name (optional)',
              labelStyle: TextStyle(color: p.textSecondary),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: p.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _kInvestAccent)),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              AppHaptics.light();
              await _submit();
            },
            style: FilledButton.styleFrom(backgroundColor: _kInvestAccent),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _AddInvestmentLotSheet extends StatefulWidget {
  const _AddInvestmentLotSheet({
    required this.palette,
    required this.holding,
    required this.onCompleted,
  });

  final AppPalette palette;
  final InvestmentHolding holding;
  final Future<void> Function() onCompleted;

  @override
  State<_AddInvestmentLotSheet> createState() => _AddInvestmentLotSheetState();
}

class _AddInvestmentLotSheetState extends State<_AddInvestmentLotSheet> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final FocusNode _qtyFocus;
  late final FocusNode _priceFocus;
  bool _entryIsFcy = true;
  late DateTime _purchaseDay;
  final CurrencyController _cur = Get.find<CurrencyController>();

  @override
  void initState() {
    super.initState();
    _qtyFocus = FocusNode();
    _priceFocus = FocusNode();
    _qtyCtrl = TextEditingController(text: '0');
    _priceCtrl = TextEditingController();
    _purchaseDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _qtyFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _qtyFocus.dispose();
    _priceFocus.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final double? qty = double.tryParse(_qtyCtrl.text.replaceAll(',', ''));
    if (qty == null) {
      Get.snackbar('Quantity', 'Enter a valid quantity.');
      return;
    }
    if (qty == 0) {
      Get.snackbar('Quantity', 'Enter a non-zero quantity (use negative for sales).');
      return;
    }
    final int? pxEntry = parseMoneyStringToMinor(_priceCtrl.text);
    if (pxEntry == null) {
      Get.snackbar('Price required', 'Enter the per-share price for this lot.');
      return;
    }
    if (pxEntry <= 0) {
      Get.snackbar('Price', 'Enter a per-share price greater than zero.');
      return;
    }
    final int lcyPx = _entryIsFcy ? _cur.lcyMinorFromFcyMinor(pxEntry) : pxEntry;
    final DateTime atMidnight = DateTime(_purchaseDay.year, _purchaseDay.month, _purchaseDay.day);
    await inv.insertInvestmentLot(
      holdingId: widget.holding.id,
      occurredAtMs: atMidnight.millisecondsSinceEpoch,
      quantityDelta: qty,
      purchasePriceMinorPerShare: lcyPx,
      purchaseEntryIsFcy: _entryIsFcy,
      purchasePriceEntryMinorPerShare: pxEntry,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    _snackbarAfterRouteSettled('Saved', 'Lot saved');
    await widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = widget.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Add / remove shares', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Enter the price paid (or received) per share for this lot. Sales use a negative quantity.',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyCtrl,
            focusNode: _qtyFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            textInputAction: TextInputAction.next,
            inputFormatters: <TextInputFormatter>[DecimalTextInputFormatter(decimalRange: 8)],
            decoration: const InputDecoration(labelText: 'Quantity (fractional ok)'),
            onSubmitted: (_) => _priceFocus.requestFocus(),
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              final String code = _entryIsFcy ? _cur.fcyCode.value : _cur.lcyCode.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Price per share ($code)',
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: p.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<bool>(
                        segments: <ButtonSegment<bool>>[
                          ButtonSegment<bool>(value: false, label: Text(_cur.lcyCode.value)),
                          ButtonSegment<bool>(value: true, label: Text(_cur.fcyCode.value)),
                        ],
                        selected: <bool>{_entryIsFcy},
                        onSelectionChanged: (Set<bool> next) {
                          if (next.isEmpty) return;
                          final bool toFcy = next.single;
                          if (toFcy == _entryIsFcy) return;
                          AppHaptics.selection();
                          setState(() {
                            final int m = parseMoneyStringToMinor(_priceCtrl.text) ?? 0;
                            if (m <= 0) {
                              _entryIsFcy = toFcy;
                              return;
                            }
                            if (toFcy) {
                              _priceCtrl.text = (_cur.fcyMinorFromLcyMinor(m) / 100).toStringAsFixed(2);
                              _entryIsFcy = true;
                            } else {
                              _priceCtrl.text = (_cur.lcyMinorFromFcyMinor(m) / 100).toStringAsFixed(2);
                              _entryIsFcy = false;
                            }
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          selectedBackgroundColor: _kInvestAccent,
                          selectedForegroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceCtrl,
                    focusNode: _priceFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: <TextInputFormatter>[DecimalTextInputFormatter()],
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: p.textSecondary),
                    ),
                    onSubmitted: (_) async {
                      AppHaptics.light();
                      await _save();
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(DateFormat.yMMMd().format(_purchaseDay)),
            subtitle: const Text('Purchase date'),
            trailing: const Icon(Icons.event_rounded),
            onTap: () async {
              AppHaptics.light();
              final DateTime? d = await showDatePicker(
                context: context,
                initialDate: _purchaseDay,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (d == null) return;
              setState(() {
                _purchaseDay = DateTime(d.year, d.month, d.day);
              });
            },
          ),
          FilledButton(
            onPressed: () async {
              AppHaptics.light();
              await _save();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _LogInvestmentPriceSheet extends StatefulWidget {
  const _LogInvestmentPriceSheet({
    required this.palette,
    required this.holding,
    required this.onCompleted,
  });

  final AppPalette palette;
  final InvestmentHolding holding;
  final Future<void> Function() onCompleted;

  @override
  State<_LogInvestmentPriceSheet> createState() => _LogInvestmentPriceSheetState();
}

class _LogInvestmentPriceSheetState extends State<_LogInvestmentPriceSheet> {
  late final TextEditingController _priceCtrl;
  late final FocusNode _priceFocus;
  bool _entryIsFcy = true;
  late DateTime _priceDay;
  final CurrencyController _cur = Get.find<CurrencyController>();

  @override
  void initState() {
    super.initState();
    _priceFocus = FocusNode();
    _priceCtrl = TextEditingController();
    _priceDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _priceFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _priceFocus.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final int? entryMinor = parseMoneyStringToMinor(_priceCtrl.text);
    if (entryMinor == null || entryMinor <= 0) {
      Get.snackbar('Price', 'Enter a value greater than zero.');
      return;
    }
    final int lcyMinor = _entryIsFcy ? _cur.lcyMinorFromFcyMinor(entryMinor) : entryMinor;
    final int day = encodeLocalYyyymmdd(_priceDay);
    await inv.insertInvestmentPricePoint(
      holdingId: widget.holding.id,
      asOfDayYyyymmdd: day,
      priceMinorPerShare: lcyMinor,
      entryIsFcy: _entryIsFcy,
      priceEntryMinorPerShare: entryMinor,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    _snackbarAfterRouteSettled('Saved', 'Market price saved');
    await widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = widget.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Market price per share', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'The stock’s price on this calendar day (latest entry wins for current value).',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              final String code = _entryIsFcy ? _cur.fcyCode.value : _cur.lcyCode.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Amount ($code)',
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: p.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<bool>(
                        segments: <ButtonSegment<bool>>[
                          ButtonSegment<bool>(value: false, label: Text(_cur.lcyCode.value)),
                          ButtonSegment<bool>(value: true, label: Text(_cur.fcyCode.value)),
                        ],
                        selected: <bool>{_entryIsFcy},
                        onSelectionChanged: (Set<bool> next) {
                          if (next.isEmpty) return;
                          final bool toFcy = next.single;
                          if (toFcy == _entryIsFcy) return;
                          AppHaptics.selection();
                          setState(() {
                            final int m = parseMoneyStringToMinor(_priceCtrl.text) ?? 0;
                            if (m <= 0) {
                              _entryIsFcy = toFcy;
                              return;
                            }
                            if (toFcy) {
                              _priceCtrl.text = (_cur.fcyMinorFromLcyMinor(m) / 100).toStringAsFixed(2);
                              _entryIsFcy = true;
                            } else {
                              _priceCtrl.text = (_cur.lcyMinorFromFcyMinor(m) / 100).toStringAsFixed(2);
                              _entryIsFcy = false;
                            }
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          selectedBackgroundColor: _kInvestAccent,
                          selectedForegroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceCtrl,
                    focusNode: _priceFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: <TextInputFormatter>[DecimalTextInputFormatter()],
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: p.textSecondary),
                    ),
                    onSubmitted: (_) async {
                      AppHaptics.light();
                      await _save();
                    },
                  ),
                ],
              );
            },
          ),
          ListTile(
            title: Text(DateFormat.yMMMd().format(_priceDay)),
            subtitle: const Text('As of date'),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: () async {
              AppHaptics.light();
              final DateTime? d = await showDatePicker(
                context: context,
                initialDate: _priceDay,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (d == null) return;
              setState(() {
                _priceDay = DateTime(d.year, d.month, d.day);
              });
            },
          ),
          FilledButton(
            onPressed: () async {
              AppHaptics.light();
              await _save();
            },
            child: const Text('Save price'),
          ),
        ],
      ),
    );
  }
}

/// Manual stock positions, fractional share lots, price history, and portfolio chart — feeds net worth.
class PlanStocksScreen extends StatefulWidget {
  const PlanStocksScreen({super.key});

  @override
  State<PlanStocksScreen> createState() => _PlanStocksScreenState();
}

class _PlanStocksScreenState extends State<PlanStocksScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final InvestmentController _inv = Get.find<InvestmentController>();
  int _stocksTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _stocksTabIndex = _tabs.index;
    _tabs.addListener(_onStocksTabChanged);
  }

  void _onStocksTabChanged() {
    if (_tabs.indexIsChanging) return;
    final int i = _tabs.index;
    if (i != _stocksTabIndex) {
      AppHaptics.selection();
      _stocksTabIndex = i;
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onStocksTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _reload() => _inv.reload();

  String _fmtQty(double q) {
    if ((q - q.roundToDouble()).abs() < 1e-9) {
      return '${q.toInt()} shares';
    }
    return '${q.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '')} shares';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: p.textPrimary,
          onPressed: () {
            AppHaptics.light();
            Get.back();
          },
        ),
        title: Text(
          'Investments',
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: p.textPrimary,
                letterSpacing: -0.4,
              ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kInvestAccent,
          dividerColor: Colors.transparent,
          dividerHeight: 0,
          labelColor: p.textPrimary,
          unselectedLabelColor: p.textSecondary,
          tabs: const <Widget>[
            Tab(text: 'Holdings'),
            Tab(text: 'Other investments'),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: MidnightGridPainter(heightFraction: 1.0, gridLineColor: p.gridLine),
            ),
          ),
          SafeArea(
            top: false,
            child: TabBarView(
              controller: _tabs,
              children: <Widget>[
                _buildHoldingsTab(context, p),
                _buildOtherInvestmentsTab(context, p),
              ],
            ),
          ),
        ],
      ),
      // Use [ListenableBuilder], not [Obx]: tab index comes from [TabController], not GetX.
      floatingActionButton: ListenableBuilder(
        listenable: _tabs,
        builder: (BuildContext context, Widget? child) {
          if (_tabs.index == 0) {
            return FloatingActionButton(
              onPressed: () {
                AppHaptics.light();
                _showAddHoldingSheet(context, p);
              },
              backgroundColor: p.mint,
              foregroundColor: const Color(0xFF0D1117),
              child: const Icon(Icons.add_rounded),
            );
          }
          if (_tabs.index == 1) {
            return FloatingActionButton(
              onPressed: () {
                AppHaptics.light();
                _showOtherInvestmentSheet(context, p, null);
              },
              backgroundColor: _kInvestAccent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHoldingsTab(BuildContext context, AppPalette p) {
    return Obx(() {
      if (_inv.loading.value && _inv.holdings.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: _reload,
        color: _kInvestAccent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (_inv.holdings.isNotEmpty) ...<Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                sliver: SliverToBoxAdapter(child: _PortfolioSummary(p: p, inv: _inv)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: _PortfolioChart(p: p, inv: _inv)),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 8), sliver: SliverToBoxAdapter(child: SizedBox())),
            ],
            if (_inv.holdings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: EmptyState(
                    icon: Icon(Icons.inventory_2_outlined, size: 40, color: p.mint.withValues(alpha: 0.6)),
                    primaryText: Text(
                      'No positions yet',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(color: p.textPrimary),
                    ),
                    secondaryText: Text(
                      'Add a ticker, log fractional shares over time, and enter prices manually to track value and growth.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: p.textSecondary, height: 1.4),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int i) {
                      final InvestmentHolding h = _inv.holdings[i];
                      final HoldingRowData? row = _inv.rowByHoldingId[h.id];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Slidable(
                          key: ValueKey<String>('holding_${h.id}'),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: <Widget>[
                              SlidableAction(
                                onPressed: (_) async {
                                  AppHaptics.light();
                                  final bool? ok = await Get.dialog<bool>(
                                    AlertDialog(
                                      title: const Text('Remove holding?'),
                                      content: Text('Delete ${h.ticker} and all its history?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            AppHaptics.light();
                                            Get.back(result: false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            AppHaptics.medium();
                                            Get.back(result: true);
                                          },
                                          child: Text('Delete', style: TextStyle(color: p.coral)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await inv.deleteInvestmentHolding(h.id);
                                    await _reload();
                                  }
                                },
                                backgroundColor: p.coral.withValues(alpha: 0.25),
                                foregroundColor: p.coral,
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: SlidablePeekHint(
                            storageKey: AppConstants.SLIDABLE_PEEK_INVESTMENTS,
                            enabled: i == 0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  AppHaptics.light();
                                  _showHoldingDetailSheet(context, p, h);
                                },
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: p.surface.withValues(alpha: 0.85),
                                    border: Border.all(color: p.border.withValues(alpha: 0.6)),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      CircleAvatar(
                                        backgroundColor: p.surfaceElevated,
                                        child: Text(
                                          h.ticker.length <= 4 ? h.ticker : h.ticker.substring(0, 4),
                                          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                                color: _kInvestAccent,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              h.ticker,
                                              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                                    color: p.textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            Text(
                                              h.displayName.isEmpty ? '—' : h.displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: p.textSecondary),
                                            ),
                                            if (row != null)
                                              Text(
                                                _fmtQty(row.quantity),
                                                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: p.textSecondary),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: <Widget>[
                                          DualCurrencyTotal(
                                            lcyMinor: row?.valueMinor ?? 0,
                                            textAlign: TextAlign.end,
                                            compactSecondary: true,
                                            primaryStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                                                  color: p.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                            secondaryStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                                                  color: p.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          if (row != null && row.deltaMinor != null && row.deltaPct != null)
                                            Text(
                                              'P/L ${row.deltaMinor! >= 0 ? '+' : '−'}${formatAmount(row.deltaMinor!.abs())} '
                                              '(${row.deltaPct! >= 0 ? '+' : ''}${row.deltaPct!.toStringAsFixed(2)}% vs cost)',
                                              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                                    color: row.deltaMinor! >= 0 ? p.mint : p.coral,
                                                  ),
                                            )
                                          else
                                            Text(
                                              '—',
                                              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: p.textSecondary),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _inv.holdings.length,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildOtherInvestmentsTab(BuildContext context, AppPalette p) {
    return Obx(() {
      if (_inv.loading.value && _inv.otherInvestments.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: _reload,
        color: _kInvestAccent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (_inv.otherInvestments.isNotEmpty) ...<Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                sliver: SliverToBoxAdapter(child: _OtherInvestmentsSummary(p: p, inv: _inv)),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 4), sliver: SliverToBoxAdapter(child: SizedBox())),
            ],
            if (_inv.otherInvestments.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: EmptyState(
                    icon: Icon(Icons.savings_outlined, size: 40, color: p.mint.withValues(alpha: 0.6)),
                    primaryText: Text(
                      'No other investments yet',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(color: p.textPrimary),
                    ),
                    secondaryText: Text(
                      'Add cash, land, gold, or anything else. Each line is converted to your local currency and included in net worth.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: p.textSecondary, height: 1.45),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int i) {
                      final OtherInvestment o = _inv.otherInvestments[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Slidable(
                          key: ValueKey<String>('other_invest_${o.id}'),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: <Widget>[
                              SlidableAction(
                                onPressed: (_) async {
                                  AppHaptics.light();
                                  final bool? ok = await Get.dialog<bool>(
                                    AlertDialog(
                                      title: const Text('Remove item?'),
                                      content: Text('Delete “${o.label}”?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            AppHaptics.light();
                                            Get.back(result: false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            AppHaptics.medium();
                                            Get.back(result: true);
                                          },
                                          child: Text('Delete', style: TextStyle(color: p.coral)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await _inv.deleteOtherInvestment(o.id);
                                  }
                                },
                                backgroundColor: p.coral.withValues(alpha: 0.25),
                                foregroundColor: p.coral,
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: SlidablePeekHint(
                            storageKey: AppConstants.SLIDABLE_PEEK_INVESTMENTS_OTHER,
                            enabled: i == 0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  AppHaptics.light();
                                  _showOtherInvestmentSheet(context, p, o);
                                },
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: p.surface.withValues(alpha: 0.85),
                                    border: Border.all(color: p.border.withValues(alpha: 0.6)),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Icon(Icons.account_balance_wallet_outlined, color: _kInvestAccent, size: 26),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              o.label.isEmpty ? '—' : o.label,
                                              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                                    color: p.textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            Obx(() {
                                              final CurrencyController c = Get.find<CurrencyController>();
                                              if (o.entryIsFcy) {
                                                return Text(
                                                  '${formatMinorUnits(o.entryMinor, c.fcyCode.value)} • ${formatAmount(o.valueLcyMinor)}',
                                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: p.textSecondary),
                                                );
                                              }
                                              return Text(
                                                formatAmount(o.valueLcyMinor),
                                                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: p.textSecondary),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                      DualCurrencyTotal(
                                        lcyMinor: o.valueLcyMinor,
                                        textAlign: TextAlign.end,
                                        compactSecondary: true,
                                        primaryStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                                              color: p.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                        secondaryStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                                              color: p.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _inv.otherInvestments.length,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Future<void> _showOtherInvestmentSheet(BuildContext context, AppPalette p, OtherInvestment? existing) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: p.overlay,
      builder: (BuildContext ctx) {
        return _floatingModalCard(
          context: ctx,
          palette: p,
          child: ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: <Widget>[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _OtherInvestmentEditorContent(
                palette: p,
                inv: _inv,
                existing: existing,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddHoldingSheet(BuildContext context, AppPalette p) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: p.overlay,
      builder: (BuildContext ctx) {
        return _floatingModalCard(
          context: ctx,
          palette: p,
          child: ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: <Widget>[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _AddHoldingEditorContent(
                palette: p,
                onSave: (String ticker, String displayName) async {
                  await inv.insertInvestmentHolding(ticker: ticker, displayName: displayName);
                },
              ),
            ],
          ),
        );
      },
    );
    await _reload();
  }

  Future<void> _showHoldingDetailSheet(BuildContext context, AppPalette p, InvestmentHolding h) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: p.overlay,
      builder: (BuildContext ctx) {
        return _floatingModalCard(
          context: ctx,
          palette: p,
          child: _HoldingDetailBody(
            holding: h,
            palette: p,
            onChanged: _reload,
            fmtQty: _fmtQty,
          ),
        );
      },
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary({required this.p, required this.inv});

  final AppPalette p;
  final InvestmentController inv;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int total = inv.stocksTotalMinor.value;
      final int d = inv.portfolioDayChangeMinor.value;
      final double? pct = inv.portfolioDayChangePct.value;
      final bool up = d >= 0;
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: p.surface.withValues(alpha: 0.92),
          border: Border.all(color: _kInvestAccent.withValues(alpha: 0.35)),
          boxShadow: <BoxShadow>[
            BoxShadow(color: _kInvestAccent.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Total portfolio value',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(color: p.textSecondary),
                  ),
                ),
                if (pct != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(up ? Icons.north_east_rounded : Icons.south_east_rounded, size: 16, color: up ? p.mint : p.coral),
                          const SizedBox(width: 4),
                          Text(
                            '${up ? '+' : ''}${pct.toStringAsFixed(2)}% (${up ? '+' : '−'}${formatAmount(d.abs())})',
                            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: up ? p.mint : p.coral,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      Text('Today', style: Theme.of(context).textTheme.labelSmall!.copyWith(color: p.textSecondary)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DualCurrencyTotal(
              lcyMinor: total,
              textAlign: TextAlign.start,
              primaryStyle: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
              secondaryStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: p.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Rolls into net worth',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      );
    });
  }
}

class _OtherInvestmentsSummary extends StatelessWidget {
  const _OtherInvestmentsSummary({required this.p, required this.inv});

  final AppPalette p;
  final InvestmentController inv;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int total = inv.otherInvestmentsTotalMinor.value;
      final int n = inv.otherInvestments.length;
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: p.surface.withValues(alpha: 0.92),
          border: Border.all(color: _kInvestAccent.withValues(alpha: 0.35)),
          boxShadow: <BoxShadow>[
            BoxShadow(color: _kInvestAccent.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Total other investments',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 8),
            DualCurrencyTotal(
              lcyMinor: total,
              textAlign: TextAlign.start,
              primaryStyle: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
              secondaryStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: p.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              n == 0
                  ? 'No entries yet • Rolls into net worth'
                  : n == 1
                      ? '1 entry • Rolls into net worth'
                      : '$n entries • Rolls into net worth',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      );
    });
  }
}

class _PortfolioChart extends StatelessWidget {
  const _PortfolioChart({required this.p, required this.inv});

  final AppPalette p;
  final InvestmentController inv;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<({int ms, int valueMinor})> hist = inv.portfolioHistory;
      if (hist.length < 2) {
        return const SizedBox.shrink();
      }
      final List<FlSpot> spots = <FlSpot>[];
      int minV = hist.first.valueMinor;
      int maxV = hist.first.valueMinor;
      for (int i = 0; i < hist.length; i++) {
        final int v = hist[i].valueMinor;
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
        spots.add(FlSpot(i.toDouble(), v / 100.0));
      }
      final double minDisplay = minV / 100.0;
      final double maxDisplay = maxV / 100.0;
      final double range = maxDisplay - minDisplay;
      const double headroomFrac = 0.08;
      final double minY;
      final double maxY;
      if (range <= 1e-9) {
        if (maxDisplay <= 0) {
          minY = maxDisplay - 1;
          maxY = maxDisplay + 1;
        } else {
          minY = 0;
          maxY = math.max(maxDisplay * 1.1, maxDisplay + 1);
        }
      } else {
        if (minDisplay >= 0) {
          minY = 0;
        } else {
          minY = minDisplay - range * headroomFrac;
        }
        maxY = maxDisplay + math.max(range * headroomFrac, maxDisplay.abs() * 0.02 + 1e-6);
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Portfolio value over time',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: p.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY - minY) / 4),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: TextStyle(color: p.textSecondary, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: math.max(1, (spots.length / 5).floorToDouble()),
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int i = value.round();
                          if (i < 0 || i >= hist.length) return const SizedBox.shrink();
                          final DateTime d = DateTime.fromMillisecondsSinceEpoch(hist[i].ms);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat.Md().format(d),
                              style: TextStyle(color: p.textSecondary, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: <LineChartBarData>[
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: _kInvestAccent,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _kInvestAccent.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _HoldingDetailBody extends StatefulWidget {
  const _HoldingDetailBody({
    required this.holding,
    required this.palette,
    required this.onChanged,
    required this.fmtQty,
  });

  final InvestmentHolding holding;
  final AppPalette palette;
  final Future<void> Function() onChanged;
  final String Function(double q) fmtQty;

  @override
  State<_HoldingDetailBody> createState() => _HoldingDetailBodyState();
}

class _HoldingDetailBodyState extends State<_HoldingDetailBody> {
  List<InvestmentLotEntry> _lots = <InvestmentLotEntry>[];
  List<InvestmentPricePoint> _prices = <InvestmentPricePoint>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final List<InvestmentLotEntry> l = await inv.listLotsForHolding(widget.holding.id);
    final List<InvestmentPricePoint> pr = await inv.listPricePointsForHolding(widget.holding.id);
    if (mounted) {
      setState(() {
        _lots = l;
        _prices = pr;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = widget.palette;
    final double maxSheetHeight = MediaQuery.sizeOf(context).height * 0.92;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.holding.ticker,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
          ),
          if (widget.holding.displayName.isNotEmpty)
            Text(widget.holding.displayName, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: p.textSecondary)),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.light();
                    _addLot(context);
                  },
                  icon: const Icon(Icons.add_chart_rounded),
                  label: const Text('Add shares'),
                  style: OutlinedButton.styleFrom(foregroundColor: _kInvestAccent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    AppHaptics.light();
                    _addPrice(context);
                  },
                  icon: const Icon(Icons.price_change_outlined),
                  label: const Text('Log price'),
                  style: FilledButton.styleFrom(backgroundColor: _kInvestAccent, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Share lots (purchase price)', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: p.textPrimary)),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_lots.isEmpty)
            Text('No lots yet — add shares with the price you paid per share.', style: TextStyle(color: p.textSecondary))
          else
            ..._lots.map((InvestmentLotEntry e) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${e.quantityDelta >= 0 ? '+' : ''}${e.quantityDelta} shares @ ${formatAmount(e.purchasePriceMinorPerShare)}',
                  style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(e.occurredAtMs)),
                      style: TextStyle(color: p.textSecondary),
                    ),
                    if (e.purchaseEntryIsFcy)
                      Obx(
                        () => Text(
                          '${formatMinorUnits(e.purchasePriceEntryMinorPerShare, Get.find<CurrencyController>().fcyCode.value)} per share (entry)',
                          style: TextStyle(color: p.textSecondary.withValues(alpha: 0.9), fontSize: 12),
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close_rounded, color: p.coral, size: 20),
                  onPressed: () async {
                    AppHaptics.light();
                    await inv.deleteInvestmentLot(e.id);
                    await _load();
                    await widget.onChanged();
                  },
                ),
              );
            }),
          const SizedBox(height: 20),
          Text('Market price history (date)', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: p.textPrimary)),
          const SizedBox(height: 8),
          if (!_loading && _prices.isEmpty)
            Text(
              'No market prices — log the current price per share by date to track value and growth.',
              style: TextStyle(color: p.textSecondary),
            )
          else if (!_loading)
            ..._prices.map((InvestmentPricePoint e) {
              final DateTime day = e.asOfDay > 0
                  ? localMidnightFromYyyymmdd(e.asOfDay)
                  : DateTime.fromMillisecondsSinceEpoch(e.asOfMs);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  formatAmount(e.priceMinorPerShare),
                  style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      DateFormat.yMMMd().format(day),
                      style: TextStyle(color: p.textSecondary),
                    ),
                    if (e.entryIsFcy)
                      Obx(
                        () => Text(
                          '${formatMinorUnits(e.priceEntryMinorPerShare, Get.find<CurrencyController>().fcyCode.value)} (entry)',
                          style: TextStyle(color: p.textSecondary.withValues(alpha: 0.9), fontSize: 12),
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close_rounded, color: p.coral, size: 20),
                  onPressed: () async {
                    AppHaptics.light();
                    await inv.deleteInvestmentPricePoint(e.id);
                    await _load();
                    await widget.onChanged();
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _addLot(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: p.overlay,
      builder: (BuildContext ctx) {
        return _floatingModalCard(
          context: ctx,
          palette: p,
          child: ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: <Widget>[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _AddInvestmentLotSheet(
                palette: p,
                holding: widget.holding,
                onCompleted: () async {
                  await _load();
                  await widget.onChanged();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addPrice(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: p.overlay,
      builder: (BuildContext ctx) {
        return _floatingModalCard(
          context: ctx,
          palette: p,
          child: ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: <Widget>[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _LogInvestmentPriceSheet(
                palette: p,
                holding: widget.holding,
                onCompleted: () async {
                  await _load();
                  await widget.onChanged();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  AppPalette get p => widget.palette;
}
