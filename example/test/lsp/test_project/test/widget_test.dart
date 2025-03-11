import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';

void main() {
  testWidgetsOnAllPlatforms('custom runner without group', (tester) async {});

  test('regular test without group', () {});

  testWidgets('widget test without group', (tester) async {});

  group('root group', () {
    test('regular test inside root group', () {});
    testWidgets('widget test inside root group', (tester) async {});
    testWidgetsOnAllPlatforms('custom runner test inside root group', (tester) async {});

    group('subgroup1', () {
      group('subgroup2', () {
        test('regular test inside nested group', () {});
        testWidgets('widget test inside nested group', (tester) async {});
        testWidgetsOnAllPlatforms('custom runner test inside nested group', (tester) async {});
      });
    });
  });
}
