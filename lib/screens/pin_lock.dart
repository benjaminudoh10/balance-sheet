import 'package:balance_sheet/constants/midnight_theme.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/pin_field_card.dart';
import 'package:balance_sheet/widgets/pin_hero_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Pin extends StatelessWidget {
  final SecurityController _securityController = Get.find();

  @override
  Widget build(BuildContext context) {
    final bool setNewPin = _securityController.currentStoredPin.value == '';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: MidnightTheme.background,
      appBar: AppBar(
        backgroundColor: MidnightTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: MidnightTheme.textPrimary),
        title: Text(
          setNewPin ? 'Set up PIN' : 'Change PIN',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: MidnightTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MidnightGridPainter(heightFraction: 1.0),
            ),
          ),
          SafeArea(
            child: setNewPin ? NewPinScreen() : ChangePinScreen(),
          ),
        ],
      ),
    );
  }
}

class NewPinScreen extends StatefulWidget {
  @override
  State<NewPinScreen> createState() => _NewPinScreenState();
}

class _NewPinScreenState extends State<NewPinScreen> {
  late final TextEditingController _newPinController;
  late final TextEditingController _verifyPinController;
  late final FocusNode _newPinFocus;
  late final FocusNode _verifyPinFocus;

  @override
  void initState() {
    super.initState();
    Get.find<SecurityController>().reset();
    _newPinController = TextEditingController();
    _verifyPinController = TextEditingController();
    _newPinFocus = FocusNode();
    _verifyPinFocus = FocusNode();
  }

  @override
  void dispose() {
    _newPinController.dispose();
    _verifyPinController.dispose();
    _newPinFocus.dispose();
    _verifyPinFocus.dispose();
    super.dispose();
  }

  bool _inputIsValid(SecurityController c) {
    return c.newPin.value != '' &&
        c.newPin.value.length == 4 &&
        c.verifyPin.value != '' &&
        c.verifyPin.value.length == 4;
  }

  Future<void> _setNewPin(SecurityController c) async {
    if (!_inputIsValid(c)) {
      Get.snackbar(
        'Error',
        'All input is required',
        backgroundColor: MidnightTheme.coral.withOpacity(0.9),
        colorText: MidnightTheme.textPrimary,
      );
      return;
    }

    final bool pinSet = await c.setNewPin();
    if (pinSet) {
      Get.snackbar(
        'Success',
        'PIN has been set successfully',
        backgroundColor: MidnightTheme.mint.withOpacity(0.9),
        colorText: Colors.black87,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SecurityController c = Get.find();
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Obx(() => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: PinHeroIcon(icon: Icons.pin_rounded),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose a 4-digit PIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: MidnightTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You’ll use this to unlock Balanced. Pick something you’ll remember.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: MidnightTheme.textSecondary.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 28),
              PinFieldCard(
                label: 'New PIN',
                hint: 'Enter four digits',
                field: PinInput(
                  fullWidth: true,
                  focusNode: _newPinFocus,
                  autofocus: true,
                  unfocusOnCompleted: false,
                  onCompleted: (_) {
                    c.showVerifyInput.value = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _verifyPinFocus.requestFocus();
                    });
                  },
                  onChanged: (value) => c.newPin.value = value,
                  controller: _newPinController,
                ),
              ),
              if (c.showVerifyInput.value) ...[
                const SizedBox(height: 16),
                PinFieldCard(
                  label: 'Confirm PIN',
                  hint: 'Re-enter the same digits',
                  field: PinInput(
                    fullWidth: true,
                    focusNode: _verifyPinFocus,
                    autofocus: false,
                    onCompleted: (_) {},
                    onChanged: (value) => c.verifyPin.value = value,
                    controller: _verifyPinController,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: _inputIsValid(c)
                      ? MidnightTheme.mint
                      : MidnightTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(26),
                  child: InkWell(
                    onTap: () => _setNewPin(c),
                    borderRadius: BorderRadius.circular(26),
                    child: Center(
                      child: Text(
                        'Save PIN',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _inputIsValid(c)
                              ? Colors.black87
                              : MidnightTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

class ChangePinScreen extends StatefulWidget {
  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  late final TextEditingController _currentPinController;
  late final TextEditingController _newPinController;
  late final TextEditingController _verifyPinController;
  late final FocusNode _currentPinFocus;
  late final FocusNode _newPinFocus;
  late final FocusNode _verifyPinFocus;

  @override
  void initState() {
    super.initState();
    Get.find<SecurityController>().reset();
    _currentPinController = TextEditingController();
    _newPinController = TextEditingController();
    _verifyPinController = TextEditingController();
    _currentPinFocus = FocusNode();
    _newPinFocus = FocusNode();
    _verifyPinFocus = FocusNode();
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _verifyPinController.dispose();
    _currentPinFocus.dispose();
    _newPinFocus.dispose();
    _verifyPinFocus.dispose();
    super.dispose();
  }

  bool _inputIsValid(SecurityController c) {
    return c.currentPinEnteredByUser.value != '' &&
        c.currentPinEnteredByUser.value.length == 4 &&
        c.newPin.value != '' &&
        c.newPin.value.length == 4 &&
        c.verifyPin.value != '' &&
        c.verifyPin.value.length == 4;
  }

  Future<void> _changePin(SecurityController c) async {
    if (!_inputIsValid(c)) {
      Get.snackbar(
        'Error',
        'All input is required',
        backgroundColor: MidnightTheme.coral.withOpacity(0.9),
        colorText: MidnightTheme.textPrimary,
      );
      return;
    }

    final bool pinSet = await c.changePin();
    if (pinSet) {
      Get.snackbar(
        'Success',
        'PIN has been set successfully',
        backgroundColor: MidnightTheme.mint.withOpacity(0.9),
        colorText: Colors.black87,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SecurityController c = Get.find();
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Obx(() => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: PinHeroIcon(icon: Icons.lock_reset_rounded),
              ),
              const SizedBox(height: 20),
              const Text(
                'Update your PIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: MidnightTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your current PIN, then choose a new one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: MidnightTheme.textSecondary.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 28),
              PinFieldCard(
                label: 'Current PIN',
                hint: 'Your existing 4-digit PIN',
                field: PinInput(
                  fullWidth: true,
                  focusNode: _currentPinFocus,
                  autofocus: true,
                  unfocusOnCompleted: false,
                  onCompleted: (_) {
                    c.showNewPin.value = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _newPinFocus.requestFocus();
                    });
                  },
                  onChanged: (value) =>
                      c.currentPinEnteredByUser.value = value,
                  controller: _currentPinController,
                ),
              ),
              if (c.showNewPin.value) ...[
                const SizedBox(height: 16),
                PinFieldCard(
                  label: 'New PIN',
                  hint: 'Choose a new 4-digit PIN',
                  field: PinInput(
                    fullWidth: true,
                    focusNode: _newPinFocus,
                    autofocus: false,
                    unfocusOnCompleted: false,
                    onCompleted: (_) {
                      c.showVerifyInput.value = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _verifyPinFocus.requestFocus();
                      });
                    },
                    onChanged: (value) => c.newPin.value = value,
                    controller: _newPinController,
                  ),
                ),
              ],
              if (c.showVerifyInput.value) ...[
                const SizedBox(height: 16),
                PinFieldCard(
                  label: 'Confirm new PIN',
                  hint: 'Re-enter your new PIN',
                  field: PinInput(
                    fullWidth: true,
                    focusNode: _verifyPinFocus,
                    autofocus: false,
                    onCompleted: (_) {},
                    onChanged: (value) => c.verifyPin.value = value,
                    controller: _verifyPinController,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: _inputIsValid(c)
                      ? MidnightTheme.mint
                      : MidnightTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(26),
                  child: InkWell(
                    onTap: () => _changePin(c),
                    borderRadius: BorderRadius.circular(26),
                    child: Center(
                      child: Text(
                        'Update PIN',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _inputIsValid(c)
                              ? Colors.black87
                              : MidnightTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
