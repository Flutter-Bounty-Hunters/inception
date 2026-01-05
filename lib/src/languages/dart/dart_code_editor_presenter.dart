import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:inception/src/document/code_document.dart';
import 'package:inception/src/document/syntax_highlighter.dart';
import 'package:inception/src/editor/code_editor.dart';

class DartCodeEditorPresenter extends CodeEditorPresenter {
  DartCodeEditorPresenter(CodeDocument document, this._syntaxHighlighter)
      : _codeLines = ValueNotifier([]),
        super(document) {
    _syntaxHighlighter.attachToDocument(document);
    _syntaxHighlighter.addListener(_onStyledLinesChanged);

    _onStyledLinesChanged();
  }

  @override
  void dispose() {
    _syntaxHighlighter.detachFromDocument();
    _syntaxHighlighter.removeListener(_onStyledLinesChanged);
    _codeLines.dispose();
    selection.dispose();
  }

  @override
  ValueListenable<List<TextSpan>> get codeLines => _codeLines;
  final ValueNotifier<List<TextSpan>> _codeLines;

  final CodeDocumentSyntaxHighlighter _syntaxHighlighter;

  void _onStyledLinesChanged() {
    _codeLines.value = [
      for (int i = 0; i < _syntaxHighlighter.lineCount; i += 1) //
        _syntaxHighlighter.getStyledLineAt(i)!,
    ];
  }
}
