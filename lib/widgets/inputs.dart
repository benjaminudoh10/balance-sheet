import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/controllers/organizationController.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
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

class AmountInput extends StatelessWidget {
  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10.0),
        color: Color(0x33ffffff),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 10.0,
      ),
      child: TextField(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10.0),
          hintText: "0.00",
          hintStyle: TextStyle(
            fontSize: 14.0,
            color: Color(0x88ffffff),
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          color: Colors.white,
        ),
        cursorColor: Colors.white,
        controller: _transactionController.amountController.value,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [DecimalTextInputFormatter()],
        onChanged: (value) {
          _transactionController.amount.value = double.parse(value) * 1000 ~/ 10;
        },
      ),
    );
  }
}

class CategoryInput extends StatelessWidget {
  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    List<Map<String, Object>> category = Categories.CATEGORIES.where(
      (category) => category["key"] == _transactionController.category.value
    ).toList();
    String categoryLabel = category[0]['label']! as String;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10.0),
        color: Color(0x33ffffff),
      ),
      width: Get.width,
      padding: EdgeInsets.symmetric(
        vertical: 15.0,
        horizontal: 8.0,
      ),
      margin: EdgeInsets.symmetric(
        vertical: 10.0,
      ),
      child: Text(
        categoryLabel,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.0,
        ),
      ),
    );
  }
}

class DescriptionInput extends StatelessWidget {
  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10.0),
        color: Color(0x33ffffff),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 10.0,
      ),
      child: TextField(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10.0),
          hintText: "e.g. Tomatoes",
          hintStyle: TextStyle(
            fontSize: 14.0,
            color: Color(0x88ffffff),
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          color: Colors.white,
        ),
        cursorColor: Colors.white,
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
  final ContactController _contactController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10.0),
        color: Color(0x33ffffff),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 10.0,
      ),
      child: TextField(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10.0),
          hintText: "e.g. Jane Doe",
          hintStyle: TextStyle(
            fontSize: 14.0,
            color: Color(0x88ffffff),
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          color: Colors.white,
        ),
        cursorColor: Colors.white,
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

class PinInput extends StatelessWidget {
  final void Function(String) onCompleted;
  final void Function(String) onChanged;
  final TextEditingController controller;
  final FocusNode _focusNode = FocusNode();

  PinInput({
    super.key,
    required this.onCompleted,
    required this.onChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    _focusNode.requestFocus();

    final following = PinTheme(
      width: 50,
      height: 50,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.LIGHT_2_GREY,
        border: Border.all(color: AppColors.LIGHT_2_GREY),
        borderRadius: BorderRadius.circular(5.0),
      ),
    );
    final focused = PinTheme(
      width: 50,
      height: 50,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.SECONDARY,
        border: Border.all(
          color: AppColors.PRIMARY,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(5.0),
      ),
    );

    return Pinput(
      length: AppConstants.PIN_CODE_LENGTH,
      controller: controller,
      autofocus: true,
      obscureText: true,
      obscuringCharacter: '●',
      focusNode: _focusNode,
      defaultPinTheme: following,
      focusedPinTheme: focused,
      submittedPinTheme: focused,
      followingPinTheme: following,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      onChanged: onChanged,
      onCompleted: (value) {
        FocusScope.of(context).unfocus();
        onCompleted(value);
      },
    );
  }
}

class OrganizationInput extends StatelessWidget {
  final OrganizationController _organizationController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10.0),
        color: Color(0x33ffffff),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 10.0,
      ),
      child: TextField(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10.0),
          hintText: "e.g. Investments",
          hintStyle: TextStyle(
            fontSize: 14.0,
            color: Color(0x88ffffff),
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          color: Colors.white,
        ),
        cursorColor: Colors.white,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.sentences,
        autofocus: true,
        onChanged: (value) {
          _organizationController.name.value = value.trim();
        },
      ),
    );
  }
}
