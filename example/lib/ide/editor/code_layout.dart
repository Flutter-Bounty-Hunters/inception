import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// TODO: Define and implement a CodeLinesLayout, similar to CodeLineLayout, but
//       for the whole file.
// TODO: Refactor CodeLines to display in a ContentLayers widget.

/// Widget that displays all the lines of source within a given file or sample.
class CodeLines extends StatefulWidget {
  const CodeLines({
    super.key,
    required this.codeLines,
    required this.indentLineColor,
    required this.baseTextStyle,
  });

  /// All lines of source code, with syntax highlighting already applied.
  final List<TextSpan> codeLines;

  /// The color of little lines that appear on the upstream side of the code in the
  /// indentation area.
  final Color indentLineColor;

  /// The base text style, applied beneath the styles in [code], and also applied to the indent line spacing.
  final TextStyle baseTextStyle;

  @override
  State<CodeLines> createState() => _CodeLinesState();
}

class _CodeLinesState extends State<CodeLines> implements CodeLinesLayout {
  final _lineKeys = <int, GlobalKey>{};

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
  CodePosition findCodePositionNearestGlobalOffset(Offset globalOffset) {
    for (int lineIndex in _lineKeys.keys) {
      final lineLayout = _lineKeys[lineIndex]!.asCodeLine;
      if (!lineLayout.containsGlobalYValue(globalOffset.dy)) {
        continue;
      }

      return lineLayout.findCodePositionNearestGlobalOffset(globalOffset);
    }

    return const CodePosition(0, 0);
  }

  @override
  CodePosition findCodePositionNearestLocalOffset(Offset localOffset) {
    final globalOffset = (context.findRenderObject() as RenderBox).localToGlobal(localOffset);
    return findCodePositionNearestGlobalOffset(globalOffset);
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
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < widget.codeLines.length; i += 1) //
            _buildCodeLine(i),
        ],
      ),
    );
  }

  Widget _buildCodeLine(int lineIndex) {
    _lineKeys[lineIndex] ??= GlobalKey(debugLabel: "Code line: $lineIndex");
    final key = _lineKeys[lineIndex];

    return CodeLine(
      key: key,
      lineNumber: lineIndex,
      code: widget.codeLines[lineIndex],
      indentLineColor: widget.indentLineColor,
      baseTextStyle: widget.baseTextStyle,
    );
  }
}

extension CodeLinesLayoutFromContext on GlobalKey {
  /// Assumes this [GlobalKey] is attached to a [CodeLines] widget, and returns
  /// the [CodeLinesLayout] for the code layout.
  ///
  /// This method is a verbosity reduction for repeated access of code layout.
  CodeLinesLayout get asCodeLines => currentState as CodeLinesLayout;
}

abstract interface class CodeLinesLayout {
  /// Returns the bounds that surround the word that appears at the given
  /// [globalOffset].
  CodeRange? findWordBoundaryAtGlobalOffset(Offset globalOffset);

  /// Returns the bounds that surround the word that appears at the given
  /// [localOffset].
  CodeRange? findWordBoundaryAtLocalOffset(Offset localOffset);

  /// Returns the [CodePosition] nearest to the given [globalOffset].
  CodePosition findCodePositionNearestGlobalOffset(Offset globalOffset);

  /// Returns the [CodePosition] nearest to the given [localOffset].
  CodePosition findCodePositionNearestLocalOffset(Offset localOffset);
}

/// Widget that displays a single line of code text.
class CodeLine extends StatefulWidget {
  const CodeLine({
    super.key,
    required this.lineNumber,
    required this.code,
    required this.indentLineColor,
    required this.baseTextStyle,
  });

  /// Line number for this line within its overall source file, starting at zero.
  final int lineNumber;

  /// The styled code to display in this line.
  final TextSpan code;

  /// The color of little lines that appear on the upstream side of the code in the
  /// indentation area.
  final Color indentLineColor;

  /// The base text style, applied beneath the styles in [code], and also applied to the indent line spacing.
  final TextStyle baseTextStyle;

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

    final renderParagraph = _renderParagraph;
    final paragraphLocalOffset = renderParagraph.globalToLocal(localOffset, ancestor: codeLineBox);
    print("Local offset: $paragraphLocalOffset");
    final textPosition = renderParagraph.getPositionForOffset(paragraphLocalOffset);
    print("Text position: $textPosition");
    final wordRange = renderParagraph.getWordBoundary(textPosition);
    print("Word range: $wordRange");
    print("Word: '${renderParagraph.text.toPlainText().substring(wordRange.start, wordRange.end)}'");
    return CodeRange(
      CodePosition(widget.lineNumber, wordRange.start),
      CodePosition(widget.lineNumber, wordRange.end),
    );
  }

  @override
  CodePosition findCodePositionNearestGlobalOffset(Offset globalOffset) {
    final localOffset = (_codeTextKey.currentContext!.findRenderObject() as RenderBox).globalToLocal(globalOffset);
    return findCodePositionNearestLocalOffset(localOffset);
  }

  @override
  CodePosition findCodePositionNearestLocalOffset(Offset localOffset) {
    final renderParagraph = _renderParagraph;
    final textPosition = renderParagraph.getPositionForOffset(localOffset);
    return CodePosition(widget.lineNumber, textPosition.offset);
  }

  RenderParagraph get _renderParagraph => _codeTextKey.currentContext!.findRenderObject() as RenderParagraph;

  @override
  Widget build(BuildContext context) {
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

    return Stack(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 100 + 8),
            for (int i = 0; i < tabCount; i += 1) //
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: widget.indentLineColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  "  ",
                  style: widget.baseTextStyle,
                ),
              ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.only(right: 64),
                child: Text(
                  "${widget.lineNumber + 1}",
                  textAlign: TextAlign.right,
                  style: widget.baseTextStyle.copyWith(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text.rich(
              key: _codeTextKey,
              widget.code,
              style: widget.baseTextStyle,
            ),
          ],
        ),
      ],
    );
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
  CodePosition findCodePositionNearestGlobalOffset(Offset globalOffset);

  /// Returns the [CodePosition] nearest to the given [localOffset].
  CodePosition findCodePositionNearestLocalOffset(Offset localOffset);
}

class CodeSelection {
  const CodeSelection({
    required this.base,
    required this.extent,
  });

  final CodePosition base;
  final CodePosition extent;

  CodeRange toRange() {
    final affinity = extent.line > base.line || extent.characterOffset >= base.characterOffset
        ? TextAffinity.downstream
        : TextAffinity.upstream;

    return CodeRange(
      affinity == TextAffinity.downstream ? base : extent,
      affinity == TextAffinity.downstream ? extent : base,
    );
  }
}

/// A range of code, from a starting line and offset, to an ending line and offset.
class CodeRange {
  const CodeRange(this.start, this.end) : assert(start <= end);

  final CodePosition start;
  final CodePosition end;

  CodeSelection toSelection([TextAffinity affinity = TextAffinity.downstream]) {
    return CodeSelection(
      base: affinity == TextAffinity.downstream ? start : end,
      extent: affinity == TextAffinity.downstream ? end : start,
    );
  }

  @override
  String toString() => "[CodeRange - $start -> $end]";
}

class CodePosition implements Comparable<CodePosition> {
  const CodePosition(this.line, this.characterOffset);

  final int line;
  final int characterOffset;

  bool operator <(CodePosition other) {
    return compareTo(other) < 0;
  }

  bool operator <=(CodePosition other) {
    return compareTo(other) <= 0;
  }

  bool operator >(CodePosition other) {
    return compareTo(other) > 0;
  }

  bool operator >=(CodePosition other) {
    return compareTo(other) >= 0;
  }

  @override
  int compareTo(CodePosition other) {
    if (line == other.line) {
      return characterOffset - other.characterOffset;
    }

    return line - other.line;
  }

  @override
  String toString() => "(line: $line, offset: $characterOffset)";
}
