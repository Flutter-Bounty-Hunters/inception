import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inception/src/document/selection.dart';
import 'package:inception/src/editor/code_layout.dart';
import 'package:inception/src/editor/theme.dart';
import 'package:super_editor/super_editor.dart' show TapSequenceGestureRecognizer;

class CodeEditor extends StatefulWidget {
  const CodeEditor({
    super.key,
    this.focusNode,
    required this.presenter,
    required this.style,
  });

  final FocusNode? focusNode;

  // TODO: The presenter handles the double click, so it should know the Dart vs Luau comment syntax
  final CodeEditorPresenter presenter;
  final CodeEditorStyle style;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late FocusNode _focusNode;

  final _codeLayoutKey = GlobalKey(debugLabel: 'code-layout');

  /// The preferred x-offset from the left side of the editor when the user
  /// moves the caret up/down lines.
  double? _preferredCaretXOffset;

  @override
  void initState() {
    super.initState();

    _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'code-editor');
  }

  @override
  void didUpdateWidget(covariant CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'code-editor');
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onClickDown(TapDownDetails details) {
    final codeLayout = _codeLayoutKey.currentState as CodeLayout;
    final (codeTapPosition, affinity) = codeLayout.findCodePositionNearestGlobalOffset(details.globalPosition);

    widget.presenter.onClickDownAt(codeTapPosition, affinity);

    _updatePreferredCaretXOffsetToMatchCurrentCaretOffset();

    // Ensure the editor has focus, now that the user has clicked it.
    _focusNode.requestFocus();

    // Optimistically set the drag start position, assuming this is a drag.
    _dragStartPosition = codeTapPosition;
  }

  void _onDoubleClickDown(TapDownDetails details) {
    final codeLayout = _codeLayoutKey.currentState as CodeLayout;
    final (codeTapPosition, affinity) = codeLayout.findCodePositionNearestGlobalOffset(details.globalPosition);

    widget.presenter.onDoubleClickDownAt(codeTapPosition, affinity);
  }

  void _onTripleClickDown(TapDownDetails details) {
    final codeLayout = _codeLayoutKey.currentState as CodeLayout;
    final (codeTapPosition, affinity) = codeLayout.findCodePositionNearestGlobalOffset(details.globalPosition);

    widget.presenter.onTripleClickDownAt(codeTapPosition, affinity);
  }

  CodePosition? _dragStartPosition;
  CodeSelection? _dragStartSelection;

  void _onPanStart(DragStartDetails details) {
    if (_dragStartPosition == null) {
      // Ideally, the drag start position is set on tap down, but it seems that in some situations
      // a pan will start without first running a tap down call. We handle that here.
      final codeLayout = _codeLayoutKey.currentState as CodeLayout;
      _dragStartPosition = codeLayout.findCodePositionNearestGlobalOffset(details.globalPosition).$1;

      // Ensure the editor has focus, now that the user has clicked it.
      _focusNode.requestFocus();
    }

    if (widget.presenter.selection.value?.isExpanded == true) {
      // The selection is expanded at drag start. This happens on a double-click-and-drag,
      // and a triple-click-and-drag. Record it, because we don't want any drag offset to
      // reduce the selection to less than this word or line.
      _dragStartSelection = widget.presenter.selection.value;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final codeLayout = _codeLayoutKey.currentState as CodeLayout;
    final newExtent = codeLayout.findCodePositionNearestGlobalOffset(details.globalPosition).$1;

    if (_dragStartSelection != null) {
      // The user started dragging with a double or triple click. In this case,
      // expand the original selection range to include the new extent, but don't
      // let the selection become less than it was when the dragging started. I.e.,
      // the original word or the original line will remain selected no matter where
      // the user drags.
      widget.presenter.selection.value = _dragStartSelection!.isDownstream
          ? CodeSelection(
              base: _dragStartSelection!.start <= newExtent ? _dragStartSelection!.start : _dragStartSelection!.end,
              extent: newExtent < _dragStartSelection!.start || newExtent > _dragStartSelection!.end
                  ? newExtent
                  : _dragStartSelection!.end,
            )
          : CodeSelection(
              base: newExtent <= _dragStartSelection!.end ? _dragStartSelection!.end : _dragStartSelection!.start,
              extent: newExtent < _dragStartSelection!.start || newExtent > _dragStartSelection!.end
                  ? newExtent
                  : _dragStartSelection!.start,
            );
    } else {
      // Select from the drag start position to the new extent.
      widget.presenter.selection.value = CodeSelection(base: _dragStartPosition!, extent: newExtent);
    }

    _updatePreferredCaretXOffsetToMatchCurrentCaretOffset();
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStartPosition = null;
    _dragStartSelection = null;
  }

  void _onPanCancel() {
    _dragStartPosition = null;
    _dragStartSelection = null;
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent keyEvent) {
    if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
      // We don't care about up events.
      return KeyEventResult.ignored;
    }

    switch (keyEvent.logicalKey) {
      case LogicalKeyboardKey.escape:
        print("Pressed ESC");
        if (widget.presenter.selection.value?.isExpanded == true) {
          print("Collapsing selection");
          widget.presenter.selection.value = CodeSelection.collapsed(widget.presenter.selection.value!.extent);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
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

    if (HardwareKeyboard.instance.isMetaPressed && direction.isHorizontal) {
      switch (direction) {
        case _SelectionDirection.left:
          if (selection.extent.characterOffset == 0) {
            // Jump to previous line.
            if (selection.extent.line > 0) {
              widget.presenter.selection.value = CodeSelection.collapsed(
                CodePosition(
                  selection.extent.line - 1,
                  widget.presenter.codeLines.value[selection.extent.line - 1].toPlainText().length,
                ),
              );
            }
          } else {
            final lineIndentOffset = widget.presenter.getLineIndent(selection.extent.line);

            if (selection.extent.characterOffset > lineIndentOffset) {
              // Jump left to where the code starts, after the indent.
              widget.presenter.selection.value = CodeSelection.collapsed(
                CodePosition(selection.extent.line, lineIndentOffset),
              );
            } else {
              // Jump all the way to the start of the line, before the indent.
              widget.presenter.selection.value = CodeSelection.collapsed(CodePosition(selection.extent.line, 0));
            }
          }
        case _SelectionDirection.right:
          final lineLength = widget.presenter.codeLines.value[selection.extent.line].toPlainText().length;

          if (selection.extent.characterOffset < lineLength) {
            // Move caret to end of current line.
            widget.presenter.selection.value = CodeSelection.collapsed(
              CodePosition(selection.extent.line, lineLength),
            );
          } else if (widget.presenter.codeLines.value.length > selection.extent.line + 1) {
            // Move caret to start of next line.
            widget.presenter.selection.value = CodeSelection.collapsed(
              CodePosition(selection.extent.line + 1, 0),
            );
          }
        default:
          throw Exception("Push direction said it was horizontal, but it wasn't.");
      }
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

    if (HardwareKeyboard.instance.isMetaPressed && direction.isHorizontal) {
      switch (direction) {
        case _SelectionDirection.left:
          if (selection.extent.characterOffset == 0) {
            // Jump to previous line.
            if (selection.extent.line > 0) {
              widget.presenter.selection.value = CodeSelection(
                base: selection.base,
                extent: CodePosition(
                  selection.extent.line - 1,
                  widget.presenter.codeLines.value[selection.extent.line - 1].toPlainText().length,
                ),
              );
            }
          } else {
            final lineIndentOffset = widget.presenter.getLineIndent(selection.extent.line);

            if (selection.extent.characterOffset > lineIndentOffset) {
              // Jump left to where the code starts, after the indent.
              widget.presenter.selection.value = CodeSelection(
                base: selection.base,
                extent: CodePosition(selection.extent.line, lineIndentOffset),
              );
            } else {
              // Jump all the way to the start of the line, before the indent.
              widget.presenter.selection.value = CodeSelection(
                base: selection.base,
                extent: CodePosition(selection.extent.line, 0),
              );
            }
          }
        case _SelectionDirection.right:
          final lineLength = widget.presenter.codeLines.value[selection.extent.line].toPlainText().length;

          if (selection.extent.characterOffset < lineLength) {
            // Move caret to end of current line.
            widget.presenter.selection.value = CodeSelection(
              base: selection.base,
              extent: CodePosition(selection.extent.line, lineLength),
            );
          } else if (widget.presenter.codeLines.value.length > selection.extent.line + 1) {
            // Move caret to start of next line.
            widget.presenter.selection.value = CodeSelection(
              base: selection.base,
              extent: CodePosition(selection.extent.line + 1, 0),
            );
          }
        default:
          throw Exception("Push direction said it was horizontal, but it wasn't.");
      }
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
    final gestureSettings = MediaQuery.maybeOf(context)?.gestureSettings;

    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        TapSequenceGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapSequenceGestureRecognizer>(
          () => TapSequenceGestureRecognizer(),
          (TapSequenceGestureRecognizer recognizer) {
            recognizer
              ..onTapDown = _onClickDown
              ..onDoubleTapDown = _onDoubleClickDown
              ..onTripleTapDown = _onTripleClickDown
              ..gestureSettings = gestureSettings;
          },
        ),
      },
      child: GestureDetector(
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
      ),
    );
  }
}

abstract class CodeEditorPresenter {
  void dispose();

  int get lineCount;

  int getLineLength(int lineIndex);

  int getLineIndent(int lineIndex);

  ValueListenable<List<TextSpan>> get codeLines;

  ValueNotifier<CodeSelection?> get selection;

  void onClickDownAt(CodePosition codePosition, TextAffinity affinity);

  void onDoubleClickDownAt(CodePosition codePosition, TextAffinity affinity);

  void onTripleClickDownAt(CodePosition codePosition, TextAffinity affinity);
}

enum _SelectionDirection {
  left,
  right,
  up,
  down;

  bool get isHorizontal => this == left || this == right;

  bool get isVertical => this == up || this == down;
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
