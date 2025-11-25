import 'package:example/ide/editor/code_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Widget that displays a single line of code text.
class ScrollingCodeLine extends StatefulWidget {
  const ScrollingCodeLine({
    super.key,
    required this.lineNumber,
    required this.indentLineColor,
    required this.baseTextStyle,
    this.scrollOffset = 0,
    required this.code,
  });

  /// Line number for this line within its overall source file, starting at zero.
  final int lineNumber;

  /// The color of little lines that appear on the upstream side of the code in the
  /// indentation area.
  final Color indentLineColor;

  /// The base text style, applied beneath the styles in [code], and also applied to the indent line spacing.
  final TextStyle baseTextStyle;

  final double scrollOffset;

  /// The styled code to display in this line.
  final TextSpan code;

  @override
  State<ScrollingCodeLine> createState() => _ScrollingCodeLineState();
}

class _ScrollingCodeLineState extends State<ScrollingCodeLine> implements CodeLineLayout {
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

    if (widget.lineNumber == 100) {
      print("I'm line 100 and my global origin is: ${myBox.localToGlobal(Offset.zero)}");
    }
    if (myRect.top <= y && y <= myRect.bottom) {
      print("I'm line ${widget.lineNumber} and I contain y: $y");
    }

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

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    // TODO:
    return [];
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

    return Row(
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: widget.indentLineColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 64),
            child: Text(
              "${widget.lineNumber + 1}",
              textAlign: TextAlign.right,
              style: widget.baseTextStyle.copyWith(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        Expanded(
          child: Builder(builder: (context) {
            return ClipRect(
              child: Transform.translate(
                offset: Offset(-widget.scrollOffset, 0),
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: 50,
                  // ^ without a max height this widget blows up with unbounded height. Not sure why.
                  alignment: Alignment.centerLeft,
                  fit: OverflowBoxFit.deferToChild,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Text.rich(
                      key: _codeTextKey,
                      widget.code,
                      style: widget.baseTextStyle,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
