import 'dart:math' as math;

import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/widgets/category_pill_label.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({this.decimalRange = 2})
    : assert(decimalRange > 0);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String value = newValue.text;
    String truncated = value;

    if (value.startsWith(".")) {
      truncated = "0$value";
    } else if (".".allMatches(value).length == 2) {
      // catch double fullstop
      truncated = value.replaceFirst(RegExp('.'), '', value.lastIndexOf("."));
    } else if (value.contains(".") &&
        value.substring(value.indexOf(".") + 1).length > decimalRange) {
      truncated = formatNewValue(value);
    } else if (value == ".") {
      truncated = "0.";
    }

    late TextSelection selection;
    late TextRange composing;

    if (truncated == value) {
      // No transform: keep caret / selection where the user put it.
      final sel = newValue.selection;
      final int len = truncated.length;
      selection = TextSelection(
        baseOffset: sel.baseOffset.clamp(0, len),
        extentOffset: sel.extentOffset.clamp(0, len),
      );
      composing = newValue.composing;
    } else if (value.startsWith(".") && truncated == "0$value") {
      // Inserted one leading zero: shift selection by +1.
      final sel = newValue.selection;
      final int len = truncated.length;
      selection = TextSelection(
        baseOffset: (sel.baseOffset + 1).clamp(0, len),
        extentOffset: (sel.extentOffset + 1).clamp(0, len),
      );
      composing = TextRange.empty;
    } else if (value == "." && truncated == "0.") {
      selection = const TextSelection.collapsed(offset: 2);
      composing = TextRange.empty;
    } else {
      // Text length changed (duplicate dot, formatNewValue, etc.): nudge caret by length delta.
      final int len = truncated.length;
      int base = newValue.selection.baseOffset;
      final int delta = len - value.length;
      base = (base + delta).clamp(0, len);
      selection = TextSelection.collapsed(offset: base);
      composing = TextRange.empty;
    }

    final stripped = _stripLeadingZerosFromAmount(truncated);
    String out = stripped.$1;
    final int removedPrefix = stripped.$2;
    if (removedPrefix > 0) {
      final int len = out.length;
      selection = TextSelection(
        baseOffset: (selection.baseOffset - removedPrefix).clamp(0, len),
        extentOffset: (selection.extentOffset - removedPrefix).clamp(0, len),
      );
      composing = TextRange.empty;
    }

    return TextEditingValue(
      text: out,
      selection: selection,
      composing: composing,
    );
  }

  /// Drops redundant leading zeros (e.g. `012` → `12`, `00.5` → `0.5`); keeps a single `0` before `.` for values &lt; 1.
  (String, int) _stripLeadingZerosFromAmount(String input) {
    if (input.isEmpty) return ('', 0);
    final int dot = input.indexOf('.');
    late final String result;
    late final int removed;
    if (dot >= 0) {
      String intPart = input.substring(0, dot);
      final String frac = input.substring(dot);
      final int origIntLen = intPart.length;
      intPart = intPart.replaceFirst(RegExp(r'^0+'), '');
      if (intPart.isEmpty) intPart = '0';
      removed = origIntLen - intPart.length;
      result = '$intPart$frac';
    } else {
      final int origLen = input.length;
      String s = input.replaceFirst(RegExp(r'^0+'), '');
      if (s.isEmpty) s = '0';
      removed = origLen - s.length;
      result = s;
    }
    return (result, removed);
  }

  String formatNewValue(String newValue) {
    // this gives some form of accuracy
    // 0.045 becomes 0.45 not 0.49999999999...
    String num = (double.parse(newValue) * 1000 / 100).toStringAsFixed(2);
    return num;
  }
}

/// LCY/FCY control for transaction amount — place on the same row as the amount field label.
class TransactionAmountCurrencySelector extends StatelessWidget {
  const TransactionAmountCurrencySelector({
    super.key,
    this.isIncome,
  });

  /// `true` = income (mint), `false` = expense (coral). `null` = outflow-only styling (coral), e.g. budget.
  final bool? isIncome;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final CurrencyController currency = Get.find<CurrencyController>();
    final TransactionController tx = Get.find<TransactionController>();
    final Color flowAccent =
        isIncome == null ? p.coral : (isIncome! ? p.mint : p.coral);
    final Color selectedOnAccent =
        isIncome == null ? Colors.white : (isIncome! ? const Color(0xFF0D1117) : Colors.white);
    return Obx(() {
      final bool fcy = tx.amountEntryIsFcy.value;
      final String lCode = currency.lcyCode.value;
      final String fCode = currency.fcyCode.value;
      return SegmentedButton<bool>(
        segments: <ButtonSegment<bool>>[
          ButtonSegment<bool>(
            value: false,
            label: Text(lCode),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text(fCode),
          ),
        ],
        selected: <bool>{fcy},
        onSelectionChanged: (Set<bool> next) {
          if (next.isEmpty) return;
          final bool toFcy = next.single;
          if (toFcy == fcy) return;
          AppHaptics.selection();
          tx.toggleAmountEntryCurrency();
        },
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: p.surface,
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.border),
          selectedBackgroundColor: flowAccent,
          selectedForegroundColor: selectedOnAccent,
        ),
      );
    });
  }
}

class AmountInput extends StatelessWidget {
  AmountInput({
    super.key,
    this.compact = false,
    this.isIncome,
  });

  /// When true, removes vertical margin for stacked forms (e.g. bottom sheet).
  final bool compact;

  /// `true` = income (mint), `false` = expense (coral). `null` = outflow-only styling (coral), e.g. budget.
  final bool? isIncome;

  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final Color flowAccent =
        isIncome == null ? p.coral : (isIncome! ? p.mint : p.coral);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(10.0),
        color: p.surface,
      ),
      margin: EdgeInsets.symmetric(
        vertical: compact ? 0.0 : 10.0,
      ),
      child: TextField(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(compact ? 8.0 : 10.0),
          hintText: "0.00",
          hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: p.textSecondary,
              ),
          border: InputBorder.none,
        ),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: p.textPrimary,
            ),
        cursorColor: flowAccent,
        controller: _transactionController.amountController.value,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [DecimalTextInputFormatter()],
        onChanged: _transactionController.applyAmountFieldText,
      ),
    );
  }
}

class CategoryInput extends StatelessWidget {
  CategoryInput({super.key, this.compact = false});

  /// When true, tighter padding and no margin — aligns with adjacent icon buttons.
  final bool compact;

  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final AppPalette p = AppPalette.of(context);
      final List<Map<String, Object>> list = Categories.CATEGORIES;
      final List<String> keys =
          list.map((c) => c['key']! as String).toList(growable: false);
      final String raw = _transactionController.category.value;
      final String value = keys.contains(raw) ? raw : keys.first;
      if (!keys.contains(raw)) {
        Future.microtask(() {
          _transactionController.category.value = value;
        });
      }

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(10.0),
          color: p.surface,
        ),
        width: compact ? double.infinity : Get.width,
        padding: EdgeInsets.fromLTRB(
          compact ? 9.0 : 10.0,
          compact ? 10.0 : 10.0,
          compact ? 7.0 : 9.0,
          compact ? 10.0 : 10.0,
        ),
        margin: EdgeInsets.symmetric(
          vertical: compact ? 0.0 : 10.0,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: false,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: p.textSecondary,
              size: 22,
            ),
            dropdownColor: p.background,
            borderRadius: BorderRadius.circular(14.0),
            itemHeight: null,
            menuMaxHeight: 300,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontWeight: FontWeight.w600,
            ),
            selectedItemBuilder: (BuildContext context) {
              return list.map((c) {
                final String k = c['key']! as String;
                final String lbl = c['label']! as String;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: CategoryPillLabel(categoryKey: k, label: lbl),
                );
              }).toList();
            },
            items: list.map((c) {
              final String k = c['key']! as String;
              final String lbl = c['label']! as String;
              return DropdownMenuItem<String>(
                value: k,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: CategoryPillLabel(categoryKey: k, label: lbl),
                ),
              );
            }).toList(),
            onChanged: (String? v) {
              if (v == null) return;
              AppHaptics.selection();
              _transactionController.category.value = v;
            },
          ),
        ),
      );
    });
  }
}

/// Category dropdown for **All transactions** — same pill styling as [CategoryInput], bound to [ReportController].
class ReportCategoryDropdown extends StatelessWidget {
  ReportCategoryDropdown({super.key, required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final AppPalette p = AppPalette.of(context);
      final List<Map<String, Object>> list = Categories.CATEGORIES;
      final List<String> keys =
          list.map((c) => c['key']! as String).toList(growable: false);
      final String raw = controller.category.value;
      final bool isPlaceholder = raw == 'Category';
      final String? value =
          isPlaceholder ? null : (keys.contains(raw) ? raw : null);
      if (!isPlaceholder && !keys.contains(raw)) {
        Future.microtask(() {
          controller.category.value = 'Category';
        });
      }

      final CategoryPillStyle? pill = isPlaceholder
          ? null
          : Categories.pillStyleForKey(value!, Theme.of(context).brightness);

      final Color hintAndIconColor = isPlaceholder
          ? p.textSecondary
          : pill!.foreground;

      final String displayLabel = isPlaceholder
          ? 'Category'
          : (() {
              final int i = keys.indexOf(value!);
              return i >= 0 ? list[i]['label']! as String : 'Category';
            })();

      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isPlaceholder ? p.border : pill!.border,
          ),
          borderRadius: BorderRadius.circular(20.0),
          color: isPlaceholder ? p.surface : pill!.background,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          splashRadius: 20,
          color: p.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          onSelected: (String v) {
            AppHaptics.selection();
            controller.category.value = v;
          },
          itemBuilder: (BuildContext context) {
            return list.map((c) {
              final String k = c['key']! as String;
              final String lbl = c['label']! as String;
              return PopupMenuItem<String>(
                value: k,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: CategoryPillLabel(categoryKey: k, label: lbl),
              );
            }).toList();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlaceholder
                    ? Icons.category_outlined
                    : Categories.iconForKey(value!),
                size: 18,
                color: hintAndIconColor,
              ),
              const SizedBox(width: 6),
              Text(
                displayLabel,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hintAndIconColor,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class DescriptionInput extends StatelessWidget {
  DescriptionInput({super.key, this.compact = false});

  /// When true, removes vertical margin for stacked forms (e.g. bottom sheet).
  final bool compact;

  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(10.0),
        color: p.surface,
      ),
      margin: EdgeInsets.symmetric(
        vertical: compact ? 0.0 : 10.0,
      ),
      child: TextField(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(compact ? 8.0 : 10.0),
          hintText: "e.g. Tomatoes",
          hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: p.textSecondary,
          ),
          border: InputBorder.none,
        ),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: p.textPrimary,
        ),
        cursorColor: p.mint,
        controller: _transactionController.descController.value,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.sentences,
        autofocus: true,
        onChanged: (value) {
          _transactionController.description.value = value.trim();
        },
      ),
    );
  }
}

class ContactInput extends StatelessWidget {
  ContactInput({super.key, this.compact = false});

  /// When true (e.g. Accounts composer dock), removes extra vertical margin for alignment with adjacent controls.
  final bool compact;

  final ContactController _contactController = Get.find();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final double radius = compact ? 24.0 : 12.0;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(radius),
        color: p.surface,
      ),
      margin: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        textAlignVertical: compact ? TextAlignVertical.center : null,
        decoration: InputDecoration(
          contentPadding: compact
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
              : const EdgeInsets.all(10.0),
          isDense: compact,
          hintText: "e.g. Jane Doe",
          hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: p.textSecondary,
          ),
          border: InputBorder.none,
        ),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: p.textPrimary,
        ),
        cursorColor: p.mint,
        controller: _contactController.nameController.value,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        onChanged: (value) {
          _contactController.name.value = value.trim();
        },
      ),
    );
  }
}

class PinInput extends StatefulWidget {
  final void Function(String) onCompleted;
  final void Function(String) onChanged;
  final TextEditingController controller;
  final bool autofocus;
  /// When true, pin cells expand to fill available width (with gaps between).
  final bool fullWidth;
  final FocusNode? focusNode;
  /// When false, focus/keyboard stay active after completion (e.g. to chain to the next field).
  final bool unfocusOnCompleted;

  const PinInput({
    super.key,
    required this.onCompleted,
    required this.onChanged,
    required this.controller,
    this.autofocus = true,
    this.fullWidth = false,
    this.focusNode,
    this.unfocusOnCompleted = true,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  int _lastPinLen = 0;

  static const double _gap = 10.0;
  static const double _compactSize = 50.0;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _lastPinLen = widget.controller.text.length;
  }

  @override
  void dispose() {
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  PinTheme _pinTheme(BuildContext context, double size, {required bool focused}) {
    final AppPalette p = AppPalette.of(context);
    final double radius = (size * 0.18).clamp(8.0, 14.0);
    final TextStyle base = Theme.of(context).textTheme.titleLarge!;
    return PinTheme(
      width: size,
      height: size,
      textStyle: base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: (size * 0.34).clamp(15.0, 20.0),
        color: p.textPrimary,
      ),
      decoration: BoxDecoration(
        color: focused ? p.surface : p.surfaceElevated,
        border: Border.all(
          color: focused ? p.mint : p.border,
          width: focused ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildPinput(BuildContext context, double cellSize) {
    final PinTheme following = _pinTheme(context, cellSize, focused: false);
    final PinTheme focused = _pinTheme(context, cellSize, focused: true);

    final double keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    return Pinput(
      length: AppConstants.PIN_CODE_LENGTH,
      controller: widget.controller,
      autofocus: widget.autofocus,
      obscureText: true,
      obscuringCharacter: '●',
      focusNode: _focusNode,
      scrollPadding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 96,
        bottom: 120 + keyboardBottom,
      ),
      closeKeyboardWhenCompleted: widget.unfocusOnCompleted,
      defaultPinTheme: following,
      focusedPinTheme: focused,
      submittedPinTheme: focused,
      followingPinTheme: following,
      mainAxisAlignment: MainAxisAlignment.start,
      separatorBuilder: (index) => SizedBox(width: _gap),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      onChanged: (String value) {
        final int len = value.length;
        if (len > _lastPinLen) {
          AppHaptics.selection();
        } else if (len < _lastPinLen) {
          AppHaptics.light();
        }
        _lastPinLen = len;
        widget.onChanged(value);
      },
      onCompleted: (String value) {
        AppHaptics.medium();
        if (widget.unfocusOnCompleted) {
          FocusScope.of(context).unfocus();
        }
        widget.onCompleted(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fullWidth) {
      return _buildPinput(context, _compactSize);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final int n = AppConstants.PIN_CODE_LENGTH;
        double maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 0) {
          maxW = MediaQuery.sizeOf(context).width - 40;
        }
        final double totalGaps = _gap * (n - 1);
        final double cell = math.max(44.0, (maxW - totalGaps) / n);
        return SizedBox(
          width: double.infinity,
          child: _buildPinput(context, cell),
        );
      },
    );
  }
}
