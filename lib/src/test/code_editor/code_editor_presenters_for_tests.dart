import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:inception/src/document/selection.dart';
import 'package:inception/src/editor/code_editor.dart';

/// A [CodeEditorPresenter] that only contains visual information, e.g., the [codeLines]
/// to display and the [selection] to render, without any backing [CodeDocument].
///
/// This presenter is meant for tests that want to verify various editor UI details, without
/// creating a backing document that is then tokenized in precisely the desired way. Instead,
/// tests can set whatever [codeLines] they want.
class DisplayOnlyCodeEditorPresenter implements CodeEditorPresenter {
  DisplayOnlyCodeEditorPresenter()
      : codeLines = ValueNotifier([]),
        selection = ValueNotifier(null);

  @override
  void dispose() {
    codeLines.dispose();
    selection.dispose();
  }

  @override
  final ValueNotifier<List<TextSpan>> codeLines;

  @override
  final ValueNotifier<CodeSelection?> selection;

  @override
  void onClickDownAt(CodePosition codePosition, TextAffinity affinity) {
    // No-op.
  }

  @override
  void onDoubleClickDownAt(CodePosition codePosition, TextAffinity affinity) {
    // No-op.
  }

  @override
  void onTripleClickDownAt(CodePosition codePosition, TextAffinity affinity) {
    // No-op.
  }
}
