import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pin_put/pin_put.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({this.decimalRange = 2})
    : assert(decimalRange > 0);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;
    String value = newValue.text;
    // String afterDecimal = value.substring(value.indexOf(".") + 1);

    // if (afterDecimal.length < 2) {
    //   truncated = "${value}0";
    //   newSelection = oldValue.selection;
    if (value.startsWith(".")) {
      truncated = "0$value";
      newSelection = oldValue.selection;
    } else if (".".allMatches(value).length == 2) {
      // catch double fullstop
      truncated = value.replaceFirst(RegExp('.'), '', value.lastIndexOf("."));
      newSelection = oldValue.selection;
    } else if (value.contains(".") &&
      value.substring(value.indexOf(".") + 1).length > decimalRange) {
      truncated = this.formatNewValue(newValue.text);
      newSelection = oldValue.selection;
    } else if (value == ".") {
      truncated = "0.";
      newSelection = newValue.selection.copyWith(
        baseOffset: truncated.length,
        extentOffset: truncated.length,
      );
    }

    return TextEditingValue(
      text: truncated,
      selection: TextSelection( // previously newSelection
        baseOffset: truncated.length,
        extentOffset: truncated.length
      ),
      composing: TextRange.empty,
    );
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
    String categoryLabel = category[0]['label'];
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
  final Function(String) onCompleted;
  final Function(String) onChanged;
  final TextEditingController controller;
  final FocusNode _focusNode = FocusNode();

  PinInput({
    @required this.onCompleted,
    @required this.onChanged,
    @required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    _focusNode.requestFocus();

    return PinPut(
      fieldsCount: AppConstants.PIN_CODE_LENGTH,
      controller: controller,
      autofocus: true,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
      ),
      obscureText: "●",
      focusNode: _focusNode,
      selectedFieldDecoration: BoxDecoration(
        color: AppColors.SECONDARY,
        border: Border.all(
          color: AppColors.PRIMARY,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(5.0),
      ),
      submittedFieldDecoration: BoxDecoration(
        color: AppColors.SECONDARY,
        border: Border.all(
          color: AppColors.PRIMARY,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(5.0),
      ),
      followingFieldDecoration: BoxDecoration(
        color: AppColors.LIGHT_2_GREY,
        border: Border.all(color: AppColors.LIGHT_2_GREY),
        borderRadius: BorderRadius.circular(5.0),
      ),
      onChanged: onChanged,
      onSubmit: (value) {
        FocusScope.of(Get.context).unfocus();
        onCompleted(value);
      },
      eachFieldWidth: 50.0,
      eachFieldHeight: 50.0,
    );
  }
}
