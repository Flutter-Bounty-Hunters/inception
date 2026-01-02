import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:inception/inception.dart';

void main() {
  group("Code editor >", () {
    group("selection >", () {
      group("gestures >", () {
        testWidgetsOnMac("tap to place caret", (tester) async {
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

        testWidgetsOnMac("double tap to select word", (tester) async {
          // TODO:
        });

        testWidgetsOnMac("triple tap to select line", (tester) async {
          // TODO:
        });
      });

      group("keyboard >", () {
        testWidgetsOnMac("arrow keys push caret", (tester) async {
          await _pumpScaffold(tester);

          // Click to place the caret at the start of the document.
          await tester.clickOnCaretPosition(0, 0);
          expect(CodeLinesInspector.findCaretPosition(), CodePosition.start);

          // Make sure nothing bad happens when trying to move the caret left of the first character.
          await tester.pressLeftArrow();
          expect(CodeLinesInspector.findCaretPosition(), CodePosition.start);

          // Press the right arrow, moving the caret character by character, until we get
          // to the end of the whole code document.
          CodePosition? previousCaretPosition;
          CodePosition currentCaretPosition = CodePosition.start;
          while (currentCaretPosition != previousCaretPosition) {
            previousCaretPosition = currentCaretPosition;
            await tester.pressRightArrow();
            currentCaretPosition = CodeLinesInspector.findCaretPosition()!;

            // Ensure that we moved one position downstream.
            final expectedNextPosition = CodeLinesInspector.findPositionAfter(previousCaretPosition);
            if (expectedNextPosition != null) {
              expect(currentCaretPosition, expectedNextPosition);
            }
          }
          // Ensure we're at the end of the document.
          expect(currentCaretPosition, CodeLinesInspector.findEndPosition());

          // Press the left arrow, moving the caret character by character, until we get
          // to the start of the whole code document.
          previousCaretPosition = null;
          currentCaretPosition = CodeLinesInspector.findEndPosition();
          while (currentCaretPosition != previousCaretPosition) {
            previousCaretPosition = currentCaretPosition;
            await tester.pressLeftArrow();
            currentCaretPosition = CodeLinesInspector.findCaretPosition()!;

            // Ensure that we moved one position upstream.
            final expectedNextPosition = CodeLinesInspector.findPositionBefore(previousCaretPosition);
            if (expectedNextPosition != null) {
              expect(currentCaretPosition, expectedNextPosition);
            }
          }
          // Ensure we're at the start of the document.
          expect(currentCaretPosition, CodePosition.start);
        });

        testWidgetsOnMac("ALT + arrow keys jump tokens", (tester) async {
          // TODO:
        });

        testWidgetsOnMac("CMD + arrow keys jumps to ends of line", (tester) async {
          // TODO:
        });

        testWidgetsOnMac("SHIFT + arrow keys expands selection", (tester) async {
          // TODO:
        });

        testWidgetsOnMac("SHIFT + ALT + arrow keys expand over tokens", (tester) async {
          // TODO:
        });

        testWidgetsOnMac("SHIFT + CMD + arrow keys expand to ends of line", (tester) async {
          // TODO:
        });

        testWidgetsOnMac("arrow key collapses an expanded position in arrow direction", (tester) async {
          // TODO:
        });
      });
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
