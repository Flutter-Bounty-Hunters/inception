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

  void _onTapDown(TapDownDetails details) {
    final codeLayout = _codeLayoutKey.currentState as CodeLinesLayout;
    final codeTapPosition = codeLayout.findCodePositionNearestGlobalOffset(details.globalPosition);

    widget.presenter.selection.value = CodeSelection.collapsed(codeTapPosition);

    // Ensure the editor has focus, now that the user has clicked it.
    _focusNode.requestFocus();
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent keyEvent) {
    if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
      // We don't care about up events.
      return KeyEventResult.ignored;
    }

    switch (keyEvent.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        final selection = widget.presenter.selection.value;
        if (selection == null) {
          return KeyEventResult.ignored;
        }

        if (selection.isCollapsed) {
          final nextPosition = _codeLayout.findPositionAfter(selection.extent);
          if (nextPosition != null) {
            // Move the caret to the next position.
            widget.presenter.selection.value = CodeSelection.collapsed(nextPosition);
          }
        } else {
          // TODO: Handle expanded selection
        }

        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        final selection = widget.presenter.selection.value;
        if (selection == null) {
          return KeyEventResult.ignored;
        }

        if (selection.isCollapsed) {
          final nextPosition = _codeLayout.findPositionBefore(selection.extent);
          if (nextPosition != null) {
            // Move the caret to the next position.
            widget.presenter.selection.value = CodeSelection.collapsed(nextPosition);
          }
        } else {
          // TODO: Handle expanded selection
        }

        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  CodeLinesState get _codeLayout => _codeLayoutKey.currentState as CodeLinesState;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
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
  CodeEditorPresenter()
      : codeLines = ValueNotifier([]),
        selection = ValueNotifier(null);

  void dispose() {
    codeLines.dispose();
    selection.dispose();
  }

  final ValueNotifier<List<TextSpan>> codeLines;
  final ValueNotifier<CodeSelection?> selection;
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
