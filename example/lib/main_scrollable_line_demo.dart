import 'package:example/ide/editor/scrolling_code_line.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: const Scaffold(
        backgroundColor: Color(0xFF222222),
        body: _ScrollingLineScreen(),
      ),
    ),
  );
}

class _ScrollingLineScreen extends StatelessWidget {
  const _ScrollingLineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: double.infinity,
        child: ScrollingCodeLine(
          lineNumber: 31,
          indentLineColor: Color(0xFF333333),
          baseTextStyle: TextStyle(
            color: Colors.white,
            fontFamily: "SourceCodePro",
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          scrollOffset: 0,
          code: TextSpan(
            text: "class _ScrollingLineScreen extends StatelessWidget {",
          ),
        ),
      ),
    );
  }
}
