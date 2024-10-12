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

class _CodeLinesState extends State<CodeLines> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < widget.codeLines.length; i += 1) //
          CodeLine(
            lineNumber: i + 1,
            code: widget.codeLines[i],
            indentLineColor: widget.indentLineColor,
            baseTextStyle: widget.baseTextStyle,
          )
      ],
    );
  }
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
  CodePosition findCodePositionAtGlobalOffset(Offset globalOffset) {
    final renderParagraph = _codeTextKey.currentContext!.findRenderObject() as RenderParagraph;
    final textPosition = renderParagraph.getPositionForOffset(globalOffset);
    return CodePosition(widget.lineNumber, textPosition.offset);
  }

  @override
  CodePosition findCodePositionAtLocalOffset(Offset localOffset) {
    final globalOffset = (context.findRenderObject() as RenderBox).localToGlobal(localOffset);
    return findCodePositionAtGlobalOffset(globalOffset);
  }

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

  /// Returns the [CodePosition] nearest to the given [globalOffset].
  CodePosition findCodePositionAtGlobalOffset(Offset globalOffset);

  /// Returns the [CodePosition] nearest to the given [localOffset].
  CodePosition findCodePositionAtLocalOffset(Offset localOffset);
}

class CodeSelection {
  const CodeSelection({
    required this.base,
    required this.extent,
  });

  final CodePosition base;
  final CodePosition extent;
}

class CodePosition {
  const CodePosition(this.line, this.characterOffset);

  final int line;
  final int characterOffset;
}
