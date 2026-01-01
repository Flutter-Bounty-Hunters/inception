import 'dart:math' as math;
import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inception/src/document/selection.dart';
import 'package:inception/src/editor/theme.dart';
import 'package:inception/src/infrastructure/flutter_extensions/border_box.dart';
import 'package:inception/src/infrastructure/flutter_extensions/render_box_extensions.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_text_layout/super_text_layout.dart';

// TODO: Define and implement a CodeLinesLayout, similar to CodeLineLayout, but
//       for the whole file.
// TODO: Refactor CodeLines to display in a ContentLayers widget.

/// Widget that displays all the lines of source within a given file or sample.
class CodeLines extends StatefulWidget {
  const CodeLines({
    super.key,
    required this.codeLines,
    this.shadowCaretPosition,
    this.selection,
    // this.perLineOverlays = const [],
    // this.perLineUnderlays = const [],
    required this.style,
  });

  /// All lines of source code, with syntax highlighting already applied.
  final List<TextSpan> codeLines;

  final CodePosition? shadowCaretPosition;

  final CodeSelection? selection;

  // final List<CodeLineLayerWidgetBuilder> perLineUnderlays;
  //
  // final List<CodeLineLayerWidgetBuilder> perLineOverlays;

  final CodeLinesStyle style;

  @override
  State<CodeLines> createState() => CodeLinesState();
}

class CodeLinesState extends State<CodeLines> implements CodeLayout {
  // We track the previous frame line keys so we know which lines disappeared
  // since the last frame and can clear them from `_lineKeys`.
  final _previousFrameLineKeys = <int, GlobalKey>{};
  final _lineKeys = <int, GlobalKey>{};

  CodePosition? get caretPosition => widget.selection?.extent;

  @override
  CodePosition? findPositionBefore(CodePosition position) {
    if (position.line < 0 || position.characterOffset < 0) {
      throw Exception(
        "Tried to access a CodePosition ($position) but the line and/or character offset is negative, which is invalid.",
      );
    }

    if (position.line == 0 && position.characterOffset == 0) {
      // At the start of the document.
      return null;
    } else if (position.characterOffset == 0) {
      // Move to end of line above.
      return CodePosition(position.line - 1, widget.codeLines[position.line - 1].toPlainText().length);
    } else {
      // Move left one character.
      return CodePosition(position.line, position.characterOffset - 1);
    }
  }

  @override
  CodePosition? findPositionAfter(CodePosition position) {
    if (position.line > widget.codeLines.length ||
        position.characterOffset > widget.codeLines[position.line].toPlainText().length) {
      throw Exception(
        "Tried to access a CodePosition ($position) that's beyond the end of the code document (${widget.codeLines.length - 1} lines, ${widget.codeLines.last.toPlainText().length} characters).",
      );
    }

    if (position.line == widget.codeLines.length - 1 &&
        position.characterOffset == widget.codeLines.last.toPlainText().length) {
      // At end of the document.
      return null;
    } else if (position.characterOffset == widget.codeLines[position.line].toPlainText().length) {
      // Move to start of next line.
      return CodePosition(position.line + 1, 0);
    } else {
      // Move one character to the right.
      return CodePosition(position.line, position.characterOffset + 1);
    }
  }

  @override
  CodePosition findEndPosition() => CodePosition(
        widget.codeLines.length - 1,
        widget.codeLines.last.toPlainText().length,
      );

  @override
  CodePosition? findPositionInLineAbove(CodePosition position, {double? preferredXOffset}) {
    if (position.line <= 0 || position.line > widget.codeLines.length) {
      return null;
    }

    final lineAboveIndex = position.line - 1;
    final codeLine = _lineKeys[lineAboveIndex]!.asCodeLine;
    if (preferredXOffset != null) {
      return codeLine.findCodePositionNearestLocalOffset(Offset(preferredXOffset, 0)).$1;
    } else {
      return CodePosition(
        lineAboveIndex,
        min(position.characterOffset, widget.codeLines[lineAboveIndex].toPlainText().length),
      );
    }
  }

  @override
  CodePosition? findPositionInLineBelow(CodePosition position, {double? preferredXOffset}) {
    if (position.line >= widget.codeLines.length || position.line < -1) {
      return null;
    }

    final lineBelowIndex = position.line + 1;
    final codeLine = _lineKeys[lineBelowIndex]!.asCodeLine;
    if (preferredXOffset != null) {
      return codeLine.findCodePositionNearestLocalOffset(Offset(preferredXOffset, 0)).$1;
    } else {
      return CodePosition(
        lineBelowIndex,
        min(position.characterOffset, widget.codeLines[lineBelowIndex].toPlainText().length),
      );
    }
  }

  @override
  CodeRange? findWordBoundaryAtGlobalOffset(Offset globalOffset) {
    final line = _findLineLayoutAtGlobalOffset(globalOffset);
    if (line == null) {
      return null;
    }

    return line.findWordBoundaryAtGlobalOffset(globalOffset);
  }

  @override
  CodeRange? findWordBoundaryAtLocalOffset(Offset localOffset) {
    final globalOffset = (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
    return findWordBoundaryAtGlobalOffset(globalOffset);
  }

  @override
  (CodePosition, TextAffinity) findCodePositionNearestGlobalOffset(Offset globalOffset) {
    for (int lineIndex in _lineKeys.keys) {
      final lineKey = _lineKeys[lineIndex];
      assert(
        lineKey != null,
        "A key in the _lineKeys points to a null line (line $lineIndex). All map entries should point to GlobalKeys.",
      );
      if (lineKey!.currentState == null) {
        // The line `GlobalKey` isn't bound to any `State`. This means that the line isn't visible so
        // we ignore it. We have some behavior to try to throw away unused keys, and ideally this situation
        // would never happen, but the lines are built at the discretion of our `TwoDimensionalScrollableDelegate`
        // so we don't know when any specific line is thrown away.
        continue;
      }
      final lineLayout = lineKey.asCodeLine;
      if (!lineLayout.containsGlobalYValue(globalOffset.dy)) {
        continue;
      }

      return lineLayout.findCodePositionNearestGlobalOffset(globalOffset);
    }

    return (const CodePosition(0, 0), TextAffinity.downstream);
  }

  @override
  (CodePosition, TextAffinity) findCodePositionNearestLocalOffset(Offset localOffset) {
    final globalOffset = (context.findRenderObject() as RenderBox).localToGlobal(localOffset);
    return findCodePositionNearestGlobalOffset(globalOffset);
  }

  @override
  List<TextBox> getSelectionBoxesForCodeRange(CodeRange codeRange) {
    final boxes = <TextBox>[];

    // Add the boxes for the first selected line, which may start at the middle of the line.
    final firstCodeLine = _lineKeys[codeRange.start.line]!.asCodeLine;
    final firstCodeLineBoxes = firstCodeLine.getBoxesForSelection(
      TextSelection(
        baseOffset: codeRange.start.characterOffset,
        extentOffset: codeRange.start.line == codeRange.end.line
            ? codeRange.end.characterOffset
            : widget.codeLines.first.toPlainText().length,
      ),
    );
    boxes.addAll(_mapCodeLineTextBoxesToLayoutTextBoxes(codeRange.start.line, firstCodeLineBoxes));

    // Add the boxes for the lines between the first and the last, which are fully selected.
    for (int lineIndex = codeRange.start.line + 1; lineIndex < codeRange.end.line - 1; lineIndex += 1) {
      final codeLine = _lineKeys[lineIndex]!.asCodeLine;
      final codeLineBoxes = codeLine.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: widget.codeLines[lineIndex].toPlainText().length,
        ),
      );
      boxes.addAll(_mapCodeLineTextBoxesToLayoutTextBoxes(lineIndex, codeLineBoxes));
    }

    // Add the boxes for the last selected line, which may end at the middle of the line.
    if (codeRange.start.line != codeRange.end.line) {
      final lastCodeLine = _lineKeys[codeRange.end.line]!.asCodeLine;
      final lastCodeLineBoxes = lastCodeLine.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: codeRange.end.characterOffset,
        ),
      );
      boxes.addAll(_mapCodeLineTextBoxesToLayoutTextBoxes(codeRange.end.line, lastCodeLineBoxes));
    }

    return boxes;
  }

  List<TextBox> _mapCodeLineTextBoxesToLayoutTextBoxes(int lineIndex, List<TextBox> boxes) {
    final layoutRenderBox = context.findRenderObject() as RenderBox;
    final codeLineRenderBox = _lineKeys[lineIndex]!.currentContext!.findRenderObject() as RenderBox;

    return boxes.map(
      (textBox) {
        final topLeft = layoutRenderBox.globalToLocal(
          codeLineRenderBox.localToGlobal(Offset(textBox.left, textBox.top)),
        );

        final bottomRight = layoutRenderBox.globalToLocal(
          codeLineRenderBox.localToGlobal(Offset(textBox.right, textBox.bottom)),
        );

        return TextBox.fromLTRBD(
          topLeft.dx,
          topLeft.dy,
          bottomRight.dx,
          bottomRight.dy,
          TextDirection.ltr,
        );
      },
    ).toList();
  }

  CodeLineLayout _findLineLayoutNearestGlobalOffset(Offset globalOffset) {
    // First, check if the offset is above/below all lines and return
    // the nearest.
    final linesBox = context.findRenderObject() as RenderBox;
    final linesTopLeft = linesBox.localToGlobal(Offset.zero);
    if (globalOffset.dy < linesTopLeft.dy) {
      return _lineKeys[0]!.asCodeLine;
    }
    if (globalOffset.dy > linesTopLeft.dy + linesBox.size.height) {
      return _lineKeys[_lineKeys.length]!.asCodeLine;
    }

    // The offset is somewhere within the lines. Find the line that
    // contains the offset.
    for (int lineIndex in _lineKeys.keys) {
      final lineLayout = _lineKeys[lineIndex]!.asCodeLine;
      if (!lineLayout.containsGlobalYValue(globalOffset.dy)) {
        continue;
      }

      return lineLayout;
    }

    throw Exception("Tried to find the nearest code line to global offset ($globalOffset) but didn't find one.");
  }

  CodeLineLayout? _findLineLayoutAtGlobalOffset(Offset globalOffset) {
    for (int lineIndex in _lineKeys.keys) {
      final lineLayout = _lineKeys[lineIndex]!.asCodeLine;
      if (!lineLayout.containsGlobalYValue(globalOffset.dy)) {
        continue;
      }

      return lineLayout;
    }

    return null;
  }

  @override
  Rect getLocalRectForCodePosition(CodePosition position) {
    final codeLineBox = _lineKeys[position.line]!.currentContext!.findRenderObject() as RenderBox;
    final codeLine = _lineKeys[position.line]!.asCodeLine;
    final codeLinePositionRect = codeLine.getLocalRectForCharacter(position.characterOffset);

    final codeLinesBox = context.findRenderObject() as RenderBox;
    return codeLineBox.localRectToGlobal(codeLinePositionRect, ancestor: codeLinesBox);
  }

  @override
  Rect getLocalRectForCaret(CodePosition position) {
    final codeLineBox = _lineKeys[position.line]!.currentContext!.findRenderObject() as RenderBox;
    final codeLine = _lineKeys[position.line]!.asCodeLine;
    final codeLineCaretRect = codeLine.getLocalRectForCaret(position.characterOffset);

    final codeLinesBox = context.findRenderObject() as RenderBox;
    return codeLineBox.localRectToGlobal(codeLineCaretRect, ancestor: codeLinesBox);
  }

  @override
  double getXForCaretInCodeLine(CodePosition position) {
    final codeLine = _lineKeys[position.line]!.asCodeLine;
    return codeLine.getLocalXForCaret(position.characterOffset);
  }

  @override
  Widget build(BuildContext context) {
    _previousFrameLineKeys
      ..clear()
      ..addAll(_lineKeys);
    _lineKeys.clear();

    final codeLines = ColoredBox(
      color: widget.style.lineBackgroundColor,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: widget.codeLines.isNotEmpty
            ? CodeScroller(
                delegate: TwoDimensionalChildBuilderDelegate(
                  maxXIndex: 1,
                  maxYIndex: widget.codeLines.length - 1,
                  builder: (context, vicinity) {
                    if (vicinity.xIndex == 0) {
                      return _buildLineIndicator(vicinity.yIndex);
                    }

                    return _buildCodeLine(vicinity.yIndex);
                  },
                ),
              )
            : const SizedBox(),
      ),
    );

    // We're done building lines and re-using existing keys. Throw away all the keys we
    // no longer need.
    _previousFrameLineKeys.clear();

    return codeLines;
  }

  Widget _buildLineIndicator(int lineIndex) {
    return Container(
      decoration: BoxDecoration(
        color: widget.style.gutterColor,
        border: Border(right: BorderSide(color: widget.style.gutterBorderColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Text(
          " ${lineIndex + 1}",
          textAlign: TextAlign.right,
          style: widget.style.baseTextStyle.copyWith(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeLine(int lineIndex) {
    final key = _previousFrameLineKeys[lineIndex] ?? GlobalKey(debugLabel: "Code line: $lineIndex");
    _lineKeys[lineIndex] = key;

    return CodeLine(
      key: key,
      lineNumber: lineIndex,
      code: widget.codeLines[lineIndex],
      selection: _calculateLineSelection(lineIndex),
      hasStart: widget.selection?.start.line == lineIndex,
      hasEnd: widget.selection?.end.line == lineIndex,
      hasCaret: widget.selection?.extent.line == lineIndex,
      shadowCaretPosition: widget.shadowCaretPosition?.line == lineIndex
          ? TextPosition(offset: widget.shadowCaretPosition!.characterOffset)
          : null,
      // TODO: Pipe style controls through to CodeLines widget
      style: CodeLineStyle(
        indentLineColor: widget.style.indentLineColor,
        baseTextStyle: widget.style.baseTextStyle,
        shadowCaretColor: Colors.grey.shade700,
        selectionBoxColor: Colors.blueGrey,
        caretColor: Colors.yellowAccent,
      ),
    );
  }

  TextSelection? _calculateLineSelection(int lineIndex) {
    final documentSelection = widget.selection;
    if (documentSelection == null) {
      return null;
    }
    if (documentSelection.start.line > lineIndex || documentSelection.end.line < lineIndex) {
      // The selection doesn't include this line.
      return null;
    }

    // print("Calculating selection for line $lineIndex");
    // print(" - Doc selection start line: ${documentSelection.start.line}");
    // print(" - Doc selection end line: ${documentSelection.end.line}");
    final lineSelection = documentSelection.isDownstream
        ? TextSelection(
            baseOffset: documentSelection.start.line == lineIndex ? documentSelection.start.characterOffset : 0,
            extentOffset: documentSelection.end.line == lineIndex
                ? documentSelection.end.characterOffset
                : widget.codeLines[lineIndex].toPlainText().length,
          )
        : TextSelection(
            baseOffset: documentSelection.end.line == lineIndex
                ? documentSelection.end.characterOffset
                : widget.codeLines[lineIndex].toPlainText().length,
            extentOffset: documentSelection.start.line == lineIndex ? documentSelection.start.characterOffset : 0,
          );
    // print(" - Line selection: $lineSelection");

    return lineSelection;
  }
}

class CodeLinesStyle {
  // TODO: Define a default light

  const CodeLinesStyle.dark()
      : gutterColor = const Color(0xFF1E1E1E),
        gutterBorderColor = const Color(0xFF2E2E2E),
        lineBackgroundColor = const Color(0xFF1E1E1E),
        indentLineColor = const Color(0xFF222222),
        baseTextStyle = const TextStyle(color: Color(0xFFD4D4D4));

  const CodeLinesStyle({
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

extension CodeLinesLayoutFromContext on GlobalKey {
  /// Assumes this [GlobalKey] is attached to a [CodeLines] widget, and returns
  /// the [CodeLayout] for the code layout.
  ///
  /// This method is a verbosity reduction for repeated access of code layout.
  CodeLayout get asCodeLines => currentState as CodeLayout;
}

abstract interface class CodeLayout {
  /// Returns the [CodePosition] immediately preceding [position], or `null` if the [position]
  /// is at the start of the code document.
  ///
  /// {@template code_document_convenience}
  /// This information could be pulled from the [CodeDocument], but its implemented
  /// in [CodeLayout] for convenience for use-cases that may not have easy access
  /// to the associated [CodeDocument].
  /// {@endtemplate}
  CodePosition? findPositionBefore(CodePosition position);

  /// Returns the [CodePosition] immediately following [position], or `null` if the [position]
  /// is at the end of the code document.
  ///
  /// {@macro code_document_convenience}
  CodePosition? findPositionAfter(CodePosition position);

  /// Returns the [CodePosition] that points to the end of the code document.
  ///
  /// {@macro code_document_convenience}
  CodePosition findEndPosition();

  /// Returns the [CodePosition] in the line above [position], choosing a character offset that's
  /// near the [preferredXOffset], or if it's `null`, choosing a character offset as close as possible
  /// to [position.characterOffset].
  CodePosition? findPositionInLineAbove(CodePosition position, {double? preferredXOffset});

  /// Returns the [CodePosition] in the line below [position], choosing a character offset that's
  /// near the [preferredXOffset], or if it's `null`, choosing a character offset as close as possible
  /// to [position.characterOffset].
  CodePosition? findPositionInLineBelow(CodePosition position, {double? preferredXOffset});

  /// Returns the bounds that surround the word that appears at the given
  /// [globalOffset].
  CodeRange? findWordBoundaryAtGlobalOffset(Offset globalOffset);

  /// Returns the bounds that surround the word that appears at the given
  /// [localOffset].
  CodeRange? findWordBoundaryAtLocalOffset(Offset localOffset);

  /// Returns the [CodePosition] nearest to the given [globalOffset].
  (CodePosition, TextAffinity) findCodePositionNearestGlobalOffset(Offset globalOffset);

  /// Returns the [CodePosition] nearest to the given [localOffset].
  (CodePosition, TextAffinity) findCodePositionNearestLocalOffset(Offset localOffset);

  /// Returns the [Rect] that surrounds the character at the given [position].
  Rect getLocalRectForCodePosition(CodePosition position);

  /// Returns the [Rect] where the caret would appear **before** the given [position].
  ///
  /// The returned [Rect] is a conceptual caret - its x-offset starts either 1px before
  /// a character, or immediately after a character, it's width is 1px, and its height is
  /// equal to the line height.
  ///
  /// There is no requirement that an editor render a caret with this [Rect]. An editor
  /// can choose to render a wider caret, taller caret, shorter caret. Rather, this [Rect]
  /// should be thought of as a line segment between characters, and then used to calculate
  /// any relevant information based on that.
  Rect getLocalRectForCaret(CodePosition position);

  /// Returns the x-offset where the caret would appear, if the caret were displayed at the
  /// given [position], i.e., the x-offset between two sequential characters, or before/after
  /// the first/last character.
  ///
  /// The x-offset is measured from the start of the text portion of the line of code, ignoring any
  /// gutter direction on the left, and ignoring any horizontal scroll offset.
  ///
  /// This x-offset isn't necessarily used by an editor to display the caret. An editor is free
  /// to choose whatever offset, width, and height it desired for the caret. Rather, this x-offset
  /// is made available for any layout calculations that want to operate between characters, instead
  /// of within a given character.
  double getXForCaretInCodeLine(CodePosition position);

  /// Returns a list of [TextBox]es that bound the content selected in the given [codeRange],
  /// in local coordinates.
  ///
  /// See also:
  ///
  ///  * [RenderParagraph.getBoxesForSelection].
  List<TextBox> getSelectionBoxesForCodeRange(CodeRange codeRange);
}

/// Widget that displays a single line of code text.
class CodeLine extends StatefulWidget {
  const CodeLine({
    super.key,
    required this.lineNumber,
    required this.code,
    this.shadowCaretPosition,
    this.selection,
    this.hasStart = false,
    this.hasEnd = false,
    this.hasCaret = false,
    required this.style,
    // this.overlays = const [],
    // this.underlays = const [],
    this.debugPaint = CodeLineDebugPaint.empty,
  });

  /// Line number for this line within its overall source file, starting at zero.
  final int lineNumber;

  /// The styled code to display in this line.
  final TextSpan code;

  final TextPosition? shadowCaretPosition;

  final TextSelection? selection;

  final bool hasStart;
  final bool hasEnd;
  final bool hasCaret;

  final CodeLineStyle style;

// TODO: Define a contract for CodeLineLayerWidgetBuilder, which takes in all
//       info about a code line (including layout) and builds widgets based on it.
  // final List<CodeLineLayerWidgetBuilder> underlays;
  //
  // final List<CodeLineLayerWidgetBuilder> overlays;

  final CodeLineDebugPaint debugPaint;

  @override
  State<CodeLine> createState() => _CodeLineState();
}

class _CodeLineState extends State<CodeLine> implements CodeLineLayout {
  final _codeTextKey = GlobalKey();

  @override
  int get lineNumber => widget.lineNumber;

  @override
  bool containsGlobalOffset(Offset globalOffset) {
    final myBox = context.findRenderObject() as RenderBox;
    final myOffset = myBox.localToGlobal(Offset.zero);
    final myRect = myOffset & myBox.size;
    return myRect.contains(globalOffset);
  }

  @override
  bool containsGlobalYValue(double y) {
    final myBox = context.findRenderObject() as RenderBox;
    final myOffset = myBox.localToGlobal(Offset.zero);
    final myRect = myOffset & myBox.size;
    return myRect.top <= y && y <= myRect.bottom;
  }

  @override
  CodeRange? findWordBoundaryAtGlobalOffset(Offset globalOffset) {
    final localOffset = (context.findRenderObject() as RenderBox).globalToLocal(globalOffset);
    return findWordBoundaryAtLocalOffset(localOffset);
  }

  @override
  CodeRange? findWordBoundaryAtLocalOffset(Offset localOffset) {
    final codeLineBox = context.findRenderObject() as RenderBox;
    final localRect = Offset.zero & codeLineBox.size;
    if (!localRect.contains(localOffset)) {
      return null;
    }

    final textRenderBox = _textRenderBox;
    final paragraphLocalOffset = textRenderBox.globalToLocal(localOffset, ancestor: codeLineBox);
    //print("Local offset: $paragraphLocalOffset");

    final textLayout = _textLayout;
    final textPosition = textLayout.getPositionNearestToOffset(paragraphLocalOffset);
    //print("Text position: $textPosition");
    final wordRange = textLayout.getWordSelectionAt(textPosition);
    //print("Word range: $wordRange");
    //ðprint("Word: '${renderParagraph.text.toPlainText().substring(wordRange.start, wordRange.end)}'");
    return CodeRange(
      CodePosition(widget.lineNumber, wordRange.start),
      CodePosition(widget.lineNumber, wordRange.end),
    );
  }

  @override
  (CodePosition, TextAffinity) findCodePositionNearestGlobalOffset(Offset globalOffset) {
    final localOffset = (_codeTextKey.currentContext!.findRenderObject() as RenderBox).globalToLocal(globalOffset);
    return findCodePositionNearestLocalOffset(localOffset);
  }

  @override
  (CodePosition, TextAffinity) findCodePositionNearestLocalOffset(Offset localOffset) {
    final textPosition = _textLayout.getPositionNearestToOffset(localOffset);

    // Figure out proximity -> affinity.
    late final TextAffinity affinity;
    final characterRect = _textLayout.getCharacterBox(textPosition)!.toRect();
    if (localOffset.dy < characterRect.top) {
      // The search offset is above the text. This is the "nearest" position because
      // as a matter of policy, when searching above text, we report the beginning of
      // the text as the nearest position.
      affinity = TextAffinity.upstream;
    } else if (localOffset.dy > characterRect.bottom) {
      // The search offset is below the text. This is the "nearest" position because
      // as a matter of policy, when searching below text, we report the end of the
      // text as the nearest position.
      affinity = TextAffinity.downstream;
    } else {
      // The search offset is vertically within the line of text. Report affinity
      // based on whichever horizontal edge is closer.
      affinity = (characterRect.left - localOffset.dx).abs() > (characterRect.right - localOffset.dx).abs()
          ? TextAffinity.downstream
          : TextAffinity.upstream;
    }

    return (CodePosition(widget.lineNumber, textPosition.offset), affinity);
  }

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    final boxes = _textLayout.getBoxesForSelection(
      selection,
      boxHeightStyle: BoxHeightStyle.max,
      boxWidthStyle: BoxWidthStyle.max,
    );

    final lineBox = context.findRenderObject() as RenderBox;
    final textRenderBox = _textRenderBox;

    return boxes.map(
      (textBox) {
        final topLeft = lineBox.globalToLocal(
          textRenderBox.localToGlobal(Offset(textBox.left, textBox.top)),
        );
        final bottomRight = lineBox.globalToLocal(
          textRenderBox.localToGlobal(Offset(textBox.right, textBox.bottom)),
        );

        return TextBox.fromLTRBD(
          topLeft.dx,
          topLeft.dy,
          bottomRight.dx,
          bottomRight.dy,
          TextDirection.ltr,
        );
      },
    ).toList();
  }

  @override
  Rect getLocalRectForCharacter(int characterOffset) {
    final localCharacterRect = _textLayout.getCharacterBox(TextPosition(offset: characterOffset))!.toRect();
    final codeLineBox = context.findRenderObject() as RenderBox;
    return _textRenderBox.localRectToGlobal(localCharacterRect, ancestor: codeLineBox);
  }

  @override
  Rect getLocalRectForCaret(int characterOffset) {
    final textPosition = TextPosition(offset: characterOffset);
    final localCharacterRect =
        _textLayout.getOffsetForCaret(textPosition) & Size(1, _textLayout.getHeightForCaret(textPosition)!);
    final codeLineBox = context.findRenderObject() as RenderBox;
    return _textRenderBox.localRectToGlobal(localCharacterRect, ancestor: codeLineBox);
  }

  @override
  double getLocalXForCaret(int characterOffset) {
    final textLayoutOffset = _textLayout.getOffsetForCaret(TextPosition(offset: characterOffset));
    final codeLineBox = context.findRenderObject() as RenderBox;
    final codeLineOffset = _textRenderBox.localToGlobal(textLayoutOffset, ancestor: codeLineBox).dx;

    return codeLineOffset;
  }

  RenderBox get _textRenderBox => _codeTextKey.currentContext!.findRenderObject() as RenderBox;

  ProseTextLayout get _textLayout =>
      (_codeTextKey.currentContext!.findRenderObject() as RenderSuperTextLayout).state.textLayout;

  @override
  Widget build(BuildContext context) {
    // if (widget.selection != null) {
    //   print(
    //       "Line ${widget.lineNumber} has selection: ${widget.selection}, has base: ${widget.hasStart}, has extent: ${widget.hasEnd}");
    // }

    final caretPosition = widget.selection?.extent;

    // if (widget.shadowCaretPosition != null) {
    //   print("Line ${widget.lineNumber} has shadow caret at: ${widget.shadowCaretPosition}");
    // }

    return BorderBox(
      color: widget.debugPaint.lineBoundaryColor,
      isEnabled: widget.debugPaint.lineBoundaryColor != null,
      child: BoxContentLayers(
        content: (context) => Stack(
          children: [
            _buildVerticalTabLines(),
            BorderBox(
              color: widget.debugPaint.textBoundaryColor,
              isEnabled: widget.debugPaint.textBoundaryColor != null,
              child: Padding(
                // Push off from left edge, also add a little space on top and bottom so the caret
                // doesn't go all the way to the previous/next lines.
                padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
                child: SuperText(
                  key: _codeTextKey,
                  richText: TextSpan(
                    style: widget.style.baseTextStyle,
                    children: [widget.code],
                  ),
                  layerBeneathBuilder: (context, layout) {
                    // final selectionBoxWidgets = <Widget>[];
                    //
                    // final lineSelection = widget.selection;
                    // if (lineSelection != null) {
                    //   final paintToStartOfLine = lineSelection.start == 0 && !widget.hasStart;
                    //   final paintToEndOfLine = lineSelection.end == widget.code.toPlainText().length && !widget.hasEnd;
                    //
                    //   final selectionBoxLeft = paintToStartOfLine
                    //       ? 0.0
                    //       : layout
                    //           .getOffsetForCaret(
                    //             TextPosition(offset: lineSelection.start),
                    //           )
                    //           .dx;
                    //   // print(" - selection offset left: $selectionBoxLeft");
                    //   final selectionBoxRight = paintToEndOfLine
                    //       ? 0.0
                    //       : layout
                    //               .getOffsetForCaret(
                    //                 TextPosition(offset: widget.code.toPlainText().length),
                    //               )
                    //               .dx -
                    //           layout
                    //               .getOffsetForCaret(
                    //                 TextPosition(offset: lineSelection.end),
                    //               )
                    //               .dx;
                    //
                    //   selectionBoxWidgets.addAll([
                    //     // Give a slight highlight to the entire line that has the extent.
                    //     // TODO: Make this color theme-configurable.
                    //     Positioned(
                    //       top: 0,
                    //       bottom: 0,
                    //       left: 0,
                    //       right: 0,
                    //       child: ColoredBox(color: Colors.yellow.withValues(alpha: 0.03)),
                    //     ),
                    //     // Paint the selection box.
                    //     // TODO: Make this color theme-configurable.
                    //     // FIXME: Figure out why left/right values are NaN for lines that scroll off
                    //     //        screen. Check if we should fix something in super_text_layout.
                    //     if (!selectionBoxLeft.isNaN && !selectionBoxRight.isNaN)
                    //       Positioned(
                    //         top: 0,
                    //         bottom: 0,
                    //         left: selectionBoxLeft,
                    //         right: selectionBoxRight,
                    //         child: const ColoredBox(color: Color(0xFF334400)),
                    //       ),
                    //   ]);
                    // }

                    final shadowCaretPosition = widget.shadowCaretPosition;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // ...selectionBoxWidgets,
                        // Shadow caret.
                        if (shadowCaretPosition != null) //
                          Positioned(
                            left: layout.getOffsetForCaret(shadowCaretPosition).dx,
                            top: layout.getOffsetForCaret(shadowCaretPosition).dy,
                            height: layout.getHeightForCaret(shadowCaretPosition),
                            child: Container(
                              width: 1,
                              color: widget.style.shadowCaretColor,
                            ),
                          ),
                      ],
                    );
                  },
                  layerAboveBuilder: (context, layout) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (widget.hasCaret && caretPosition != null) //
                          Positioned(
                            left: layout.getOffsetForCaret(caretPosition).dx,
                            // FIXME: The reported SuperTextLayout y-offset when caret is at the very end of the line
                            //        is too far down. It positions the caret dangling below the bottom of the line.
                            // top: layout.getOffsetForCaret(caretPosition).dy,
                            top: 0,
                            height: layout.getHeightForCaret(caretPosition),
                            child: Container(
                              width: 2,
                              color: widget.style.caretColor,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        underlays: [
          _buildSelectionBox,
          _buildShadowCaret,
        ],
      ),
    );
  }

  Widget _buildVerticalTabLines() {
    final buffer = StringBuffer();
    widget.code.computeToPlainText(buffer);
    final contentText = buffer.toString();

    final leadingSpaceMatcher = RegExp(r'\s+');
    final leadingSpaceMatch = leadingSpaceMatcher.matchAsPrefix(contentText);
    int tabCount = 0;
    if (leadingSpaceMatch != null) {
      // -1 because the very first indentation line is the same as the divider between lines and code.
      tabCount = (leadingSpaceMatch.end ~/ 2) - 1;
    }

    return Positioned(
      top: 0,
      bottom: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < tabCount; i += 1) //
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: widget.style.indentLineColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                "  ",
                style: widget.style.baseTextStyle,
              ),
            ),
        ],
      ),
    );
  }

  ContentLayerWidget _buildSelectionBox(BuildContext context) {
    return _LineSelectionBoxContentLayer(
      codeTextKey: _codeTextKey,
      codeText: widget.code,
      lineSelection: widget.selection,
      hasStart: widget.hasStart,
      hasEnd: widget.hasEnd,
    );
  }

  ContentLayerWidget _buildShadowCaret(BuildContext context) {
    return _ShadowCaretContentLayer(widget.shadowCaretPosition);
  }
}

class CodeLineDebugPaint {
  static const empty = CodeLineDebugPaint();

  const CodeLineDebugPaint({
    this.lineBoundaryColor,
    this.textBoundaryColor,
  });

  /// The color of a debug border that's painted around the entire code portion
  /// of a line (the part to the right of the gutter), or `null` if no debug paint
  /// is desired.
  final Color? lineBoundaryColor;

  /// The color of a debug border that's painted around the bounding box of the text
  /// in the code portion of a line (the part to the right of the gutter), or `null` if
  /// no debug paint is desired.
  ///
  /// This boundary is typically very similar to [lineBoundaryColor], but may have some
  /// differences.
  final Color? textBoundaryColor;
}

class _LineSelectionBoxContentLayer extends ContentLayerStatelessWidget {
  const _LineSelectionBoxContentLayer({
    required this.codeTextKey,
    required this.codeText,
    required this.lineSelection,
    required this.hasStart,
    required this.hasEnd,
  });

  final GlobalKey codeTextKey;
  final TextSpan codeText;
  final TextSelection? lineSelection;
  final bool hasStart;
  final bool hasEnd;

  @override
  Widget doBuild(BuildContext context, Element? contentElement, RenderObject? contentLayout) {
    if (lineSelection == null || lineSelection!.isCollapsed) {
      return const EmptyContentLayer();
    }

    // print("_LineSelectionBoxContentLayer ($contentLayout)");
    final lineBox = contentLayout as RenderBox;
    final textLayout = codeTextKey.currentState as ProseTextBlock;
    // Note: Instead of getting the absolute global offset of the line and the text layout, and then calculating
    //       the difference, we directly ask for the difference by passing the `lineBox` as an ancestor.
    //       I did this specifically because `TwoDimensionScrollable` was breaking when trying to get absolute
    //       global offsets. This happened when selecting some code, scrolling it offscreen, then scrolling it back
    //       on screen. The child in the `TwoDimensionScrollable` didn't have its transform matrix set and therefore
    //       was blowing up.
    final textBoundaryOffset =
        (codeTextKey.currentContext!.findRenderObject() as RenderBox).localToGlobal(Offset.zero, ancestor: lineBox);
    // print(" - distance from line boundary to text boundary: $textBoundaryOffset");

    final paintToStartOfLine = lineSelection != null && lineSelection!.start == 0 && !hasStart;
    final paintToEndOfLine = lineSelection != null && lineSelection!.end == codeText.toPlainText().length && !hasEnd;

    // print(" - line selection: $lineSelection");
    // print(" - line selection start: ${lineSelection!.start}, has base: $hasStart");
    // print(" - left x: ${textLayout.textLayout.getOffsetForCaret(
    //       TextPosition(offset: lineSelection!.start),
    //     ).dx}");
    // print(" - paint to start of line? $paintToStartOfLine");
    // print(" - right x: ${paintToEndOfLine ? 0 : lineBox.size.width - textLayout.textLayout.getOffsetForCaret(
    //       TextPosition(offset: codeText.toPlainText().length),
    //     ).dx}");
    // print(" - paint to end of line? $paintToEndOfLine");

    final selectionBoxLeft = paintToStartOfLine
        ? 0.0
        : textBoundaryOffset.dx +
            textLayout.textLayout
                .getOffsetForCaret(
                  TextPosition(offset: lineSelection!.start),
                )
                .dx;
    final selectionBoxRight = paintToEndOfLine
        ? 0.0
        : lineBox.size.width -
            textLayout.textLayout
                .getOffsetForCaret(
                  TextPosition(offset: lineSelection!.end),
                )
                .dx -
            textBoundaryOffset.dx;

    return ContentLayerProxyWidget(
      child: Stack(
        children: [
          // Give a slight highlight to the entire line that has the extent.
          // TODO: Make this color theme-configurable.
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: ColoredBox(color: Colors.yellow.withValues(alpha: 0.03)),
          ),
          // Paint the selection box.
          // TODO: Make this color theme-configurable.
          // FIXME: Figure out why left/right values are NaN for lines that scroll off
          //        screen. Check if we should fix something in super_text_layout.
          if (!selectionBoxLeft.isNaN && !selectionBoxRight.isNaN)
            Positioned(
              top: 0,
              bottom: 0,
              left: selectionBoxLeft,
              right: selectionBoxRight,
              child: const ColoredBox(color: Color(0xFF334400)),
            ),
        ],
      ),
    );
  }
}

class _ShadowCaretContentLayer extends ContentLayerStatelessWidget {
  const _ShadowCaretContentLayer(this.shadowCaretOffset);

  final TextPosition? shadowCaretOffset;

  @override
  Widget doBuild(BuildContext context, Element? contentElement, RenderObject? contentLayout) {
    // if (shadowCaretOffset != null) {
    //   print("Line element: ${contentElement.runtimeType}, render object: ${contentLayout.runtimeType}");
    // }

    return const EmptyContentLayer();
  }
}

class CodeLineStyle {
  const CodeLineStyle({
    required this.baseTextStyle,
    required this.indentLineColor,
    required this.shadowCaretColor,
    required this.selectionBoxColor,
    required this.caretColor,
  });

  /// The base text style, applied beneath the styles in [code], and also applied to the indent line spacing.
  final TextStyle baseTextStyle;

  /// The color of the vertical lines that are drawn at every tab-level indent on a line.
  final Color indentLineColor;

  final Color selectionBoxColor;

  final Color shadowCaretColor;

  final Color caretColor;
}

class CodeScroller extends TwoDimensionalScrollView {
  const CodeScroller({
    super.key,
    super.primary,
    super.mainAxis = Axis.vertical,
    super.verticalDetails = const ScrollableDetails.vertical(physics: ClampingScrollPhysics()),
    super.horizontalDetails = const ScrollableDetails.horizontal(physics: ClampingScrollPhysics()),
    required TwoDimensionalChildBuilderDelegate delegate,
    super.cacheExtent,
    super.diagonalDragBehavior = DiagonalDragBehavior.free,
    super.dragStartBehavior = DragStartBehavior.start,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.clipBehavior = Clip.hardEdge,
  }) : super(delegate: delegate);

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return CodeScrollerViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }
}

class CodeScrollerViewport extends TwoDimensionalViewport {
  const CodeScrollerViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  });

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return RenderCodeScrollerViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      childManager: context as TwoDimensionalChildManager,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCodeScrollerViewport renderObject,
  ) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..mainAxis = mainAxis
      ..delegate = delegate
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}

class RenderCodeScrollerViewport extends RenderTwoDimensionalViewport {
  RenderCodeScrollerViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildBuilderDelegate delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  }) : super(delegate: delegate);

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  late ChildVicinity _leadingVicinity;
  late ChildVicinity _trailingVicinity;

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  void layoutChildSequence() {
    final builderDelegate = delegate as TwoDimensionalChildBuilderDelegate;

    // We only have two columns, the line indicator, and the line itself.
    assert(builderDelegate.maxXIndex == 1);

    final verticalPixels = verticalOffset.pixels;
    final viewportHeight = viewportDimension.height + cacheExtent;
    final maxRowIndex = builderDelegate.maxYIndex!;

    // We need to layout all children to compute the maximum line width
    // and maximum indicator width.
    //
    // To do this, we need to call buildOrObtainChildFor for each vicinity. Calling
    // buildOrObtainChildFor more than once for the same vinicity throws an
    // assertion error.
    //
    // Cache the children to avoid that.
    final childrenCache = <ChildVicinity, RenderBox>{};

    // The line height is computed when the first line is laid out.
    double lineHeight = 0;

    const firstLineVicinity = ChildVicinity(xIndex: 1, yIndex: 0);
    childrenCache[firstLineVicinity] = buildOrObtainChildFor(firstLineVicinity)!;
    childrenCache[firstLineVicinity]!.layout(BoxConstraints(), parentUsesSize: true);
    lineHeight = childrenCache[firstLineVicinity]!.size.height;
    final firstCachedLineIndex = max(verticalPixels - cacheExtent, 0) ~/ lineHeight;
    final lastCachedLineIndex = min(((verticalPixels + viewportHeight + cacheExtent) / lineHeight).ceil(), maxRowIndex);

    double maxLineIndicatorWidth = 0;

    for (int i = firstCachedLineIndex; i <= lastCachedLineIndex; i++) {
      // Compute the maximum width of the line indicator.
      // We will layout all of them after with the same width.
      final lineIndicatorVicinity = ChildVicinity(xIndex: 0, yIndex: i);
      final lineIndicator = buildOrObtainChildFor(lineIndicatorVicinity)!;
      childrenCache[lineIndicatorVicinity] = lineIndicator;

      final lineIndicatorSize = lineIndicator.getDryLayout(
        constraints.loosen().copyWith(maxWidth: double.infinity),
      );
      if (lineIndicatorSize.width > maxLineIndicatorWidth) {
        maxLineIndicatorWidth = lineIndicatorSize.width;
      }

      // We are required to set the layoutOffset for each obtained child,
      // even if we won't paint it. Otherwise, an assertion error is thrown.
      parentDataOf(lineIndicator).layoutOffset = const Offset(double.infinity, double.infinity);
    }

    // Make every line at least as wide as the viewport, so that selection boxes can always
    // extend as wide as the visible area.
    // print("Selecting max line width.");
    // print(" - constraints max width: ${constraints.maxWidth}");
    // print(" - viewport width: ${viewportDimension.width}");
    // print(" - max line indicator width: $maxLineIndicatorWidth");
    var maxLineWidth = viewportDimension.width - maxLineIndicatorWidth;

    for (int i = firstCachedLineIndex; i <= lastCachedLineIndex; i++) {
      // Layout the code line.
      final codeLineVicinity = ChildVicinity(xIndex: 1, yIndex: i);
      final codeLine = childrenCache[codeLineVicinity] ?? buildOrObtainChildFor(codeLineVicinity)!;
      childrenCache[codeLineVicinity] = codeLine;

      codeLine.layout(
        constraints.loosen().copyWith(maxWidth: double.infinity),
        parentUsesSize: true,
      );
      if (codeLine.size.width > maxLineWidth) {
        maxLineWidth = codeLine.size.width;
      }

      if (lineHeight == 0) {
        lineHeight = codeLine.size.height;
      }

      // We are required to set the layoutOffset for each obtained child,
      // even if we won't paint it. Otherwise, an assertion error is thrown.
      parentDataOf(codeLine).layoutOffset = const Offset(double.infinity, double.infinity);
    }

    // Re-layout each line at the length of the longest line.
    for (int i = firstCachedLineIndex; i <= lastCachedLineIndex; i++) {
      final codeLineVicinity = ChildVicinity(xIndex: 1, yIndex: i);
      final codeLine = childrenCache[codeLineVicinity]!;

      codeLine.layout(
        constraints.loosen().copyWith(minWidth: maxLineWidth, maxWidth: maxLineWidth),
        parentUsesSize: true,
      );
    }

    // Now that we have maximum indicator width, layout each indicator with the same width.
    for (int i = firstCachedLineIndex; i <= lastCachedLineIndex; i++) {
      final lineIndicatorVicinity = ChildVicinity(xIndex: 0, yIndex: i);
      final lineIndicator = childrenCache[lineIndicatorVicinity]!;
      lineIndicator.layout(
        constraints.copyWith(
          minWidth: maxLineIndicatorWidth,
          maxWidth: maxLineIndicatorWidth,
        ),
      );
    }

    // First row that will be painted.
    final leadingRow = math.max((verticalPixels / lineHeight).floor(), 0);

    // Last row that will be painted.
    final trailingRow = math.min(
      ((verticalPixels + viewportHeight) / lineHeight).ceil(),
      maxRowIndex,
    );

    _leadingVicinity = ChildVicinity(xIndex: 0, yIndex: leadingRow);
    _trailingVicinity = ChildVicinity(xIndex: 1, yIndex: trailingRow);

    double yLayoutOffset = (leadingRow * lineHeight) - verticalOffset.pixels;

    // Compute the offset for each visible line.
    for (int row = leadingRow; row <= trailingRow; row++) {
      // Layout the indicator, which is pinned and scrolls only vertically.
      final lineIndicatorVicinity = ChildVicinity(xIndex: 0, yIndex: row);
      final lineIndicator = childrenCache[lineIndicatorVicinity]!;
      parentDataOf(lineIndicator).layoutOffset = Offset(0, yLayoutOffset);

      final codeLineVicinity = ChildVicinity(xIndex: 1, yIndex: row);
      final codeLine = childrenCache[codeLineVicinity]!;
      parentDataOf(codeLine).layoutOffset = Offset(maxLineIndicatorWidth - horizontalOffset.pixels, yLayoutOffset);

      // Move to the next line.
      yLayoutOffset += lineHeight;
    }

    // Set the min and max scroll extents for each axis.
    final verticalExtent = lineHeight * (maxRowIndex + 1);
    verticalOffset.applyContentDimensions(
      0.0,
      clampDouble(verticalExtent - viewportDimension.height, 0.0, double.infinity),
    );

    final horizontalExtent = maxLineWidth! + maxLineIndicatorWidth;
    // print(
    //     "Horizontal extent: $horizontalExtent, max indicator width: $maxLineIndicatorWidth, max line width: $maxLineWidth");
    horizontalOffset.applyContentDimensions(
      0.0,
      clampDouble(horizontalExtent - viewportDimension.width, 0.0, double.infinity),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (clipBehavior != Clip.none) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & viewportDimension,
        _paintChildren,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      _paintChildren(context, offset);
    }
  }

  void _paintChildren(PaintingContext context, Offset offset) {
    // Paint only visible lines.
    for (int currentRow = _leadingVicinity.yIndex; currentRow <= _trailingVicinity.yIndex; currentRow++) {
      final codeLineVicinity = ChildVicinity(
        yIndex: currentRow,
        xIndex: 1,
      );
      final codeLine = getChildFor(codeLineVicinity);
      if (codeLine != null) {
        context.paintChild(codeLine, parentDataOf(codeLine).layoutOffset! + offset);
      }

      // Paint the first column, which is pinned and scrolls only vertically.
      final lineIndicatorVicinity = ChildVicinity(
        yIndex: currentRow,
        xIndex: 0,
      );
      final lineIndicator = getChildFor(lineIndicatorVicinity);
      if (lineIndicator != null) {
        context.paintChild(lineIndicator, parentDataOf(lineIndicator).layoutOffset! + offset);
      }
    }
  }
}

extension CodeLineLayoutFromContext on GlobalKey {
  /// Assumes this [GlobalKey] is attached to a [CodeLine] widget, and returns
  /// the [CodeLineLayout] for that line.
  ///
  /// This method is a verbosity reduction for repeated access of code line layouts.
  CodeLineLayout get asCodeLine => currentState as CodeLineLayout;
}

abstract interface class CodeLineLayout {
  /// Line number for this line within its overall source file, starting at zero.
  int get lineNumber;

  /// Returns `true` if the [globalOffset] is within the bounds of this code line.
  bool containsGlobalOffset(Offset globalOffset);

  /// Returns `true` if the given global [y] offset is within the bounds of this
  /// code line.
  bool containsGlobalYValue(double y);

  /// Returns the bounds that surround the word that appears at the given
  /// [globalOffset].
  CodeRange? findWordBoundaryAtGlobalOffset(Offset globalOffset);

  /// Returns the bounds that surround the word that appears at the given
  /// [localOffset].
  CodeRange? findWordBoundaryAtLocalOffset(Offset localOffset);

  /// Returns the [CodePosition] nearest to the given [globalOffset].
  (CodePosition, TextAffinity) findCodePositionNearestGlobalOffset(Offset globalOffset);

  /// Returns the [CodePosition] nearest to the given [localOffset].
  (CodePosition, TextAffinity) findCodePositionNearestLocalOffset(Offset localOffset);

  /// Returns the [Rect] that surrounds the character at the given [characterOffset].
  Rect getLocalRectForCharacter(int characterOffset);

  /// Returns the [Rect] where the caret would appear **before** the given [characterOffset].
  ///
  /// The returned [Rect] is a conceptual caret - its x-offset starts either 1px before
  /// a character, or immediately after a character, it's width is 1px, and its height is
  /// equal to the line height.
  ///
  /// There is no requirement that an editor render a caret with this [Rect]. An editor
  /// can choose to render a wider caret, taller caret, shorter caret. Rather, this [Rect]
  /// should be thought of as a line segment between characters, and then used to calculate
  /// any relevant information based on that.
  Rect getLocalRectForCaret(int characterOffset);

  /// Returns the x-offset where the caret would appear, if the caret were displayed at the
  /// given [characterOffset], i.e., the x-offset between two sequential characters, or before/after
  /// the first/last character.
  ///
  /// This x-offset isn't necessarily used by an editor to display the caret. An editor is free
  /// to choose whatever offset, width, and height it desired for the caret. Rather, this x-offset
  /// is made available for any layout calculations that want to operate between characters, instead
  /// of within a given character.
  double getLocalXForCaret(int characterOffset);

  /// Returns a list of [TextBox]es that bound the given [selection],
  /// in local coordinates.
  ///
  /// See also:
  ///
  ///  * [RenderParagraph.getBoxesForSelection].
  List<TextBox> getBoxesForSelection(TextSelection selection);
}
