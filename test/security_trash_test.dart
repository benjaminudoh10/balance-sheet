// import 'package:flutter_test/flutter_test.dart';
// import 'package:get/get.dart';
// import 'package:balance_sheet/controllers/app_controller.dart';
// import 'package:balance_sheet/controllers/security_controller.dart';

// class TestSecurityController extends SecurityController {
//   bool authResult = true;
//   @override
//   Future<bool> authenticateUser(String reason) async {
//     return authResult;
//   }
// }

// void main() {
//   late TestSecurityController testSecurityController;
//   late AppController appController;

//   setUp(() {
//     testSecurityController = TestSecurityController();
//     Get.put<SecurityController>(testSecurityController, permanent: true);
//     appController = Get.put(AppController());
//   });

//   tearDown(() {
//     Get.reset();
//   });

//   group('Trash Feature Hardening Tests', () {
//     test('setUseTrash(false) should block when lockTrash is true and auth fails', () async {
//       appController.useTrash.value = true;
//       appController.lockTrash.value = true;
//       testSecurityController.authResult = false;

//       await appController.setUseTrash(false);

//       expect(appController.useTrash.value, isTrue);
//     });

//     test('setUseTrash(false) should succeed when lockTrash is true and auth succeeds', () async {
//       appController.useTrash.value = true;
//       appController.lockTrash.value = true;
//       testSecurityController.authResult = true;

//       await appController.setUseTrash(false);

//       expect(appController.useTrash.value, isFalse);
//     });

//     test('setLockTrash(false) should block when auth fails', () async {
//       appController.lockTrash.value = true;
//       testSecurityController.authResult = false;

//       await appController.setLockTrash(false);

//       expect(appController.lockTrash.value, isTrue);
//     });

//     test('setLockTrash(false) should succeed when auth succeeds', () async {
//       appController.lockTrash.value = true;
//       testSecurityController.authResult = true;

//       await appController.setLockTrash(false);

//       expect(appController.lockTrash.value, isFalse);
//     });
//   });
// }
void main() {}
