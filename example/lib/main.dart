import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:example/example_flutter_highlight.dart';
import 'package:example/example_flutter_syntax_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_editor/super_editor.dart';

import 'code_samples.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Inception - Example',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final ParseStringResult _parsedCode;
  late final DocumentEditor _editor;

  @override
  void initState() {
    super.initState();

    _analyzeCode();

    _editor = DocumentEditor(
      document: _createDocumentFromCode(),
    );
  }

  void _analyzeCode() {
    print("Parsing Dart code");
    _parsedCode = parseString(content: codeString);
    print("Done parsing code");
    print("There are ${_parsedCode.lineInfo.lineCount} lines of code");
    print("There are ${_parsedCode.errors.length} errors in the code");

    print("Begin token: ${_parsedCode.unit.beginToken}");
    print("Offset: ${_parsedCode.unit.offset}");
    print("End token: ${_parsedCode.unit.endToken}");
    print("End offset: ${_parsedCode.unit.end}");

    final printVisitor = PrintVisitor();
    print("Declarations:");
    for (final declaration in _parsedCode.unit.declarations) {
      print("Runtime type: ${declaration.runtimeType}");
    }

    _parsedCode.unit.accept(printVisitor);
  }

  MutableDocument _createDocumentFromCode() {
    print("Creating document from parsed code...");
    print("Source code length: ${codeString.length}");

    final nodes = <DocumentNode>[];
    for (final lineStart in _parsedCode.lineInfo.lineStarts) {
      print("Line start: $lineStart");
      late final int lineEnd;
      if (_parsedCode.lineInfo.lineStarts.last == lineStart) {
        // This is the last line. We can't ask for the line after that.
        // The line ends at the end of the text.
        lineEnd = codeString.length;
      } else {
        lineEnd = _parsedCode.lineInfo.getOffsetOfLineAfter(lineStart) - 1;
      }
      print("Line end: $lineEnd");
      nodes.add(
        ParagraphNode(
          id: DocumentEditor.createNodeId(),
          text: AttributedText(
            text: codeString.substring(
              lineStart,
              lineEnd,
            ),
          ),
        ),
      );
    }

    final document = MutableDocument(nodes: nodes);

    // Style the document.
    _parsedCode.unit.accept(_StyleVisitor(_parsedCode.lineInfo, document));

    return document;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(72.0),
          child: Column(
            children: [
              SuperEditor(
                editor: _editor,
                stylesheet: defaultStylesheet.copyWith(
                  addRulesAfter: [
                    textStyles,
                    commentStyle,
                  ],
                  inlineTextStyler: _spanStyleBuilder,
                ),
              ),
              const SizedBox(height: 72),
              const FlutterSyntaxViewExample(),
            ],
          ),
        ),
      ),
    );
  }
}

final textStyles = StyleRule(
  BlockSelector.all,
  (doc, docNode) {
    return {
      "maxWidth": 1400.0,
      "padding": const CascadingPadding.all(0),
      "textStyle": const TextStyle(
        color: Colors.black,
        fontSize: 12,
        height: 1.2,
      ),
    };
  },
);

final commentStyle = StyleRule(
  const BlockSelector("comment"),
  (doc, docNode) {
    return {
      "textStyle": const TextStyle(
        color: Colors.green,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    };
  },
);

TextStyle _spanStyleBuilder(Set<Attribution> attributions, TextStyle existingStyle) {
  TextStyle style = defaultInlineTextStyler(attributions, existingStyle);

  if (attributions.contains(const NamedAttribution("variableName"))) {
    style = style.copyWith(
      fontFamily: GoogleFonts.firaCode().fontFamily,
      fontWeight: FontWeight.bold,
    );
  }

  // We have to apply the Google Fonts style on top of our own because
  // the package only requests the exact font style it needs. So if we simply
  // call the firaCode() method and take the "fontFamily" property, it won't
  // download the "bold" version or "italic" version.
  return GoogleFonts.firaCode(
    textStyle: style,
  );
}

class _StyleVisitor<R> extends RecursiveAstVisitor<R> {
  _StyleVisitor(this.lineInfo, this.document);

  final LineInfo lineInfo;
  final MutableDocument document;

  @override
  R? visitComment(Comment node) {
    final startLocation = lineInfo.getLocation(node.offset);
    final endLocation = lineInfo.getLocation(node.end);

    for (int line = startLocation.lineNumber; line <= endLocation.lineNumber; line += 1) {
      print("Styling line $line as a comment");
      final paragraph = document.getNodeAt(line - 1) as ParagraphNode; // -1 because first line is "1"
      paragraph.metadata["blockType"] = const NamedAttribution("comment");
    }

    return null;
  }

  @override
  R? visitVariableDeclaration(VariableDeclaration node) {
    final codeStartOffset = node.name2.offset;
    final codeEndOffset = node.name2.end;
    print("Styling a variable name: ${node.name2.lexeme}, $codeStartOffset -> $codeEndOffset");
    final lineIndex = lineInfo.getLocation(codeStartOffset).lineNumber - 1; // -1 because first line is "1"
    print("Line: $lineIndex");
    final lineStartInCode = lineInfo.getOffsetOfLine(lineIndex);
    print("Line start: $lineStartInCode");

    final paragraph = document.getNodeAt(lineIndex) as ParagraphNode;
    final paragraphStart = codeStartOffset - lineStartInCode;
    final paragraphEnd = codeEndOffset - lineStartInCode;
    print("Variable name within paragraph (${paragraph.text.text.length}): $paragraphStart -> $paragraphEnd");

    paragraph.text.addAttribution(
      const NamedAttribution("variableName"),
      SpanRange(start: paragraphStart, end: paragraphEnd),
    );

    return null;
  }

  @override
  R? visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.returnType != null) {
      final codeStartOffset = node.returnType!.offset;
      final codeEndOffset = node.returnType!.end;
      print("Styling a return type from $codeStartOffset -> $codeEndOffset");
      final lineIndex = lineInfo.getLocation(codeStartOffset).lineNumber - 1; // -1 because first line is "1"
      final lineStartInCode = lineInfo.getOffsetOfLine(lineIndex + 1);

      final paragraph = document.getNodeAt(lineIndex) as ParagraphNode;
      paragraph.text.addAttribution(
        const NamedAttribution("returnType"),
        SpanRange(start: codeStartOffset - lineStartInCode, end: codeEndOffset - lineStartInCode),
      );
    }

    return null;
  }
}

class PrintVisitor<R> extends RecursiveAstVisitor<R> {
  @override
  R? visitComment(Comment node) {
    print("Comment: Length - ${node.length}");
    for (final token in node.tokens) {
      print(" - ${token.lexeme}");
    }
    return null;
  }

  @override
  R? visitClassDeclaration(ClassDeclaration node) {
    print("Class:");

    print("Implements clause:");
    for (final implementsTerm in node.implementsClause!.childEntities) {
      print(" - ${implementsTerm.toString()}");
    }

    Token? token = node.firstTokenAfterCommentAndMetadata;
    // while (token != null) {
    print(" - ${token.lexeme}");
    token = token.next;
    print(" - ${token?.lexeme}");
    token = token?.next;
    print(" - ${token?.lexeme}");
    token = token?.next;
    print(" - ${token?.lexeme}");
    token = token?.next;
    print(" - ${token?.lexeme}");
    token = token?.next;
    print(" - ${token?.lexeme}");
    // }

    return null;
  }
}
