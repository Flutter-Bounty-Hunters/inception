import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:inception/inception.dart';
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

  @override
  void toggleSelectionComments() {
    // This method adds or removes comments from all selected lines. This implementation
    // doesn't account for indentation, because we don't yet have an AST to track code
    // blocks and their indentation.

    final currentSelection = selection.value;
    if (currentSelection == null) {
      return;
    }

    final selectionStartLine = currentSelection.start.line;
    final selectionEndLine = currentSelection.end.line;

    // Do a pass through all the lines to decide whether we're adding comments,
    // or removing them.
    final linesToCommentOut = <int>[];
    final linesToUncomment = <int>[];
    for (int lineIndex = selectionStartLine; lineIndex <= selectionEndLine; lineIndex += 1) {
      final documentOffset = document.lineColumnToOffset(lineIndex, 0);
      if (!document.text.startsWith("//", documentOffset)) {
        linesToCommentOut.add(lineIndex);
      } else {
        linesToUncomment.add(lineIndex);
      }
    }

    if (linesToCommentOut.isNotEmpty) {
      // By policy, if there are any lines without comments, we add comments
      // instead of remove them.
      var didAddCommentToBaseLine = false;
      var didAddCommentToExtentLine = false;
      for (final lineIndex in linesToCommentOut) {
        final documentOffset = document.lineColumnToOffset(lineIndex, 0);
        document.insert(documentOffset, "//");

        if (lineIndex == currentSelection.base.line) {
          didAddCommentToBaseLine = true;
        }
        if (lineIndex == currentSelection.extent.line) {
          didAddCommentToExtentLine = true;
        }
      }

      selection.value = CodeSelection(
        base: didAddCommentToBaseLine
            ? CodePosition(currentSelection.base.line, currentSelection.base.characterOffset + 2)
            : currentSelection.base,
        extent: didAddCommentToExtentLine
            ? CodePosition(currentSelection.extent.line, currentSelection.extent.characterOffset + 2)
            : currentSelection.extent,
      );
    } else {
      // We didn't find any uncommented lines, so we remove comments from them.
      var didRemoveCommentFromBaseLine = false;
      var didRemoveCommentFromExtentLine = false;
      for (final lineIndex in linesToUncomment) {
        final documentOffset = document.lineColumnToOffset(lineIndex, 0);
        document.delete(offset: documentOffset, count: "//".length);

        if (lineIndex == currentSelection.base.line) {
          didRemoveCommentFromBaseLine = true;
        }
        if (lineIndex == currentSelection.extent.line) {
          didRemoveCommentFromExtentLine = true;
        }
      }

      selection.value = CodeSelection(
        base: didRemoveCommentFromBaseLine
            ? CodePosition(currentSelection.base.line, currentSelection.base.characterOffset - 2)
            : currentSelection.base,
        extent: didRemoveCommentFromExtentLine
            ? CodePosition(currentSelection.extent.line, currentSelection.extent.characterOffset - 2)
            : currentSelection.extent,
      );
    }
  }
}
