import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Color(0xff9448d5),
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
                        Icons.menu_book,
                        size: 36.0,
                        color: Color(0xfffdfdfd),
                      ),
                      const SizedBox(width: 15.0,),
                      Text(
                        "Balanced",
                        style: TextStyle(
                          color: Color(0xfffdfdfd),
                          fontSize: 36.0
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "...know where your money goes",
                    style: TextStyle(
                      color: Color(0xfffdfdfd),
                      fontSize: 20.0
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: const SpinKitThreeBounce(
                color: Colors.white,
                size: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
