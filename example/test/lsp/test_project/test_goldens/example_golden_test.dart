import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('example with inexisting golden', (tester) async {
    await tester.pumpWidgetBuilder(Container());
    await screenMatchesGolden(tester, 'example_inexisting_golden');
  });

  testGoldens('example with existing golden', (tester) async {
    await tester.pumpWidgetBuilder(Container(
      color: Colors.red,
    ));
    await screenMatchesGolden(tester, 'example_existing_golden');
  });
}
