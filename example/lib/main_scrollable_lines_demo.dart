import 'package:example/ide/editor/scrolling_code_line.dart';
import 'package:example/ide/editor/syntax_highlighting.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: const Scaffold(
        backgroundColor: Color(0xFF222222),
        body: _ScrollingLineScreen(),
      ),
    ),
  );
}

class _ScrollingLineScreen extends StatefulWidget {
  const _ScrollingLineScreen();

  @override
  State<_ScrollingLineScreen> createState() => _ScrollingLineScreenState();
}

class _ScrollingLineScreenState extends State<_ScrollingLineScreen>
    with TickerProviderStateMixin
    implements ScrollActivityDelegate {
  final _verticalScrollController = ScrollController();
  double _horizontalScrollOffset = 0;

  List<TextSpan>? _styledLines;

  Duration? _lastScrollTime;
  Axis? _activeScrollDirection;
  double _velocity = 0;

  @override
  void initState() {
    super.initState();

    _highlightSyntax();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();

    super.dispose();
  }

  Future<void> _highlightSyntax() async {
    await Highlighter.initialize(['dart', 'yaml']);

    var theme = await HighlighterTheme.loadDarkTheme();

    final highlighter = Highlighter(
      language: 'dart',
      theme: theme,
    );

    setState(() {
      _styledLines = highlightSyntaxByLine(highlighter, _code);

      for (final span in _styledLines!) {
        final buffer = StringBuffer();
        span.computeToPlainText(buffer);
      }
    });
  }

  void _onPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    final scrollDelta = event.panDelta;

    // Stop any ongoing horizontal scroll momentum.
    _horizontalBallisticActivity?.delegate.goIdle();
    _horizontalBallisticActivity = null;

    if (scrollDelta.distance == 0) {
      return;
    }

    _activeScrollDirection ??= scrollDelta.dy.abs() >= scrollDelta.dx.abs() //
        ? Axis.vertical
        : Axis.horizontal;

    final secondsSinceLastEvent =
        _lastScrollTime != null ? (event.timeStamp - _lastScrollTime!).inMilliseconds / 1000 : 0;

    switch (_activeScrollDirection!) {
      case Axis.vertical:
        _verticalScrollController.position.pointerScroll(-scrollDelta.dy);
        _velocity = secondsSinceLastEvent > 0 //
            ? -scrollDelta.dy / secondsSinceLastEvent
            : _velocity;
      case Axis.horizontal:
        setState(() {
          _horizontalScrollOffset = (_horizontalScrollOffset - scrollDelta.dx).clamp(0, double.infinity);
          _velocity = secondsSinceLastEvent > 0 //
              ? -scrollDelta.dx / secondsSinceLastEvent
              : _velocity;
        });
    }

    _lastScrollTime = event.timeStamp;
  }

  void _onPanZoomEnd(PointerPanZoomEndEvent event) {
    if (_activeScrollDirection != null) {
      print("------- END -------");
      print("Velocity: $_velocity");
      switch (_activeScrollDirection!) {
        case Axis.vertical:
          _goBallisticVertical();
        case Axis.horizontal:
          _goBallisticHorizontal();
      }
    }

    _activeScrollDirection = null;
    _velocity = 0;
  }

  void _goBallisticVertical() {
    final scrollingDelegate = _verticalScrollController.position as ScrollPositionWithSingleContext;
    scrollingDelegate.goBallistic(_velocity);
  }

  BallisticScrollActivity? _horizontalBallisticActivity;
  void _goBallisticHorizontal() {
    print("GO BALLISTIC HORIZONTAL. VELOCITY: $_velocity");
    // _horizontalBallisticActivity = BallisticScrollActivity(
    //   this,
    //   ClampingScrollSimulation(
    //     position: _horizontalScrollOffset,
    //     velocity: _velocity,
    //   ),
    //   this,
    //   true,
    // );
  }

  /// The direction in which the scroll view scrolls.
  @override
  AxisDirection get axisDirection => _velocity >= 0 ? AxisDirection.left : AxisDirection.right;

  /// Update the scroll position to the given pixel value.
  ///
  /// Returns the overscroll, if any. See [ScrollPosition.setPixels] for more
  /// information.
  @override
  double setPixels(double pixels) => _horizontalScrollOffset = pixels;

  /// Updates the scroll position by the given amount.
  ///
  /// Appropriate for when the user is directly manipulating the scroll
  /// position, for example by dragging the scroll view. Typically applies
  /// [ScrollPhysics.applyPhysicsToUserOffset] and other transformations that
  /// are appropriate for user-driving scrolling.
  @override
  void applyUserOffset(double delta) => _horizontalScrollOffset += delta;

  /// Terminate the current activity and start an idle activity.
  @override
  void goIdle() {}

  /// Terminate the current activity and start a ballistic activity with the
  /// given velocity.
  @override
  void goBallistic(double velocity) {}

  @override
  Widget build(BuildContext context) {
    if (_styledLines == null) {
      return const SizedBox();
    }

    return Listener(
      onPointerPanZoomUpdate: _onPanZoomUpdate,
      onPointerPanZoomEnd: _onPanZoomEnd,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < _styledLines!.length; i += 1)
                ScrollingCodeLine(
                  lineNumber: i,
                  indentLineColor: const Color(0xFF333333),
                  baseTextStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: "SourceCodePro",
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  scrollOffset: _horizontalScrollOffset,
                  code: _styledLines![i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const _code = r'''
import 'package:example/ide/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:super_editor/super_editor.dart';

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
    final globalOffset = (context.findRenderObject() as RenderBox).localToGlobal(localOffset);
    return findWordBoundaryAtGlobalOffset(globalOffset);
  }

  @override
  CodePosition findCodePositionNearestGlobalOffset(Offset globalOffset) {
    for (int lineIndex = 0; lineIndex < widget.codeLines.length; lineIndex += 1) {
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
    for (int lineIndex = 0; lineIndex < widget.codeLines.length; lineIndex += 1) {
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
      child: CustomScrollView(
        primary: true,
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        slivers: [
          ContentLayers(
            content: (context) => SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < widget.codeLines.length; i += 1) //
                    _buildCodeLine(i),
                ],
              ),
            ),
            overlays: const [
              buildCaretOverlay,
            ],
          ),
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

ContentLayerWidget buildCaretOverlay(BuildContext context) {
  return const CodeCaretOverlay();
}

class CodeCaretOverlay extends ContentLayerStatelessWidget {
  const CodeCaretOverlay({super.key});

  @override
  Widget doBuild(BuildContext context, Element? contentElement, RenderObject? contentLayout) {
    // TODO: implement doBuild
    throw UnimplementedError();
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
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: OverflowBox(
              maxWidth: double.infinity,
              fit: OverflowBoxFit.deferToChild,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                key: _codeTextKey,
                widget.code,
                maxLines: 1,
                style: widget.baseTextStyle,
              ),
            ),
          ),
        ),
      ],
    );

    // return Stack(
    //   children: [
    //     Row(
    //       mainAxisSize: MainAxisSize.min,
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         const SizedBox(width: 100 + 8),
    //         for (int i = 0; i < tabCount; i += 1) //
    //           DecoratedBox(
    //             decoration: BoxDecoration(
    //               border: Border(
    //                 right: BorderSide(
    //                   color: widget.indentLineColor,
    //                   width: 1,
    //                 ),
    //               ),
    //             ),
    //             child: Text(
    //               "  ",
    //               style: widget.baseTextStyle,
    //             ),
    //           ),
    //       ],
    //     ),
    //     Row(
    //       mainAxisSize: MainAxisSize.min,
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         SizedBox(
    //           width: 100,
    //           child: Padding(
    //             padding: const EdgeInsets.only(right: 64),
    //             child: Text(
    //               "${widget.lineNumber + 1}",
    //               textAlign: TextAlign.right,
    //               style: widget.baseTextStyle.copyWith(
    //                 color: Colors.white.withOpacity(0.3),
    //               ),
    //             ),
    //           ),
    //         ),
    //         const SizedBox(width: 8),
    //         Text.rich(
    //           key: _codeTextKey,
    //           widget.code,
    //           style: widget.baseTextStyle,
    //         ),
    //       ],
    //     ),
    //   ],
    // );
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
''';
