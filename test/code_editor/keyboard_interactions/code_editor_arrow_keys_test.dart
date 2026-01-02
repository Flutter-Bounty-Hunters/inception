import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:inception/inception.dart';

void main() {
  group("Code editor > keyboard >", () {
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

    testWidgetsOnMac("SHIFT + arrow keys expands selection", (tester) async {
      // TODO:
    });

    testWidgetsOnMac("ALT + arrow keys jump tokens", (tester) async {
      await _pumpScaffold(tester);

      // Click to place the caret at the start of the document.
      await tester.clickOnCaretPosition(0, 0);
      expect(CodeLinesInspector.findCaretPosition(), CodePosition.start);

      // Make sure nothing bad happens when trying to move the caret left of the first character.
      await tester.pressAltLeftArrow();
      expect(CodeLinesInspector.findCaretPosition(), CodePosition.start);

      // Jump from "|import 'package:flutter/material.dart';" to "import| 'package:flutter/material.dart';"
      // TODO:

      // Jump from "import| 'package:flutter/material.dart';" to "import '|package:flutter/material.dart';"
      // TODO:

      // Jump from "import '|package:flutter/material.dart';" to "import 'package|:flutter/material.dart';"
      // TODO:

      // Jump from "import 'package|:flutter/material.dart';" to "import 'package:|flutter/material.dart';"
      // TODO:

      // Jump from "import 'package:|flutter/material.dart';" to "import 'package:flutter|/material.dart';"
      // TODO:

      // Jump from "import 'package:flutter|/material.dart';" to "import 'package:flutter/|material.dart';"
      // TODO:

      // Jump from "import 'package:flutter/|material.dart';" to "import 'package:flutter/material|.dart';"
      // TODO:

      // Jump from "import 'package:flutter/material|.dart';" to "import 'package:flutter/material.|dart';"
      // TODO:

      // Jump from "import 'package:flutter/material.|dart';" to "import 'package:flutter/material.dart|';"
      // TODO:

      // Jump from "import 'package:flutter/material.dart|';" to "import 'package:flutter/material.dart'|;"
      // TODO:

      // Jump from "import 'package:flutter/material.dart'|;" to "import 'package:flutter/material.dart';|"
      // TODO:

      // Jump to next line.
      // TODO:
    });

    testWidgetsOnMac("SHIFT + ALT + arrow keys expand over tokens", (tester) async {
      // TODO:
    });

    testWidgetsOnMac("CMD + arrow keys jumps to ends of line", (tester) async {
      await _pumpScaffold(tester);

      // Click to place the caret at the start of a line.
      await tester.clickOnCaretPosition(3, 0);
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(3, 0));

      // Jump from the start of the line to the end of the line.
      await tester.pressCmdRightArrow();
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(3, 18));

      // Jump from middle of line to the end of the line.
      await tester.clickOnCaretPosition(3, 8);
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(3, 8));

      await tester.pressCmdRightArrow();
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(3, 18));

      // Jump from end of line to the next line.
      await tester.pressCmdRightArrow();
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(4, 0));

      // Jump from middle of line to the start, just beyond the indent.
      await tester.clickOnCaretPosition(3, 8);
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(3, 8));

      await tester.pressCmdLeftArrow();
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(3, 2));

      // Jump from just beyond the indent to the absolute start of the line.
      await tester.pressCmdLeftArrow();
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(3, 0));

      // Jump from start of line to the previous line.
      await tester.pressCmdLeftArrow();
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(2, 13));
    });

    testWidgetsOnMac("SHIFT + CMD + arrow keys expand to ends of line", (tester) async {
      await _pumpScaffold(tester);

      // Click to place the caret at the start of a line.
      await tester.clickOnCaretPosition(3, 0);
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(3, 0));

      // Jump from the start of the line to the end of the line.
      await tester.pressShiftCmdRightArrow();
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(
          base: CodePosition(3, 0),
          extent: CodePosition(3, 18),
        ),
      );

      // Jump from middle of line to the end of the line.
      await tester.clickOnCaretPosition(3, 8);
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(3, 8));

      await tester.pressShiftCmdRightArrow();
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(
          base: CodePosition(3, 8),
          extent: CodePosition(3, 18),
        ),
      );

      // Jump from end of line to the next line.
      await tester.pressShiftCmdRightArrow();
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(
          base: CodePosition(3, 8),
          extent: CodePosition(4, 0),
        ),
      );

      // Jump from middle of line to the start, just beyond the indent.
      await tester.clickOnCaretPosition(3, 8);
      expect(CodeLinesInspector.findCaretPosition(), const CodePosition(3, 8));

      await tester.pressShiftCmdLeftArrow();
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(
          base: CodePosition(3, 8),
          extent: CodePosition(3, 2),
        ),
      );

      // Jump from just beyond the indent to the absolute start of the line.
      await tester.pressShiftCmdLeftArrow();
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(
          base: CodePosition(3, 8),
          extent: CodePosition(3, 0),
        ),
      );

      // Jump from start of line to the previous line.
      await tester.pressShiftCmdLeftArrow();
      expect(
        CodeEditorInspector.findSelection(),
        const CodeSelection(
          base: CodePosition(3, 8),
          extent: CodePosition(2, 13),
        ),
      );
    });

    testWidgetsOnMac("arrow key collapses an expanded position in arrow direction", (tester) async {
      // TODO:
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
