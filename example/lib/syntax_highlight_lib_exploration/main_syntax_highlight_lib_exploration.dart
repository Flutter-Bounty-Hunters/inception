import 'package:flutter/material.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: const Scaffold(
        body: _CodeViewer(),
      ),
    ),
  );
}

class _CodeViewer extends StatefulWidget {
  const _CodeViewer();

  @override
  State<_CodeViewer> createState() => _CodeViewerState();
}

class _CodeViewerState extends State<_CodeViewer> {
  late final HighlighterTheme _codeTheme;
  Highlighter? _codeHighlighter;

  @override
  void initState() {
    super.initState();

    _highlightCode();
  }

  Future<void> _highlightCode() async {
    await Highlighter.initialize(['dart']);
    if (!mounted) {
      return;
    }

    _codeTheme = await HighlighterTheme.loadDarkTheme();
    if (!mounted) {
      return;
    }

    setState(() {
      _codeHighlighter = Highlighter(
        language: 'dart',
        theme: _codeTheme,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_codeHighlighter == null) {
      return const SizedBox();
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildBackground(),
          ),
          _buildLines(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 100,
          color: _background,
        ),
        Container(
          width: 1,
          color: _lineColor,
        ),
        const Expanded(
          child: ColoredBox(
            color: _background,
          ),
        ),
      ],
    );
  }

  Widget _buildLines() {
    const codeSnippet = '''import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: const Scaffold(
        body: _CodeViewer(),
      ),
    ),
  );
}''';
    final codeLines = codeSnippet.split("\n");
    final newlineMatcher = RegExp(r'\n');
    final newlineOffsets = newlineMatcher.allMatches(codeSnippet).map((match) => match.start).toList();
    print("Newline offset: $newlineOffsets");

    final highlightedText = _codeHighlighter!.highlight(codeSnippet);

    // Move through every styled span and break the spans apart by line.
    final styledLines = <TextSpan>[];
    final spanStack = <TextSpan>[highlightedText];

    TextSpan currentLine = TextSpan(text: "", children: []);
    styledLines.add(currentLine);
    int currentOffset = 0;

    final debugBuffer = StringBuffer();

    while (spanStack.isNotEmpty) {
      final span = spanStack.removeAt(0);

      if (span.children != null) {
        spanStack.insertAll(0, span.children!.whereType<TextSpan>());
      }

      if (span.text == null) {
        continue;
      }

      // print("Span: '${span.text}' - start offset: $currentOffset");

      span.computeToPlainText(debugBuffer);
      debugBuffer.writeln();

      final endOfSpan = currentOffset + span.text!.length;

      if (newlineOffsets.isEmpty || endOfSpan <= newlineOffsets.first) {
        // All the content in this span belongs to the current line. Append it.
        currentLine.children!.add(span);
        print(
            "Appending text: '${span.text!}' - global offset: $currentOffset -> ${currentOffset + span.text!.length}");
        currentOffset += span.text!.length;
        continue;
      }

      while (newlineOffsets.isNotEmpty && endOfSpan > newlineOffsets.first) {
        // The next newline appears somewhere in this span.
        final nextNewline = newlineOffsets.removeAt(0);
        print("Processing newline at $nextNewline - end of text span: $endOfSpan");

        if (nextNewline - currentOffset > 0) {
          // Copy the styled text from the current offset to the next newline.
          print("Appending text: '${span.text!}' - global offset: $currentOffset -> ${nextNewline - 1}");

          // Copy the text in this span before the newline.
          currentLine.children!.add(
            TextSpan(
              text: span.text!.substring(0, nextNewline - currentOffset),
              style: span.style,
            ),
          );
        }

        final buffer = StringBuffer();
        currentLine.computeToPlainText(buffer);
        print("Committing line: '${buffer.toString()}'");

        // Create a new line to append to.
        currentLine = TextSpan(text: "", children: []);
        styledLines.add(currentLine);

        if (endOfSpan > nextNewline + 1 && endOfSpan < newlineOffsets.first) {
          print(
              "Copy after newline - newline offset: $nextNewline, current offset: $currentOffset, end of span: $endOfSpan, span length: ${span.text!.length}, next newline: ${newlineOffsets.first}");
          print("Text after newline: '${span.text!.substring((nextNewline - currentOffset) + 1)}'");
          // Copy the text in this span after the newline.
          currentLine.children!.add(
            TextSpan(
              text: span.text!.substring((nextNewline - currentOffset) + 1),
              style: span.style,
            ),
          );

          // Move the current offset to the character after the text we just copied.
          currentOffset = endOfSpan;
        } else {
          // Move the current offset to the character after the newline we just processed.
          currentOffset = nextNewline + 1;
        }
      }
    }

    print("Displaying ${styledLines.length} styled lines");
    for (final span in styledLines) {
      final buffer = StringBuffer();
      span.computeToPlainText(buffer);
      print("Line: '${buffer.toString()}'");
    }

    print("");
    print("");
    print("All non-null spans:");
    print(debugBuffer);

    return Column(
      children: [
        for (int i = 0; i < styledLines.length; i += 1) //
          // _buildLine(i, codeLines[i]),
          _buildLine(i, styledLines[i]),
      ],
    );
  }

  Widget _buildLine(int index, TextSpan content) {
    final buffer = StringBuffer();
    content.computeToPlainText(buffer);
    final contentText = buffer.toString();

    final leadingSpaceMatcher = RegExp(r'\s+');
    final leadingSpaceMatch = leadingSpaceMatcher.matchAsPrefix(contentText);
    int tabCount = 0;
    if (leadingSpaceMatch != null) {
      // -1 because the very first indentation line is the same as the divider between lines and code.
      tabCount = (leadingSpaceMatch.end ~/ 2) - 1;
    }
    // print("Line $index - tab: $tabCount - '$content'");

    return Stack(
      children: [
        Row(
          children: [
            const SizedBox(width: 100 + 8),
            for (int i = 0; i < tabCount; i += 1) //
              const DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: _lineColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  "  ",
                  style: _baseCodeStyle,
                ),
              ),
          ],
        ),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.only(right: 64),
                child: Text(
                  "${index + 1}",
                  textAlign: TextAlign.right,
                  style: _baseCodeStyle.copyWith(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                content,
                style: _baseCodeStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const _baseCodeStyle = TextStyle(
  color: Colors.white,
  fontFamily: "SourceCodePro",
  fontSize: 14,
  fontWeight: FontWeight.w900,
);

const _lineColor = Color(0xFF333333);
const _background = Color(0xFF222222);
