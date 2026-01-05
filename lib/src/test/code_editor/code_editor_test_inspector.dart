import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inception/src/document/selection.dart';
import 'package:inception/src/editor/code_editor.dart';

abstract class CodeEditorInspector {
  static String findContent([Finder? finder]) {
    final (codeEditor, _) = _findCodeEditor(finder);
    return codeEditor.presenter.document.text;
  }

  static CodeSelection? findSelection([Finder? finder]) {
    final (codeEditor, _) = _findCodeEditor(finder);
    return codeEditor.presenter.selection.value;
  }

  static (CodeEditor codeEditor, StatefulElement codeEditorState) _findCodeEditor([Finder? finder]) {
    final finderResults = (finder ?? find.byType(CodeEditor)).evaluate();
    if (finderResults.isEmpty) {
      throw Exception(
        "Didn't find a CodeEditor in the widget tree.",
      );
    }
    if (finderResults.length > 1) {
      throw Exception(
        "Found multiple CodeEditor's in the widget tree. We need to find just a single one.",
      );
    }

    final element = finderResults.first;
    if (element is! StatefulElement) {
      throw Exception(
        "Expected the CodeEditor widget to have a StatefulElement. Instead we found: ${element.runtimeType}",
      );
    }

    return (element.widget as CodeEditor, element);
  }
}
