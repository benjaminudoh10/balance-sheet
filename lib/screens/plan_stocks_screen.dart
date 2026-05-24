import 'dart:math' as math;

import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/controllers/investment_controller.dart';
import 'package:balance_sheet/controllers/summary_amounts_privacy_controller.dart';
import 'package:balance_sheet/database/investment_operations.dart' as inv;
import 'package:balance_sheet/investment/investment_days.dart';
import 'package:balance_sheet/models/investment_holding.dart';
import 'package:balance_sheet/models/investment_lot_entry.dart';
import 'package:balance_sheet/models/investment_price_point.dart';
import 'package:balance_sheet/models/other_investment.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/adaptive_card_sliver_list.dart';
import 'package:balance_sheet/widgets/dual_currency_total.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:balance_sheet/widgets/date_range_picker_sheet.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/slidable_peek_hint.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:balance_sheet/utils/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const Color _kInvestAccent = Color(0xFF818CF8);

String _formatShareQtyPlain(double q) {
  if ((q - q.roundToDouble()).abs() < 1e-9) {
    return '${q.toInt()}';
  }
  return q.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Same floating card treatment as the budget planned-item editor.
Widget _floatingModalCard({
  required BuildContext context,
  required AppPalette palette,
  required Widget child,
}) {
  final double inset = MediaQuery.viewInsetsOf(context).bottom;
  return Padding(
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
  );
}

/// Avoid calling [AppSnack.show] synchronously right after [Navigator.pop]: the overlay /
/// [ScaffoldMessenger] can rebuild while the route subtree is still tearing down, which
/// triggers framework assertions on inherited widgets.
void _snackbarAfterRouteSettled(String title, String message) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppSnack.show(title, message);
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
  State<_OtherInvestmentEditorContent> createState() =>
      _OtherInvestmentEditorContentState();
}

class _OtherInvestmentEditorContentState
    extends State<_OtherInvestmentEditorContent> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _amountCtrl;
  late final FocusNode _labelFocus;
  late final FocusNode _amountFocus;
  bool _entryIsFcy = true;
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
              ? ((e.entryIsFcy ? e.entryMinor : e.valueLcyMinor) / 100)
                  .toStringAsFixed(2)
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
      AppSnack.show('Label', 'Enter a short name for this investment.');
      return;
    }
    final int? entryMinor = parseMoneyStringToMinor(_amountCtrl.text);
    if (entryMinor == null || entryMinor <= 0) {
      AppSnack.show('Amount', 'Enter a value greater than zero.');
      return;
    }
    final int lcy =
        _entryIsFcy ? _cur.lcyMinorFromFcyMinor(entryMinor) : entryMinor;
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
    _snackbarAfterRouteSettled(
        'Saved', existing == null ? 'Investment added' : 'Investment updated');
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
            widget.existing == null
                ? 'Add other investment'
                : 'Edit investment',
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(color: p.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Name it (e.g. Cash, Land, Gold) and enter the value in local or foreign currency.',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: p.textSecondary, height: 1.4),
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
              enabledBorder:
                  OutlineInputBorder(borderSide: BorderSide(color: p.border)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _kInvestAccent)),
            ),
            onSubmitted: (_) {
              _amountFocus.requestFocus();
            },
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              final String code =
                  _entryIsFcy ? _cur.fcyCode.value : _cur.lcyCode.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Value ($code)',
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
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
                          ButtonSegment<bool>(
                              value: false, label: Text(_cur.lcyCode.value)),
                          ButtonSegment<bool>(
                              value: true, label: Text(_cur.fcyCode.value)),
                        ],
                        selected: <bool>{_entryIsFcy},
                        onSelectionChanged: (Set<bool> next) {
                          if (next.isEmpty) return;
                          final bool toFcy = next.single;
                          if (toFcy == _entryIsFcy) return;
                          AppHaptics.selection();
                          setState(() {
                            final int m =
                                parseMoneyStringToMinor(_amountCtrl.text) ?? 0;
                            if (m <= 0) {
                              _entryIsFcy = toFcy;
                              return;
                            }
                            if (toFcy) {
                              _amountCtrl.text =
                                  (_cur.fcyMinorFromLcyMinor(m) / 100)
                                      .toStringAsFixed(2);
                              _entryIsFcy = true;
                            } else {
                              _amountCtrl.text =
                                  (_cur.lcyMinorFromFcyMinor(m) / 100)
                                      .toStringAsFixed(2);
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: <TextInputFormatter>[
                      DecimalTextInputFormatter()
                    ],
                    style: TextStyle(color: p.textPrimary),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: p.textSecondary),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: p.border)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _kInvestAccent)),
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
            style: FilledButton.styleFrom(
                backgroundColor: _kInvestAccent, foregroundColor: Colors.white),
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
  State<_AddHoldingEditorContent> createState() =>
      _AddHoldingEditorContentState();
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
      AppSnack.show('Ticker', 'Enter a ticker symbol for this holding.');
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
          Text('Add holding',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: p.textPrimary)),
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
              enabledBorder:
                  OutlineInputBorder(borderSide: BorderSide(color: p.border)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _kInvestAccent)),
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
              enabledBorder:
                  OutlineInputBorder(borderSide: BorderSide(color: p.border)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _kInvestAccent)),
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
  late final TextEditingController _totalPriceCtrl;
  late final TextEditingController _sharePriceCtrl;
  late final FocusNode _qtyFocus;
  late final FocusNode _totalPriceFocus;
  late final FocusNode _sharePriceFocus;
  bool _entryIsFcy = true;
  bool _ignoreChanges = false;

  /// When true, quantity is stored as negative (sale). Avoids relying on `-` on keyboards where `.` and `-` share one key.
  bool _isSale = false;
  late DateTime _purchaseDay;
  final CurrencyController _cur = Get.find<CurrencyController>();

  @override
  void initState() {
    super.initState();
    _qtyFocus = FocusNode();
    _totalPriceFocus = FocusNode();
    _sharePriceFocus = FocusNode();
    _qtyCtrl = TextEditingController();
    _totalPriceCtrl = TextEditingController();
    _sharePriceCtrl = TextEditingController();
    _purchaseDay = DateTime.now();

    _qtyCtrl.addListener(_onQtyChanged);
    _totalPriceCtrl.addListener(_onTotalChanged);
    _sharePriceCtrl.addListener(_onSharePriceChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _qtyFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _qtyFocus.dispose();
    _totalPriceFocus.dispose();
    _sharePriceFocus.dispose();
    _qtyCtrl.dispose();
    _totalPriceCtrl.dispose();
    _sharePriceCtrl.dispose();
    super.dispose();
  }

  void _onQtyChanged() {
    if (_ignoreChanges) return;
    _recalcSharePrice();
  }

  void _onTotalChanged() {
    if (_ignoreChanges) return;
    _recalcSharePrice();
  }

  void _onSharePriceChanged() {
    if (_ignoreChanges) return;
    _recalcQty();
  }

  void _recalcSharePrice() {
    final double? q = double.tryParse(_qtyCtrl.text.replaceAll(',', ''));
    final double? t = double.tryParse(_totalPriceCtrl.text.replaceAll(',', ''));
    if (q != null && t != null && q != 0) {
      _ignoreChanges = true;
      final double sp = t / q;
      _sharePriceCtrl.text =
          sp.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
      _ignoreChanges = false;
    }
  }

  void _recalcQty() {
    final double? sp =
        double.tryParse(_sharePriceCtrl.text.replaceAll(',', ''));
    final double? t = double.tryParse(_totalPriceCtrl.text.replaceAll(',', ''));
    if (sp != null && t != null && sp != 0) {
      _ignoreChanges = true;
      final double q = t / sp;
      _qtyCtrl.text = q.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
      _ignoreChanges = false;
    }
  }

  Future<void> _save() async {
    final double? parsed = double.tryParse(_qtyCtrl.text.replaceAll(',', ''));
    if (parsed == null) {
      AppSnack.show('Quantity', 'Enter a valid quantity.');
      return;
    }
    final double mag = parsed.abs();
    if (mag == 0) {
      AppSnack.show('Quantity', 'Enter a non-zero quantity.');
      return;
    }
    final DateTime atMidnight =
        DateTime(_purchaseDay.year, _purchaseDay.month, _purchaseDay.day);
    final int lotMs = atMidnight.millisecondsSinceEpoch;

    if (_isSale) {
      final double available =
          await inv.totalQuantityForHoldingAtMs(widget.holding.id, lotMs);
      final double maxSell = math.max(0.0, available);
      if (mag > maxSell + 1e-9) {
        if (maxSell <= 1e-9) {
          AppSnack.show(
            'Cannot sell',
            'No shares are available to sell on this date (based on prior lots).',
          );
        } else {
          AppSnack.show(
            'Cannot sell',
            'You have ${_formatShareQtyPlain(maxSell)} shares available on this date; '
                '${_formatShareQtyPlain(mag)} is too many.',
          );
        }
        return;
      }
    }

    final double qty = _isSale ? -mag : mag;
    final int? pxEntryTotal = parseMoneyStringToMinor(_totalPriceCtrl.text);
    if (pxEntryTotal == null) {
      AppSnack.show(
          'Amount required', 'Enter the total amount for this transaction.');
      return;
    }
    if (pxEntryTotal <= 0) {
      AppSnack.show('Amount', 'Enter a total amount greater than zero.');
      return;
    }
    // The user types the total transaction amount; the canonical per-share
    // price is derived from it. Storing per-share keeps the DB schema (and all
    // existing rows from prior app versions) working unchanged.
    final int pxEntryPerShare = (pxEntryTotal / mag).round();
    if (pxEntryPerShare <= 0) {
      AppSnack.show(
        'Amount',
        'Total is too small for this quantity — per-share price rounds to zero.',
      );
      return;
    }
    final int lcyPxPerShare = _entryIsFcy
        ? _cur.lcyMinorFromFcyMinor(pxEntryPerShare)
        : pxEntryPerShare;
    await inv.insertInvestmentLot(
      holdingId: widget.holding.id,
      occurredAtMs: lotMs,
      quantityDelta: qty,
      purchasePriceMinorPerShare: lcyPxPerShare,
      purchaseEntryIsFcy: _entryIsFcy,
      purchasePriceEntryMinorPerShare: pxEntryPerShare,
    );
    // Mirror the derived per-share price into the price log so the holding has
    // a market-price datapoint on the transaction day.
    await inv.insertInvestmentPricePoint(
      holdingId: widget.holding.id,
      asOfDayYyyymmdd: encodeLocalYyyymmdd(_purchaseDay),
      priceMinorPerShare: lcyPxPerShare,
      entryIsFcy: _entryIsFcy,
      priceEntryMinorPerShare: pxEntryPerShare,
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
          Text('Buy / sell shares',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Enter two of Total Price, Quantity, or Share Price; the third will be calculated automatically. Shares and date are saved to your lot history.',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: false, label: Text('Buy')),
              ButtonSegment<bool>(value: true, label: Text('Sell')),
            ],
            selected: <bool>{_isSale},
            onSelectionChanged: (Set<bool> next) {
              if (next.isEmpty) return;
              AppHaptics.selection();
              setState(() {
                _isSale = next.single;
              });
            },
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              selectedBackgroundColor: _kInvestAccent,
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              final String code =
                  _entryIsFcy ? _cur.fcyCode.value : _cur.lcyCode.value;
              final String totalLabel =
                  _isSale ? 'Total sale proceeds' : 'Total purchase price';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '$totalLabel ($code)',
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
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
                          ButtonSegment<bool>(
                              value: false, label: Text(_cur.lcyCode.value)),
                          ButtonSegment<bool>(
                              value: true, label: Text(_cur.fcyCode.value)),
                        ],
                        selected: <bool>{_entryIsFcy},
                        onSelectionChanged: (Set<bool> next) {
                          if (next.isEmpty) return;
                          final bool toFcy = next.single;
                          if (toFcy == _entryIsFcy) return;
                          AppHaptics.selection();
                          setState(() {
                            _ignoreChanges = true;
                            final int totalMinor =
                                parseMoneyStringToMinor(_totalPriceCtrl.text) ??
                                    0;
                            final int shareMinor =
                                parseMoneyStringToMinor(_sharePriceCtrl.text) ??
                                    0;

                            if (toFcy) {
                              if (totalMinor > 0) {
                                _totalPriceCtrl.text =
                                    (_cur.fcyMinorFromLcyMinor(totalMinor) /
                                            100)
                                        .toStringAsFixed(2);
                              }
                              if (shareMinor > 0) {
                                _sharePriceCtrl.text =
                                    (_cur.fcyMinorFromLcyMinor(shareMinor) /
                                            100)
                                        .toStringAsFixed(2);
                              }
                              _entryIsFcy = true;
                            } else {
                              if (totalMinor > 0) {
                                _totalPriceCtrl.text =
                                    (_cur.lcyMinorFromFcyMinor(totalMinor) /
                                            100)
                                        .toStringAsFixed(2);
                              }
                              if (shareMinor > 0) {
                                _sharePriceCtrl.text =
                                    (_cur.lcyMinorFromFcyMinor(shareMinor) /
                                            100)
                                        .toStringAsFixed(2);
                              }
                              _entryIsFcy = false;
                            }
                            _ignoreChanges = false;
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
                    controller: _totalPriceCtrl,
                    focusNode: _totalPriceFocus,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    inputFormatters: <TextInputFormatter>[
                      DecimalTextInputFormatter()
                    ],
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: p.textSecondary),
                    ),
                    onSubmitted: (_) => _qtyFocus.requestFocus(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyCtrl,
            focusNode: _qtyFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.deny(RegExp(r'-')),
              DecimalTextInputFormatter(decimalRange: 8),
            ],
            decoration: const InputDecoration(
              labelText: 'Quantity (fractional ok)',
              hintText: '0',
            ),
            onSubmitted: (_) => _sharePriceFocus.requestFocus(),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final String code =
                _entryIsFcy ? _cur.fcyCode.value : _cur.lcyCode.value;
            return TextField(
              controller: _sharePriceCtrl,
              focusNode: _sharePriceFocus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                DecimalTextInputFormatter()
              ],
              decoration: InputDecoration(
                labelText: 'Price per share ($code)',
                hintText: '0.00',
                hintStyle: TextStyle(color: p.textSecondary),
              ),
              onSubmitted: (_) async {
                AppHaptics.light();
                await _save();
              },
            );
          }),
          const SizedBox(height: 8),
          ListTile(
            title: Text(DateFormat.yMMMd().format(_purchaseDay)),
            subtitle: Text(_isSale ? 'Sale date' : 'Purchase date'),
            trailing: const Icon(Icons.event_rounded),
            onTap: () async {
              AppHaptics.light();
              final DateTime? d = await showAppDatePicker(
                context,
                initialDate: _purchaseDay,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
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
  State<_LogInvestmentPriceSheet> createState() =>
      _LogInvestmentPriceSheetState();
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
      AppSnack.show('Price', 'Enter a value greater than zero.');
      return;
    }
    final int lcyMinor =
        _entryIsFcy ? _cur.lcyMinorFromFcyMinor(entryMinor) : entryMinor;
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
          Text('Market price per share',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'The stock’s price on this calendar day (latest entry wins for current value).',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              final String code =
                  _entryIsFcy ? _cur.fcyCode.value : _cur.lcyCode.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Amount ($code)',
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
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
                          ButtonSegment<bool>(
                              value: false, label: Text(_cur.lcyCode.value)),
                          ButtonSegment<bool>(
                              value: true, label: Text(_cur.fcyCode.value)),
                        ],
                        selected: <bool>{_entryIsFcy},
                        onSelectionChanged: (Set<bool> next) {
                          if (next.isEmpty) return;
                          final bool toFcy = next.single;
                          if (toFcy == _entryIsFcy) return;
                          AppHaptics.selection();
                          setState(() {
                            final int m =
                                parseMoneyStringToMinor(_priceCtrl.text) ?? 0;
                            if (m <= 0) {
                              _entryIsFcy = toFcy;
                              return;
                            }
                            if (toFcy) {
                              _priceCtrl.text =
                                  (_cur.fcyMinorFromLcyMinor(m) / 100)
                                      .toStringAsFixed(2);
                              _entryIsFcy = true;
                            } else {
                              _priceCtrl.text =
                                  (_cur.lcyMinorFromFcyMinor(m) / 100)
                                      .toStringAsFixed(2);
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: <TextInputFormatter>[
                      DecimalTextInputFormatter()
                    ],
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
              final DateTime? d = await showAppDatePicker(
                context,
                initialDate: _priceDay,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
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

class _PlanStocksScreenState extends State<PlanStocksScreen>
    with SingleTickerProviderStateMixin {
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
              painter: MidnightGridPainter(
                  heightFraction: 1.0, gridLineColor: p.gridLine),
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
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double contentWidth = constraints.maxWidth;
          return RefreshIndicator(
            onRefresh: _reload,
            color: _kInvestAccent,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                if (_inv.holdings.isNotEmpty) ...<Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    sliver: SliverToBoxAdapter(
                        child: _PortfolioSummary(p: p, inv: _inv)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                        child: _PortfolioChart(p: p, inv: _inv)),
                  ),
                  const SliverPadding(
                      padding: EdgeInsets.only(top: 8),
                      sliver: SliverToBoxAdapter(child: SizedBox())),
                ],
                if (_inv.holdings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: EmptyState(
                        icon: Icon(Icons.inventory_2_outlined,
                            size: 40, color: p.mint.withValues(alpha: 0.6)),
                        primaryText: Text(
                          'No positions yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(color: p.textPrimary),
                        ),
                        secondaryText: Text(
                          'Add a ticker, log fractional shares over time, and enter prices manually to track value and growth.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: p.textSecondary, height: 1.4),
                        ),
                      ),
                    ),
                  )
                else
                  adaptiveCardListSliver(
                    contentWidth: contentWidth,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: _inv.holdings.length,
                    itemBuilder: (BuildContext context, int i) {
                      final InvestmentHolding h = _inv.holdings[i];
                      final HoldingRowData? row = _inv.rowByHoldingId[h.id];
                      return _HoldingRow(
                        index: i,
                        holding: h,
                        rowData: row,
                        onTap: () {
                          AppHaptics.light();
                          _showHoldingDetailSheet(context, p, h);
                        },
                        onDelete: () async {
                          AppHaptics.light();
                          final bool? ok = await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Remove holding?'),
                              content: Text(
                                  'Delete ${h.ticker} and all its history?'),
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
                                  child: Text('Delete',
                                      style: TextStyle(color: p.coral)),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await inv.deleteInvestmentHolding(h.id);
                            await _reload();
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildOtherInvestmentsTab(BuildContext context, AppPalette p) {
    return Obx(() {
      if (_inv.loading.value && _inv.otherInvestments.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double contentWidth = constraints.maxWidth;
          return RefreshIndicator(
            onRefresh: _reload,
            color: _kInvestAccent,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                if (_inv.otherInvestments.isNotEmpty) ...<Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    sliver: SliverToBoxAdapter(
                        child: _OtherInvestmentsSummary(p: p, inv: _inv)),
                  ),
                  const SliverPadding(
                      padding: EdgeInsets.only(top: 4),
                      sliver: SliverToBoxAdapter(child: SizedBox())),
                ],
                if (_inv.otherInvestments.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: EmptyState(
                        icon: Icon(Icons.savings_outlined,
                            size: 40, color: p.mint.withValues(alpha: 0.6)),
                        primaryText: Text(
                          'No other investments yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(color: p.textPrimary),
                        ),
                        secondaryText: Text(
                          'Add cash, land, gold, or anything else. Each line is converted to your local currency and included in net worth.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: p.textSecondary, height: 1.45),
                        ),
                      ),
                    ),
                  )
                else
                  adaptiveCardListSliver(
                    contentWidth: contentWidth,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: _inv.otherInvestments.length,
                    itemBuilder: (BuildContext context, int i) {
                      final OtherInvestment o = _inv.otherInvestments[i];
                      return _OtherInvestmentRow(
                        index: i,
                        investment: o,
                        onTap: () {
                          AppHaptics.light();
                          _showOtherInvestmentSheet(context, p, o);
                        },
                        onDelete: () async {
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
                                  child: Text('Delete',
                                      style: TextStyle(color: p.coral)),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await _inv.deleteOtherInvestment(o.id);
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  Future<void> _showOtherInvestmentSheet(
      BuildContext context, AppPalette p, OtherInvestment? existing) async {
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
                  await inv.insertInvestmentHolding(
                      ticker: ticker, displayName: displayName);
                },
              ),
            ],
          ),
        );
      },
    );
    await _reload();
  }

  Future<void> _showHoldingDetailSheet(
      BuildContext context, AppPalette p, InvestmentHolding h) async {
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
      final SummaryAmountsPrivacyController priv =
          Get.find<SummaryAmountsPrivacyController>();
      final bool showAmt = priv.showInvestmentSummaryAmounts.value;
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
            BoxShadow(
                color: _kInvestAccent.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Total portfolio value',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(color: p.textSecondary),
                  ),
                ),
                if (pct != null)
                  showAmt
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                    up
                                        ? Icons.north_east_rounded
                                        : Icons.south_east_rounded,
                                    size: 16,
                                    color: up ? p.mint : p.coral),
                                const SizedBox(width: 4),
                                Text(
                                  '${up ? '+' : ''}${pct.toStringAsFixed(2)}% (${up ? '+' : '−'}${formatMinorUnits(Get.find<CurrencyController>().fcyMinorFromLcyMinor(d.abs()), Get.find<CurrencyController>().fcyCode.value)})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        color: up ? p.mint : p.coral,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            Text('Today',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(color: p.textSecondary)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                    up
                                        ? Icons.north_east_rounded
                                        : Icons.south_east_rounded,
                                    size: 16,
                                    color: up ? p.mint : p.coral),
                                const SizedBox(width: 4),
                                Text(
                                  '****',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        color: up ? p.mint : p.coral,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2,
                                      ),
                                ),
                              ],
                            ),
                            Text('Today',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(color: p.textSecondary)),
                          ],
                        ),
                IconButton(
                  tooltip: showAmt ? 'Hide amounts' : 'Show amounts',
                  onPressed: () {
                    AppHaptics.light();
                    priv.toggleInvestmentSummaryAmounts();
                  },
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    showAmt
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                    color: p.textSecondary.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DualCurrencyTotal(
              lcyMinor: total,
              textAlign: TextAlign.start,
              obscureAmount: !showAmt,
              useFcyAsPrimary: true,
              primaryStyle:
                  Theme.of(context).textTheme.headlineMedium!.copyWith(
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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: p.textSecondary),
            ),
          ],
        ),
      );
    });
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.index,
    required this.holding,
    required this.rowData,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final InvestmentHolding holding;
  final HoldingRowData? rowData;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _fmtQty(double q) {
    if ((q - q.roundToDouble()).abs() < 1e-9) {
      return '${q.toInt()} shares';
    }
    return '${q.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '')} shares';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);

    return Slidable(
      key: ValueKey<String>('holding_${holding.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: <Widget>[
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: p.coral.withValues(alpha: 0.25),
            foregroundColor: p.coral,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
          ),
        ],
      ),
      child: SlidablePeekHint(
        storageKey: AppConstants.SLIDABLE_PEEK_INVESTMENTS,
        enabled: index == 0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
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
                      holding.ticker.length <= 4
                          ? holding.ticker
                          : holding.ticker.substring(0, 4),
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
                          holding.ticker,
                          style:
                              Theme.of(context).textTheme.titleSmall!.copyWith(
                                    color: p.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          holding.displayName.isEmpty
                              ? '—'
                              : holding.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: p.textSecondary),
                        ),
                        if (rowData != null)
                          Text(
                            _fmtQty(rowData!.quantity),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(color: p.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      DualCurrencyTotal(
                        lcyMinor: rowData?.valueMinor ?? 0,
                        textAlign: TextAlign.end,
                        compactSecondary: true,
                        useFcyAsPrimary: true,
                        primaryStyle:
                            Theme.of(context).textTheme.titleSmall!.copyWith(
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                        secondaryStyle:
                            Theme.of(context).textTheme.labelSmall!.copyWith(
                                  color: p.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                      if (rowData != null &&
                          rowData!.deltaMinor != null &&
                          rowData!.deltaPct != null)
                        Obx(() {
                          final CurrencyController c =
                              Get.find<CurrencyController>();
                          final int absFcy = c
                              .fcyMinorFromLcyMinor(rowData!.deltaMinor!.abs());
                          return Text(
                            'P/L ${rowData!.deltaMinor! >= 0 ? '+' : '−'}${formatMinorUnits(absFcy, c.fcyCode.value)} '
                            '(${rowData!.deltaPct! >= 0 ? '+' : ''}${rowData!.deltaPct!.toStringAsFixed(2)}% vs cost)',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: rowData!.deltaMinor! >= 0
                                      ? p.mint
                                      : p.coral,
                                ),
                          );
                        })
                      else
                        Text(
                          '—',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall!
                              .copyWith(color: p.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtherInvestmentRow extends StatelessWidget {
  const _OtherInvestmentRow({
    required this.index,
    required this.investment,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final OtherInvestment investment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);

    return Slidable(
      key: ValueKey<String>('other_invest_${investment.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: <Widget>[
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: p.coral.withValues(alpha: 0.25),
            foregroundColor: p.coral,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
          ),
        ],
      ),
      child: SlidablePeekHint(
        storageKey: AppConstants.SLIDABLE_PEEK_INVESTMENTS_OTHER,
        enabled: index == 0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: p.surface.withValues(alpha: 0.85),
                border: Border.all(color: p.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.account_balance_wallet_outlined,
                      color: _kInvestAccent, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          investment.label.isEmpty ? '—' : investment.label,
                          style:
                              Theme.of(context).textTheme.titleSmall!.copyWith(
                                    color: p.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Obx(() {
                          final CurrencyController c =
                              Get.find<CurrencyController>();
                          final int fcy =
                              c.fcyMinorFromLcyMinor(investment.valueLcyMinor);
                          if (investment.entryIsFcy) {
                            return Text(
                              '${formatMinorUnits(investment.entryMinor, c.fcyCode.value)} • ${formatMinorUnits(investment.valueLcyMinor, c.lcyCode.value)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(color: p.textSecondary),
                            );
                          }
                          return Text(
                            formatMinorUnits(fcy, c.fcyCode.value),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: p.textSecondary),
                          );
                        }),
                      ],
                    ),
                  ),
                  DualCurrencyTotal(
                    lcyMinor: investment.valueLcyMinor,
                    textAlign: TextAlign.end,
                    compactSecondary: true,
                    useFcyAsPrimary: true,
                    primaryStyle:
                        Theme.of(context).textTheme.titleSmall!.copyWith(
                              color: p.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                    secondaryStyle:
                        Theme.of(context).textTheme.labelSmall!.copyWith(
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
    );
  }
}

class _OtherInvestmentsSummary extends StatelessWidget {
  const _OtherInvestmentsSummary({required this.p, required this.inv});

  final AppPalette p;
  final InvestmentController inv;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SummaryAmountsPrivacyController priv =
          Get.find<SummaryAmountsPrivacyController>();
      final bool showAmt = priv.showInvestmentSummaryAmounts.value;
      final int total = inv.otherInvestmentsTotalMinor.value;
      final int n = inv.otherInvestments.length;
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: p.surface.withValues(alpha: 0.92),
          border: Border.all(color: _kInvestAccent.withValues(alpha: 0.35)),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: _kInvestAccent.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Total other investments',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(color: p.textSecondary),
                  ),
                ),
                IconButton(
                  tooltip: showAmt ? 'Hide amounts' : 'Show amounts',
                  onPressed: () {
                    AppHaptics.light();
                    priv.toggleInvestmentSummaryAmounts();
                  },
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    showAmt
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                    color: p.textSecondary.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DualCurrencyTotal(
              lcyMinor: total,
              textAlign: TextAlign.start,
              obscureAmount: !showAmt,
              useFcyAsPrimary: true,
              primaryStyle:
                  Theme.of(context).textTheme.headlineMedium!.copyWith(
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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: p.textSecondary),
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
        maxY = maxDisplay +
            math.max(range * headroomFrac, maxDisplay.abs() * 0.02 + 1e-6);
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Portfolio value over time',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: p.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (maxY - minY) / 4),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style:
                                TextStyle(color: p.textSecondary, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval:
                            math.max(1, (spots.length / 5).floorToDouble()),
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int i = value.round();
                          if (i < 0 || i >= hist.length) {
                            return const SizedBox.shrink();
                          }
                          final DateTime d =
                              DateTime.fromMillisecondsSinceEpoch(hist[i].ms);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat.Md().format(d),
                              style: TextStyle(
                                  color: p.textSecondary, fontSize: 10),
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

class _HoldingDetailBodyState extends State<_HoldingDetailBody>
    with SingleTickerProviderStateMixin {
  List<InvestmentLotEntry> _lots = <InvestmentLotEntry>[];
  List<InvestmentPricePoint> _prices = <InvestmentPricePoint>[];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final List<InvestmentLotEntry> l =
        await inv.listLotsForHolding(widget.holding.id);
    final List<InvestmentPricePoint> pr =
        await inv.listPricePointsForHolding(widget.holding.id);
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
    final double maxSheetHeight = MediaQuery.sizeOf(context).height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: DraggableScrollableSheet(
        expand: false,
        snap: true,
        initialChildSize: 1.0,
        minChildSize: 0,
        maxChildSize: 1.0,
        snapAnimationDuration: const Duration(milliseconds: 220),
        builder: (BuildContext context, ScrollController scrollController) {
          return CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: p.border,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.holding.ticker,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                color: p.textPrimary,
                                fontWeight: FontWeight.w800),
                      ),
                      if (widget.holding.displayName.isNotEmpty)
                        Text(widget.holding.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: p.textSecondary)),
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
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: _kInvestAccent),
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
                              style: FilledButton.styleFrom(
                                  backgroundColor: _kInvestAccent,
                                  foregroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverAppBar(
                pinned: true,
                primary: false,
                automaticallyImplyLeading: false,
                backgroundColor: p.background,
                surfaceTintColor: Colors.transparent,
                toolbarHeight: 0,
                bottom: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorColor: _kInvestAccent,
                  labelColor: _kInvestAccent,
                  unselectedLabelColor: p.textSecondary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Share Lots'),
                    Tab(text: 'Market Prices'),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLotsList(p),
                    _buildPricesList(p),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLotsList(AppPalette p) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_lots.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No lots yet — add shares with the price you paid per share.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: _lots.length,
      itemBuilder: (context, i) {
        final InvestmentLotEntry e = _lots[i];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Obx(() {
            final CurrencyController c = Get.find<CurrencyController>();
            final int fcy =
                c.fcyMinorFromLcyMinor(e.purchasePriceMinorPerShare);
            return Text(
              '${e.quantityDelta >= 0 ? '+' : ''}${e.quantityDelta} shares @ ${formatMinorUnits(fcy, c.fcyCode.value)}',
              style:
                  TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
            );
          }),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                DateFormat.yMMMd().format(
                    DateTime.fromMillisecondsSinceEpoch(e.occurredAtMs)),
                style: TextStyle(color: p.textSecondary),
              ),
              if (e.purchaseEntryIsFcy)
                Obx(
                  () => Text(
                    '${formatMinorUnits(e.purchasePriceEntryMinorPerShare, Get.find<CurrencyController>().fcyCode.value)} per share (entry)',
                    style: TextStyle(
                        color: p.textSecondary.withValues(alpha: 0.9),
                        fontSize: 12),
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
      },
    );
  }

  Widget _buildPricesList(AppPalette p) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_prices.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No market prices — log the current price per share by date to track value and growth.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: _prices.length,
      itemBuilder: (context, i) {
        final InvestmentPricePoint e = _prices[i];
        final DateTime day = e.asOfDay > 0
            ? localMidnightFromYyyymmdd(e.asOfDay)
            : DateTime.fromMillisecondsSinceEpoch(e.asOfMs);
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Obx(() {
            final CurrencyController c = Get.find<CurrencyController>();
            final int fcy = c.fcyMinorFromLcyMinor(e.priceMinorPerShare);
            return Text(
              formatMinorUnits(fcy, c.fcyCode.value),
              style:
                  TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
            );
          }),
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
                    style: TextStyle(
                        color: p.textSecondary.withValues(alpha: 0.9),
                        fontSize: 12),
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
      },
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
