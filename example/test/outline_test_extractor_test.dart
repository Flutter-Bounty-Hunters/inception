import 'dart:convert';
import 'dart:io';
import 'package:example/ide/testing/outline_test_extractor.dart';
import 'package:example/ide/testing/test_node.dart';
import 'package:path/path.dart' as path;

import 'package:example/lsp_exploration/lsp/messages/outline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('outline test extractor', () {
    test('extracts tests', () async {
      // Load the outline notification from a file.
      final file = File(path.join(path.context.current, 'test', 'test_file_outline_sample.json'));
      final content = file.readAsStringSync();
      final outlineNotification = OutlineNotification.fromJson(jsonDecode(content));

      // Extract the tests from the outline.
      final extractor = OutlineTestExtractor();
      final testSuite = await extractor.extractTests(
        outlineNotification.outline,
        outlineNotification.uri,
        false,
      );

      // Ensure that the test suite has the expected structure.
      //
      // Compare it as a string to make it easier to write the test.
      expect(testSuiteToDebugString(testSuite), '''
(suite) ${path.basename(outlineNotification.uri)}
| (test) regular test without group
| (test) widget test without group
| (group) custom runner without group
| (group) root group
| | (test) regular test inside root group
| | (test) widget test inside root group
| | (group) custom runner test inside root group
| | (group) subgroup1
| | | (group) subgroup2
| | | | (test) regular test inside nested group
| | | | (test) widget test inside nested group
| | | | (group) custom runner test inside nested group
''');
    });
  });
}
