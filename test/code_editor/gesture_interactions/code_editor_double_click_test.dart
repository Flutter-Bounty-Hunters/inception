import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:inception/inception.dart';
import 'package:inception/language_dart.dart';
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
      await tester.doubleClickAtCodePosition(3, 4, affinity: TextAffinity.upstream);

      // Ensure that "void" to the left of the click position was selected.
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(base: CodePosition(3, 0), extent: CodePosition(3, 4)),
      );

      // Double click just beyond "void" in the whitespace, on the downstream edge.
      await tester.doubleClickAtCodePosition(3, 4, affinity: TextAffinity.downstream);

      // Ensure that "main" to the right of the click position was selected.
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(base: CodePosition(3, 5), extent: CodePosition(3, 9)),
      );
    });

    group("on Dart Doc >", () {
      testWidgetsOnMac("on indentation whitespace", (tester) async {
        await _pumpScaffold(tester, document);

        // Double click on the whitespace that appears before the initiating "///" syntax.
        await tester.doubleClickAtCodePosition(9, 0);

        // Ensure that all the space before the "///" was selected.
        expect(
          CodeEditorInspector.findSelection(),
          const CodeSelection(base: CodePosition(9, 0), extent: CodePosition(9, 2)),
        );
      });

      testWidgetsOnMac("on comment syntax", (tester) async {
        await _pumpScaffold(tester, document);

        // Double click on the initiating "///" syntax.
        await tester.doubleClickAtCodePosition(9, 3);

        // Ensure that the whole line is selected.
        expect(
          CodeEditorInspector.findSelection(),
          const CodeSelection(base: CodePosition(9, 0), extent: CodePosition(9, 42)),
        );
      });

      testWidgetsOnMac("on word", (tester) async {
        await _pumpScaffold(tester, document);

        // Double click in middle of "This" word.
        await tester.doubleClickAtCodePosition(2, 6);

        // Ensure all of "This" was selected.
        expect(
          CodeEditorInspector.findSelection(),
          const CodeSelection(base: CodePosition(2, 4), extent: CodePosition(2, 8)),
        );
      });

      testWidgetsOnMac("on whitespace", (tester) async {
        await _pumpScaffold(tester, document);

        // Double click on space after "This" and before "is", on the upstream side
        await tester.doubleClickAtCodePosition(2, 8, affinity: TextAffinity.upstream);

        // Ensure all of "This" was selected.
        expect(
          CodeEditorInspector.findSelection(),
          const CodeSelection(base: CodePosition(2, 4), extent: CodePosition(2, 8)),
        );

        // Double click on space after "This" and before "is", on the downstream side
        await tester.doubleClickAtCodePosition(2, 8, affinity: TextAffinity.downstream);

        // Ensure all of "is" was selected.
        expect(
          CodeEditorInspector.findSelection(),
          const CodeSelection(base: CodePosition(2, 9), extent: CodePosition(2, 11)),
        );
      });
    });

    group("on inline comment >", () {
      testWidgetsOnMac("on indentation whitespace", (tester) async {
        await _pumpScaffold(tester, document);

        // Double click on the whitespace that appears before the initiating "///" syntax.
        await tester.doubleClickAtCodePosition(4, 0);

        // Ensure that all the space before the "//" was selected.
        expect(
          CodeEditorInspector.findSelection(),
          const CodeSelection(base: CodePosition(4, 0), extent: CodePosition(4, 2)),
        );
      });

      testWidgetsOnMac("on comment syntax", (tester) async {
        await _pumpScaffold(tester, document);

        // Double click on the initiating "///" syntax.
        await tester.doubleClickAtCodePosition(9, 3);

        // Ensure that the whole line is selected.
        expect(
          CodeEditorInspector.findSelection(),
          const CodeSelection(base: CodePosition(9, 0), extent: CodePosition(9, 42)),
        );
      });

      testWidgetsOnMac("on word", (tester) async {
        await _pumpScaffold(tester, document);

        // Double click in middle of "This" word.
        await tester.doubleClickAtCodePosition(4, 7);

        // Ensure all of "This" was selected.
        expect(
          CodeEditorInspector.findSelection(),
          const CodeSelection(base: CodePosition(4, 5), extent: CodePosition(4, 9)),
        );
      });

      testWidgetsOnMac("on whitespace", (tester) async {
        await _pumpScaffold(tester, document);

        // Double click on space after "This" and before "is", on the upstream side
        await tester.doubleClickAtCodePosition(4, 9, affinity: TextAffinity.upstream);

        // Ensure all of "This" was selected.
        expect(
          CodeEditorInspector.findSelection(),
          const CodeSelection(base: CodePosition(4, 5), extent: CodePosition(4, 9)),
        );

        // Double click on space after "This" and before "is", on the downstream side
        await tester.doubleClickAtCodePosition(4, 9, affinity: TextAffinity.downstream);

        // Ensure all of "is" was selected.
        expect(
          CodeEditorInspector.findSelection(),
          const CodeSelection(base: CodePosition(4, 10), extent: CodePosition(4, 12)),
        );
      });
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
