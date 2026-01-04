import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:inception/inception.dart';

void main() {
  group("Code editor > keyboard >", () {
    testWidgetsOnMac("ESC key collapses selection", (tester) async {
      final presenter = TestCodeEditorPresenter()..codeLines.value = _helloWorldCodeLines;

      // Show a downstream expanded selection.
      presenter.selection.value = const CodeSelection(
        base: CodePosition(2, 5),
        extent: CodePosition(2, 11),
      );
      await _pumpScaffold(tester, presenter: presenter, autofocus: true);

      // Press ESC to collapse the selection downstream.
      await tester.pressEscape();

      // Ensure the selection collapsed in the downstream direction.
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection.collapsed(CodePosition(2, 11)),
      );

      // Configure an upstream selection.
      presenter.selection.value = const CodeSelection(
        base: CodePosition(2, 11),
        extent: CodePosition(2, 5),
      );
      await tester.pump();

      // Press ESC to collapse the selection upstream.
      await tester.pressEscape();

      // Ensure the selection collapsed in the upstream direction.
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection.collapsed(CodePosition(2, 5)),
      );
    });
  });
}

Future<void> _pumpScaffold(
  WidgetTester tester, {
  CodeEditorPresenter? presenter,
  bool autofocus = false,
}) async {
  // Create the default presenter, if none provided.
  presenter ??= TestCodeEditorPresenter()..codeLines.value = _helloWorldCodeLines;

  final focusNode = autofocus ? FocusNode(debugLabel: 'test-suite') : null;
  focusNode?.requestFocus();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CodeEditor(
          focusNode: focusNode,
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
