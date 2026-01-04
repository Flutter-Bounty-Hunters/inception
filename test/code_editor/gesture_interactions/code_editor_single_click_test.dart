import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:inception/inception.dart';

void main() {
  group("Code Editor > double click >", () {
    testWidgetsOnMac("places the caret", (tester) async {
      await _pumpScaffold(tester);

      for (int i = 0; i < _helloWorldCodeLines.length; i += 1) {
        final line = _helloWorldCodeLines[i].toPlainText();

        // Click at start of line.
        await tester.clickOnCaretPosition(i, 0);
        expect(CodeLinesInspector.findCaretPosition(), CodePosition(i, 0));

        if (line.length > 1) {
          // Click at middle of line.
          final characterOffset = (line.length / 2).floor();
          await tester.clickOnCaretPosition(i, characterOffset);
          expect(CodeLinesInspector.findCaretPosition(), CodePosition(i, characterOffset));
        }

        if (line.isNotEmpty) {
          // Click at end of line.
          await tester.clickOnCaretPosition(i, line.length);
          expect(CodeLinesInspector.findCaretPosition(), CodePosition(i, line.length));
        }
      }
    });
  });
}

Future<void> _pumpScaffold(
  WidgetTester tester, {
  CodeEditorPresenter? presenter,
}) async {
  // Create the default presenter, if none provided.
  presenter ??= TestCodeEditorPresenter()..codeLines.value = _helloWorldCodeLines;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CodeEditor(
          presenter: presenter,
          style: const CodeEditorStyle.defaultDark(),
        ),
      ),
    ),
  );
}

const _helloWorldCodeLines = [
  TextSpan(text: "import 'package:flutter/material.dart';"),
  TextSpan(text: ""),
  TextSpan(text: "void main() {"),
  TextSpan(text: "  runApp(MyApp());"),
  TextSpan(text: "}"),
];
