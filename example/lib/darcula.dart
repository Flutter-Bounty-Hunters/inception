import 'package:example/theme.dart';
import 'package:flutter/painting.dart';

const darculaTheme = SyntaxTheme(
  background: Color(0xff2b2b2b),
  baseTextStyle: TextStyle(color: Color(0xffbababa)),
  strong: TextStyle(color: Color(0xffa8a8a2)),
  emphasis: TextStyle(color: Color(0xffa8a8a2), fontStyle: FontStyle.italic),
  bullet: TextStyle(color: Color(0xff6896ba)),
  quote: TextStyle(color: Color(0xff6896ba)),
  link: TextStyle(color: Color(0xff6896ba)),
  number: TextStyle(color: Color(0xff6896ba)),
  regexp: TextStyle(color: Color(0xff6896ba)),
  literal: TextStyle(color: Color(0xff6896ba)),
  code: TextStyle(color: Color(0xffa6e22e)),
  // In flutter_highlight, keyword -> "class", "implements", "this.", "final", "void", "async", "if", "null", "await"
  keyword: TextStyle(color: Color(0xffcb7832)),
  section: TextStyle(color: Color(0xffcb7832)),
  attribute: TextStyle(color: Color(0xffcb7832)),
  name: TextStyle(color: Color(0xffcb7832)),
  variable: TextStyle(color: Color(0xffcb7832)),
  params: TextStyle(color: Color(0xffb9b9b9)),
  string: TextStyle(color: Color(0xff6a8759)),
  subst: TextStyle(color: Color(0xffe0c46c)),
  type: TextStyle(color: Color(0xffe0c46c)),
  // In flutter_highlight, builtIn -> known types, such as `final Duration elapsedTime`, styles "Duration"
  // Also, "Function" in `typedef something = void Function();`
  builtIn: TextStyle(color: Color(0xffe0c46c)),
  builtInName: TextStyle(color: Color(0xffe0c46c)),
  symbol: TextStyle(color: Color(0xffe0c46c)),
  templateTag: TextStyle(color: Color(0xffe0c46c)),
  templateVariable: TextStyle(color: Color(0xffe0c46c)),
  addition: TextStyle(color: Color(0xffe0c46c)),
  comment: TextStyle(color: Color(0xff7f7f7f)),
  deletion: TextStyle(color: Color(0xff7f7f7f)),
  meta: TextStyle(color: Color(0xff7f7f7f)),
);
