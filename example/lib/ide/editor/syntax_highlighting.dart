import 'package:flutter/widgets.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

List<TextSpan> highlightSyntaxByLine(Highlighter highlighter, String codeSnippet) {
  final highlightedText = highlighter.highlight(codeSnippet);

  final debugBuffer = StringBuffer();
  return _breakUpTextSpanTreeIntoLines(codeSnippet, highlightedText, debugBuffer);
}

List<TextSpan> _breakUpTextSpanTreeIntoLines(
  String codeSnippet,
  TextSpan highlightedText,
  StringBuffer debugBuffer,
) {
  final styledLines = <TextSpan>[];
  final spanStack = <TextSpan>[highlightedText];

  TextSpan currentLine = TextSpan(
    text: "",
    children: [],
  );
  styledLines.add(currentLine);
  int currentOffset = 0;

  // print("----------- PROCESSING SPANS ------------");
  while (spanStack.isNotEmpty) {
    // print("----------------");
    final span = spanStack.removeAt(0);
    // print("Span:\n'${span.text}'");
    // print("-----");

    if (span.children != null) {
      // Push the children of this span onto the span stack so that they'll be
      // processed after the current span.
      spanStack.insertAll(0, span.children!.whereType<TextSpan>());
    }

    if (span.text == null) {
      // There's no text in this span. Move on to the children, or later spans.
      // print("The span has no text. Moving to next span.");
      continue;
    }

    span.computeToPlainText(debugBuffer);
    debugBuffer.writeln();

    final endOfSpan = currentOffset + span.text!.length;
    // print("Start of this span: $currentOffset");
    // print("End of this span: $endOfSpan");

    if (!span.text!.contains("\n")) {
      // print("This span has no newlines, appending to ongoing line.");
      // All the content in this span belongs to the current line. Append it.
      currentLine.children!.add(span);
      // print(
      //     "Appending text: '${span.text!}' - global offset: $currentOffset -> ${currentOffset + span.text!.length}");
      currentOffset += span.text!.length;

      continue;
    }

    // print("This span contains multiple lines of text...");
    final lines = span.text!.split("\n");
    for (int i = 0; i < lines.length; i += 1) {
      final line = lines[i];
      currentLine.children!.add(
        TextSpan(
          text: line,
          style: span.style,
        ),
      );

      if (i < lines.length - 1) {
        // Write the current line to debug output for verification.
        final buffer = StringBuffer();
        currentLine.computeToPlainText(buffer);
        // print("COMMITTING LINE: '${buffer.toString()}'");

        // Create a new line to append remaining text.
        // print("STARTING NEW (BLANK) CODE LINE");
        currentLine = TextSpan(text: "", children: []);
        styledLines.add(currentLine);
      }
    }
  }

  return styledLines;
}
