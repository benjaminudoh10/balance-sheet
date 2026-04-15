import 'dart:async';

import 'package:intl/intl.dart';

/// Pin formatting so [NumberFormat] / currency tests behave the same locally and on CI.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Intl.defaultLocale = 'en_NG';
  await testMain();
}
