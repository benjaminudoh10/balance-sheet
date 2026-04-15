import 'package:balance_sheet/constants/midnight_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MidnightTheme.background,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: MidnightTheme.background,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              flex: 9,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 36.0,
                        color: MidnightTheme.mint,
                      ),
                      const SizedBox(width: 15.0),
                      const Text(
                        'Balanced',
                        style: TextStyle(
                          color: MidnightTheme.textPrimary,
                          fontSize: 36.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '...know where your money goes',
                    style: TextStyle(
                      color: MidnightTheme.textSecondary,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              flex: 1,
              child: SpinKitThreeBounce(
                color: MidnightTheme.mint,
                size: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
