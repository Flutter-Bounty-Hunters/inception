import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:inception/inception.dart';
import 'package:inception/src/languages/dart/dart_theme_pineapple.dart';

void main() {
  group("Code Editor > double click >", () {
    late CodeDocument document;

    setUp(() {
      document = CodeDocument(DartLexer(), _sampleDartCode);
    });

    testWidgetsOnMac("on token to select it", (tester) async {
      await _pumpScaffold(tester, document);

      // Double click in middle of "import" token.
      await tester.doubleClickAtCodePosition(0, 2);

      // Ensure all of "import" was selected.
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(base: CodePosition(0, 0), extent: CodePosition(0, 6)),
      );
    });

    testWidgetsOnMac("on whitespace to select nearest token", (tester) async {
      await _pumpScaffold(tester, document);

      // Double click just beyond "void" in the whitespace, on the upstream edge.
      await tester.doubleClickAtCodePosition(2, 4, affinity: TextAffinity.upstream);

      // Ensure that "void" to the left of the click position was selected.
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(base: CodePosition(2, 0), extent: CodePosition(2, 4)),
      );

      // Double click just beyond "void" in the whitespace, on the downstream edge.
      await tester.doubleClickAtCodePosition(2, 4, affinity: TextAffinity.downstream);

      // Ensure that "main" to the right of the click position was selected.
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(base: CodePosition(2, 5), extent: CodePosition(2, 9)),
      );
    });

    testWidgetsOnMac("and drag to select token and then expand", (tester) async {
      // TODO: Double-click down and drag to select token + expand in either direction
    });
  });
}

Future<void> _pumpScaffold(WidgetTester tester, CodeDocument document) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CodeEditor(
          presenter: CodeEditorPresenter(
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

void main() {
  runApp(MyApp());
}''';
