import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:inception/inception.dart';
import 'package:inception/language_dart.dart';
import 'package:inception/src/languages/dart/dart_theme_pineapple.dart';

void main() {
  group("Code Editor > triple click >", () {
    late CodeDocument document;

    setUp(() {
      document = CodeDocument(DartLexer(), _sampleDartCode);
    });

    testWidgetsOnMac("selects line", (tester) async {
      await _pumpScaffold(tester, document);

      await tester.tripleClickAtCodePosition(5, 6);

      // Ensure the whole line was selected.
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(base: CodePosition(5, 0), extent: CodePosition(5, 18)),
      );
    });

    testWidgetsOnMac("and drag to select line and then expand", (tester) async {
      // TODO: Double-click down and drag to select token + expand in either direction
    });
  });
}

Future<void> _pumpScaffold(WidgetTester tester, CodeDocument document) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CodeEditor(
          presenter: DartCodeEditorPresenter(
            document,
            DartSyntaxHighlighter(
              pineappleDartTheme,
              const TextStyle(fontSize: 14, height: 2),
            ),
          ),
          style: const CodeEditorStyle.defaultDark(),
        ),
      ),
    ),
  );
}

const _sampleDartCode = '''
import 'package:flutter/material.dart';

/// This is a DartDoc comment.
void main() {
  // This is an inline comment.
  runApp(MyApp());
}

class MyClass {
  /// This is an indented DartDoc comment.
  void someFunction() {}
}
''';
