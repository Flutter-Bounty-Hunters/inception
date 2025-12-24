import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/golden_bricks.dart';
import 'package:inception/inception.dart';

void main() {
  group("Code layout > code lines >", () {
    testGoldenSceneOnMac("caret positions", (tester) async {
      final gallery = Gallery(
        "Code Line - Caret Positions",
        fileName: "code-line_caret-positions",
        itemScaffold: _codeLineScaffold,
        layout: ColumnSceneLayout(
          background: GoldenSceneBackground.color(Colors.grey.shade900),
          itemDecorator: defaultDarkGoldenSceneItemDecorator,
        ),
      );

      for (int i = 0; i <= _lineText.toPlainText().length; i += 1) {
        gallery.itemFromWidget(
          description: "Caret at $i",
          widget: CodeLine(
            lineNumber: 123,
            code: _lineText,
            selection: TextSelection.collapsed(offset: i),
            style: _codeLineStyle,
          ),
        );
      }

      await gallery.run(tester);
    });

    testGoldenSceneOnMac("shadow caret positions", (tester) async {
      final gallery = Gallery(
        "Code Line - Shadow Caret Positions",
        fileName: "code-line_shadow-caret-positions",
        itemScaffold: _codeLineScaffold,
        layout: ColumnSceneLayout(
          background: GoldenSceneBackground.color(Colors.grey.shade900),
          itemDecorator: defaultDarkGoldenSceneItemDecorator,
        ),
      );

      for (int i = 0; i <= _lineText.toPlainText().length; i += 1) {
        gallery.itemFromWidget(
          description: "Caret at $i",
          widget: CodeLine(
            lineNumber: 123,
            code: _lineText,
            shadowCaretPosition: TextPosition(offset: i),
            style: _codeLineStyle,
          ),
        );
      }

      await gallery.run(tester);
    });

    testGoldenSceneOnMac("selection ranges", (tester) async {
      final gallery = Gallery(
        "Code Line - Selection Ranges",
        fileName: "code-line_selection-ranges",
        itemScaffold: _codeLineScaffold,
        layout: ColumnSceneLayout(
          background: GoldenSceneBackground.color(Colors.grey.shade900),
          itemDecorator: defaultDarkGoldenSceneItemDecorator,
        ),
      );

      gallery.itemFromWidget(
        description: "Full Selection - Downstream",
        widget: CodeLine(
          lineNumber: 123,
          code: _lineText,
          selection: TextSelection(baseOffset: 0, extentOffset: _lineText.toPlainText().length),
          style: _codeLineStyle,
        ),
      );

      gallery.itemFromWidget(
        description: "Full Selection - Upstream",
        widget: CodeLine(
          lineNumber: 123,
          code: _lineText,
          selection: TextSelection(baseOffset: _lineText.toPlainText().length, extentOffset: 0),
          style: _codeLineStyle,
        ),
      );

      gallery.itemFromWidget(
        description: "Return Type Token - Downstream",
        widget: CodeLine(
          lineNumber: 123,
          code: _lineText,
          selection: const TextSelection(baseOffset: 0, extentOffset: 4),
          style: _codeLineStyle,
        ),
      );

      gallery.itemFromWidget(
        description: "Return Type Token - Upstream",
        widget: CodeLine(
          lineNumber: 123,
          code: _lineText,
          selection: const TextSelection(baseOffset: 4, extentOffset: 0),
          style: _codeLineStyle,
        ),
      );

      gallery.itemFromWidget(
        description: "Function Name Token - Downstream",
        widget: CodeLine(
          lineNumber: 123,
          code: _lineText,
          selection: const TextSelection(baseOffset: 5, extentOffset: 9),
          style: _codeLineStyle,
        ),
      );

      gallery.itemFromWidget(
        description: "Function Name Token - Upstream",
        widget: CodeLine(
          lineNumber: 123,
          code: _lineText,
          selection: const TextSelection(baseOffset: 9, extentOffset: 5),
          style: _codeLineStyle,
        ),
      );

      await gallery.run(tester);
    });
  });
}

Widget _codeLineScaffold(tester, content) {
  return GoldenSceneBounds(
    child: MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: goldenBricks,
      ),
      home: Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: GoldenImageBounds(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: content,
            ),
          ),
        ),
      ),
    ),
  );
}

final _lineText = TextSpan(
  children: [
    const TextSpan(text: "void", style: TextStyle(color: _keywordColor)),
    const TextSpan(text: " "),
    TextSpan(text: "main", style: TextStyle(color: Colors.grey.shade200)),
    const TextSpan(text: "()", style: TextStyle(color: _bracketsColor)),
    const TextSpan(text: " "),
    const TextSpan(text: "[", style: TextStyle(color: _bracketsColor)),
  ],
);

const _codeLineStyle = CodeLineStyle(
  baseTextStyle: _baseTextStyle,
  indentLineColor: indentLineColor,
  shadowCaretColor: _shadowCaretColor,
  selectionBoxColor: _selectionColor,
  caretColor: _caretColor,
);

const _baseTextStyle = TextStyle(
  color: _baseTextColor,
  fontFamily: goldenBricks,
  fontSize: 14,
  height: 1.4,
);

const _backgroundColor = Color(0xFF1B2A2F);
const _baseTextColor = Color(0xFFECE7D5);
const _keywordColor = Color(0xFFFFC857);
const _bracketsColor = Color(0xFF7CD992);
const _selectionColor = Color(0xFF2F6F7A);
const _shadowCaretColor = Color(0xFF666666);
const _caretColor = Color(0xFFFFE066);
