import 'package:example/super_editor_exploration/code_samples.dart';
import 'package:flutter/material.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';

class FlutterSyntaxViewExample extends StatelessWidget {
  const FlutterSyntaxViewExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SyntaxView(
      code: codeString2, // Code text
      syntax: Syntax.DART, // Language
      syntaxTheme: _dracula, //SyntaxTheme.dracula(), // Theme
      fontSize: 12.0, // Font size
      withZoom: false, // Enable/Disable zoom icon controls
      withLinesCount: true, // Enable/Disable line number
      expanded: false, // Enable/Disable container expansion
    );
  }
}

final _dracula = SyntaxTheme(
  linesCountColor: const Color(0xFFFFFFFF).withOpacity(.7),
  backgroundColor: const Color(0xFF263238),
  baseStyle: const TextStyle(color: Color(0xFFFFFFFF)),
  numberStyle: const TextStyle(color: Color(0xFF6BC1FF)),
  commentStyle: const TextStyle(color: Color(0xFF9E9E9E)),
  // Includes "class", "implements", "required this", "final"
  keywordStyle: const TextStyle(color: Color(0xFFffa959)),
  stringStyle: const TextStyle(color: Color(0xFF93ffab)),
  punctuationStyle: const TextStyle(color: Color(0xFFFFFFFF)),
  // Includes class name, interfaces that are implemented, variable types
  classStyle: const TextStyle(color: Color(0xFF44ba8b)),
  constantStyle: const TextStyle(color: Color(0xFF795548)),
  zoomIconColor: const Color(0xFFFFFFFF),
);
