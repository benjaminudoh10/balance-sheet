import 'package:balance_sheet/screens/splash.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash shows title and tagline', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: <ThemeExtension<dynamic>>[AppPalette.light],
        ),
        home: Splash(),
      ),
    );
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.textContaining('know where your money goes'), findsOneWidget);
  });
}
