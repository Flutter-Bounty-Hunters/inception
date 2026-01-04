import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:inception/src/document/code_document.dart';
import 'package:inception/src/document/selection.dart';
import 'package:inception/src/editor/code_editor.dart';

/// A [CodeEditorPresenter] that's indented for use within tests.
///
/// This presenter doesn't contain any language-specific capabilities, and it doesn't
/// implement sophisticated interactions, like double-click and drag.
///
/// This presenter exposes [codeLines] as a notifier so that external code can change
/// the [codeLines] as if those changes came from a real `CodeDocument`. This allows tests
/// to verify visual behaviors without lexing a real `CodeDocument`, using a knowledge of
/// a real language.
class TestCodeEditorPresenter implements CodeEditorPresenter {
  TestCodeEditorPresenter()
      : codeLines = ValueNotifier([]),
        selection = ValueNotifier(null);

  @override
  void dispose() {
    codeLines.dispose();
    selection.dispose();
  }

  @override
  CodeDocument get document => throw UnimplementedError();

  @override
  int get lineCount => codeLines.value.length;

  @override
  int getLineLength(int lineIndex) => codeLines.value[lineIndex].toPlainText().length;

  @override
  int getLineIndent(int lineIndex) => RegExp(r"^(\s*)").firstMatch(codeLines.value[lineIndex].toPlainText())!.end;

  @override
  final ValueNotifier<List<TextSpan>> codeLines;

  @override
  final ValueNotifier<CodeSelection?> selection;

  @override
  void onClickDownAt(CodePosition codePosition, TextAffinity affinity) {
    // Place the caret.
    selection.value = CodeSelection.collapsed(codePosition);
  }

  @override
  void onDoubleClickDownAt(CodePosition codePosition, TextAffinity affinity) {
    // No-op.
  }

  @override
  void onTripleClickDownAt(CodePosition codePosition, TextAffinity affinity) {
    // No-op.
  }

  @override
  void moveCaretAheadOfTokenBefore(
    CodePosition searchStart, {
    bool expand = false,
  }) {}

  @override
  void moveCaretToEndOfTokenAfter(
    CodePosition searchStart, {
    bool expand = false,
  }) {}
}
