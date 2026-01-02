import 'dart:ui' show TextAffinity;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:inception/src/document/code_document.dart';
import 'package:inception/src/document/lexing.dart';
import 'package:inception/src/document/selection.dart';
import 'package:inception/src/document/syntax_highlighter.dart';
import 'package:inception/src/editor/code_editor.dart';
import 'package:inception/src/infrastructure/text/code_comment_selection_rules.dart';

class DartCodeEditorPresenter implements CodeEditorPresenter {
  DartCodeEditorPresenter(this._document, this._syntaxHighlighter)
      : _codeLines = ValueNotifier([]),
        selection = ValueNotifier(null) {
    _syntaxHighlighter.attachToDocument(_document);

    _codeLines.value = [
      for (int i = 0; i < _syntaxHighlighter.lineCount; i += 1) //
        _syntaxHighlighter.getStyledLineAt(i)!,
    ];
  }

  @override
  void dispose() {
    _syntaxHighlighter.detachFromDocument();
    _codeLines.dispose();
    selection.dispose();
  }

  final CodeDocument _document;
  final CodeDocumentSyntaxHighlighter _syntaxHighlighter;

  @override
  int get lineCount => _document.lineCount;

  @override
  int getLineLength(int lineIndex) => _document.getLine(lineIndex)!.length;

  @override
  int getLineIndent(int lineIndex) => RegExp(r"^(\s*)").firstMatch(_document.getLine(lineIndex)!)!.end;

  @override
  ValueListenable<List<TextSpan>> get codeLines => _codeLines;
  final ValueNotifier<List<TextSpan>> _codeLines;

  @override
  final ValueNotifier<CodeSelection?> selection;

  @override
  void onClickDownAt(CodePosition codePosition, TextAffinity affinity) {
    selection.value = CodeSelection.collapsed(codePosition);
  }

  @override
  void onDoubleClickDownAt(CodePosition codePosition, TextAffinity affinity) {
    LexerToken? clickedToken = _document.findTokenAt(codePosition);

    if (clickedToken == null ||
        (clickedToken.kind == SyntaxKind.whitespace &&
            _document.offsetToCodePosition(clickedToken.start).characterOffset > 0)) {
      // We don't want to select whitespace in the middle of a code line on double-click.
      // Find a nearby token and select that instead.
      //
      // Note: Some lexers might choose not to tokenize whitespace, in which case whitespace
      // will have a null token.
      //
      // Note: We exclude cases where the token starts at offset `0` because that space is
      // indentation space, and we DO want to double click to select that.
      if (affinity == TextAffinity.downstream || codePosition.characterOffset == 0) {
        // Either we double clicked on the downstream edge of a character, or at the start of
        // a line. Select to the right.
        clickedToken = _document.findTokenToTheRightOnSameLine(codePosition, filter: nonWhitespace);
      } else {
        // Either we double clicked on the upstream edge of a character, or at the end of a line.
        // Select to the left.
        clickedToken = _document.findTokenToTheLeftOnSameLine(codePosition, filter: nonWhitespace);
      }

      if (clickedToken == null) {
        // We couldn't find a nearby non-whitespace token.
        return;
      }
    }

    if (clickedToken.kind == SyntaxKind.comment) {
      final line = _document.getLine(codePosition.line)!;
      final wordRange = CodeCommentSelection.findNearestSelectableToken(
        line,
        codePosition.characterOffset,
        affinity,
        ["///", "//"],
      );

      selection.value = CodeSelection(
        base: CodePosition(codePosition.line, wordRange.start),
        extent: CodePosition(codePosition.line, wordRange.end),
      );
      return;
    }

    selection.value = CodeSelection(
      base: _document.offsetToCodePosition(clickedToken.start),
      extent: _document.offsetToCodePosition(clickedToken.end),
    );
  }

  @override
  void onTripleClickDownAt(CodePosition codePosition, TextAffinity affinity) {
    // Select the whole line.
    selection.value = CodeSelection(
      base: CodePosition(codePosition.line, 0),
      extent: CodePosition(codePosition.line, _document.getLine(codePosition.line)!.length),
    );
  }
}

bool nonWhitespace(LexerToken token, CodePosition position) {
  return token.kind != SyntaxKind.whitespace;
}
