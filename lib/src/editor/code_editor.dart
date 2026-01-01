import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inception/inception.dart';

class CodeEditor extends StatefulWidget {
  const CodeEditor({
    super.key,
    required this.presenter,
    required this.style,
  });

  final CodeEditorPresenter presenter;
  final CodeEditorStyle style;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  final _focusNode = FocusNode(debugLabel: 'code-editor');

  final _codeLayoutKey = GlobalKey(debugLabel: 'code-layout');

  /// The preferred x-offset from the left side of the editor when the user
  /// moves the caret up/down lines.
  double? _preferredCaretXOffset;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onClickDown(TapDownDetails details) {
    final codeLayout = _codeLayoutKey.currentState as CodeLayout;
    final (codeTapPosition, affinity) = codeLayout.findCodePositionNearestGlobalOffset(details.globalPosition);

    widget.presenter.selection.value = CodeSelection.collapsed(codeTapPosition);

    _updatePreferredCaretXOffsetToMatchCurrentCaretOffset();

    // Ensure the editor has focus, now that the user has clicked it.
    _focusNode.requestFocus();

    // Optimistically set the drag start position, assuming this is a drag.
    _dragStartPosition = codeTapPosition;
  }

  void _onDoubleClickDown(TapDownDetails details) {
    final codeLayout = _codeLayoutKey.currentState as CodeLayout;
    final (codeTapPosition, affinity) = codeLayout.findCodePositionNearestGlobalOffset(details.globalPosition);

    widget.presenter.onDoubleClickAt(codeTapPosition, affinity);
  }

  void _onTripleClickDown(TapDownDetails details) {
    // TODO:
  }

  CodePosition? _dragStartPosition;

  void _onPanStart(DragStartDetails details) {
    if (_dragStartPosition == null) {
      // Ideally, the drag start position is set on tap down, but it seems that in some situations
      // a pan will start without first running a tap down call. We handle that here.
      final codeLayout = _codeLayoutKey.currentState as CodeLayout;
      _dragStartPosition = codeLayout.findCodePositionNearestGlobalOffset(details.globalPosition).$1;

      // Ensure the editor has focus, now that the user has clicked it.
      _focusNode.requestFocus();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final codeLayout = _codeLayoutKey.currentState as CodeLayout;
    final newExtent = codeLayout.findCodePositionNearestGlobalOffset(details.globalPosition).$1;

    // print("New extent: $newExtent");
    widget.presenter.selection.value = CodeSelection(base: _dragStartPosition!, extent: newExtent);

    _updatePreferredCaretXOffsetToMatchCurrentCaretOffset();
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStartPosition = null;
  }

  void _onPanCancel() {
    _dragStartPosition = null;
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent keyEvent) {
    if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
      // We don't care about up events.
      return KeyEventResult.ignored;
    }

    switch (keyEvent.logicalKey) {
      case LogicalKeyboardKey.keyA:
        if (HardwareKeyboard.instance.isMetaPressed) {
          widget.presenter.selection.value = CodeSelection(
            base: CodePosition.start,
            // FIXME: Pipe the CodeDocument through instead of using text spans for length
            extent: CodePosition(
              widget.presenter.codeLines.value.length - 1,
              widget.presenter.codeLines.value.last.toPlainText().length,
            ),
          );
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowLeft:
        final selection = widget.presenter.selection.value;
        if (selection == null) {
          return KeyEventResult.ignored;
        }

        if (selection.isCollapsed && !HardwareKeyboard.instance.isShiftPressed) {
          _pushCaretInDirection(_SelectionDirection.left);
        } else if (selection.isExpanded && !HardwareKeyboard.instance.isShiftPressed) {
          // The selection is expanded but shift isn't pressed. Instead of moving the
          // caret, just collapse the selection at the left/top.
          _collapseSelectionInDirection(_SelectionDirection.left);
        } else {
          // The selection might be collapsed or expanded, but we know the SHIFT key is
          // pressed, so we want to expand the selection either way.
          _expandSelectionInDirection(_SelectionDirection.left);
        }

        _updatePreferredCaretXOffsetToMatchCurrentCaretOffset();

        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        final selection = widget.presenter.selection.value;
        if (selection == null) {
          return KeyEventResult.ignored;
        }

        if (selection.isCollapsed && !HardwareKeyboard.instance.isShiftPressed) {
          _pushCaretInDirection(_SelectionDirection.right);
        } else if (selection.isExpanded && !HardwareKeyboard.instance.isShiftPressed) {
          // The selection is expanded but shift isn't pressed. Instead of moving the
          // caret, just collapse the selection at the right/bottom.
          _collapseSelectionInDirection(_SelectionDirection.right);
        } else {
          // The selection might be collapsed or expanded, but we know the SHIFT key is
          // pressed, so we want to expand the selection either way.
          _expandSelectionInDirection(_SelectionDirection.right);
        }

        _updatePreferredCaretXOffsetToMatchCurrentCaretOffset();

        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        final selection = widget.presenter.selection.value;
        if (selection == null) {
          return KeyEventResult.ignored;
        }

        if (selection.isCollapsed && !HardwareKeyboard.instance.isShiftPressed) {
          _pushCaretInDirection(_SelectionDirection.up);
        } else if (selection.isExpanded && !HardwareKeyboard.instance.isShiftPressed) {
          // The selection is expanded but shift isn't pressed. Instead of moving the
          // caret, just collapse the selection at the top/left.
          _collapseSelectionInDirection(_SelectionDirection.up);
        } else {
          // The selection might be collapsed or expanded, but we know the SHIFT key is
          // pressed, so we want to expand the selection either way.
          _expandSelectionInDirection(_SelectionDirection.up);
        }

        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        final selection = widget.presenter.selection.value;
        if (selection == null) {
          return KeyEventResult.ignored;
        }

        if (selection.isCollapsed && !HardwareKeyboard.instance.isShiftPressed) {
          _pushCaretInDirection(_SelectionDirection.down);
        } else if (selection.isExpanded && !HardwareKeyboard.instance.isShiftPressed) {
          // The selection is expanded but shift isn't pressed. Instead of moving the
          // caret, just collapse the selection at the bottom/end.
          _collapseSelectionInDirection(_SelectionDirection.down);
        } else {
          // The selection might be collapsed or expanded, but we know the SHIFT key is
          // pressed, so we want to expand the selection either way.
          _expandSelectionInDirection(_SelectionDirection.down);
        }

        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _pushCaretInDirection(_SelectionDirection direction) {
    final selection = widget.presenter.selection.value;
    if (selection == null) {
      return;
    }

    final newPosition = switch (direction) {
      _SelectionDirection.left => _codeLayout.findPositionBefore(selection.extent),
      _SelectionDirection.right => _codeLayout.findPositionAfter(selection.extent),
      _SelectionDirection.up => _codeLayout.findPositionInLineAbove(
          selection.extent,
          preferredXOffset: _preferredCaretXOffset,
        ),
      _SelectionDirection.down => _codeLayout.findPositionInLineBelow(
          selection.extent,
          preferredXOffset: _preferredCaretXOffset,
        ),
    };

    if (newPosition != null) {
      // Move the caret to the new position.
      widget.presenter.selection.value = CodeSelection.collapsed(newPosition);
    }
  }

  void _expandSelectionInDirection(_SelectionDirection direction) {
    final selection = widget.presenter.selection.value;
    if (selection == null) {
      return;
    }

    // The selection might be collapsed or expanded, but we know the SHIFT key is
    // pressed, so we want to expand the selection either way.
    final newExtent = switch (direction) {
      _SelectionDirection.left => _codeLayout.findPositionBefore(selection.extent),
      _SelectionDirection.right => _codeLayout.findPositionAfter(selection.extent),
      _SelectionDirection.up => _codeLayout.findPositionInLineAbove(
          selection.extent,
          preferredXOffset: _preferredCaretXOffset,
        ),
      _SelectionDirection.down => _codeLayout.findPositionInLineBelow(
          selection.extent,
          preferredXOffset: _preferredCaretXOffset,
        ),
    };

    if (newExtent != null) {
      // Move the extent to the new position.
      widget.presenter.selection.value = CodeSelection(base: selection.base, extent: newExtent);
    }
  }

  void _collapseSelectionInDirection(_SelectionDirection direction) {
    final selection = widget.presenter.selection.value;
    if (selection == null) {
      return;
    }

    final collapsedPosition = switch (direction) {
      _SelectionDirection.left => selection.start,
      _SelectionDirection.up => selection.start,
      _SelectionDirection.right => selection.end,
      _SelectionDirection.down => selection.end,
    };

    widget.presenter.selection.value = CodeSelection.collapsed(collapsedPosition);
  }

  void _updatePreferredCaretXOffsetToMatchCurrentCaretOffset() {
    final selection = widget.presenter.selection.value;
    if (selection == null) {
      return;
    }

    // Update the preferred caret x-offset.
    _preferredCaretXOffset = _codeLayout.getXForCaretInCodeLine(selection.extent);
  }

  CodeLinesState get _codeLayout => _codeLayoutKey.currentState as CodeLinesState;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onClickDown,
      onDoubleTapDown: _onDoubleClickDown,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            widget.presenter.codeLines,
            widget.presenter.selection,
          ]),
          builder: (context, child) {
            return CodeLines(
              key: _codeLayoutKey,
              codeLines: widget.presenter.codeLines.value,
              selection: widget.presenter.selection.value,
              style: CodeLinesStyle(
                gutterColor: widget.style.gutterColor,
                gutterBorderColor: widget.style.gutterBorderColor,
                lineBackgroundColor: widget.style.lineBackgroundColor,
                indentLineColor: widget.style.indentLineColor,
                baseTextStyle: widget.style.baseTextStyle,
              ),
            );
          },
        ),
      ),
    );
  }
}

class CodeEditorPresenter {
  CodeEditorPresenter(this._document, this._syntaxHighlighter)
      : _codeLines = ValueNotifier([]),
        selection = ValueNotifier(null) {
    _syntaxHighlighter.attachToDocument(_document);

    _codeLines.value = [
      for (int i = 0; i < _syntaxHighlighter.lineCount; i += 1) //
        _syntaxHighlighter.getStyledLineAt(i)!,
    ];
  }

  void dispose() {
    _syntaxHighlighter.detachFromDocument();
    _codeLines.dispose();
    selection.dispose();
  }

  final CodeDocument _document;
  final CodeDocumentSyntaxHighlighter _syntaxHighlighter;

  ValueListenable<List<TextSpan>> get codeLines => _codeLines;
  final ValueNotifier<List<TextSpan>> _codeLines;

  final ValueNotifier<CodeSelection?> selection;

  void onDoubleClickAt(CodePosition codePosition, TextAffinity affinity) {
    LexerToken? clickedToken = _document.findTokenAt(codePosition);
    if (clickedToken == null) {
      return;
    }

    if (clickedToken.kind == SyntaxKind.whitespace) {
      // We don't want to select whitespace on double-click. Find a nearby token and
      // select that instead.
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

    selection.value = CodeSelection(
      base: _document.offsetToCodePosition(clickedToken.start),
      extent: _document.offsetToCodePosition(clickedToken.end),
    );
  }
}

bool nonWhitespace(LexerToken token, CodePosition position) {
  return token.kind != SyntaxKind.whitespace;
}

enum _SelectionDirection {
  left,
  right,
  up,
  down;
}

class CodeEditorStyle {
  // TODO: Define a default light

  const CodeEditorStyle.defaultDark()
      : gutterColor = const Color(0xFF1E1E1E),
        gutterBorderColor = const Color(0xFF2E2E2E),
        lineBackgroundColor = const Color(0xFF1E1E1E),
        indentLineColor = const Color(0xFF222222),
        baseTextStyle = const TextStyle(color: Color(0xFFD4D4D4));

  const CodeEditorStyle({
    this.gutterColor = lineColor,
    required this.gutterBorderColor,
    required this.lineBackgroundColor,
    required this.indentLineColor,
    required this.baseTextStyle,
  });

  final Color gutterColor;

  final Color gutterBorderColor;

  final Color lineBackgroundColor;

  /// The color of little lines that appear on the upstream side of the code in the
  /// indentation area.
  final Color indentLineColor;

  /// The base text style, applied beneath the styles in [code], and also applied to the indent line spacing.
  final TextStyle baseTextStyle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeLinesStyle &&
          runtimeType == other.runtimeType &&
          gutterColor == other.gutterColor &&
          gutterBorderColor == other.gutterBorderColor &&
          lineBackgroundColor == other.lineBackgroundColor &&
          indentLineColor == other.indentLineColor &&
          baseTextStyle == other.baseTextStyle;

  @override
  int get hashCode =>
      gutterColor.hashCode ^
      gutterBorderColor.hashCode ^
      lineBackgroundColor.hashCode ^
      indentLineColor.hashCode ^
      baseTextStyle.hashCode;
}
