import 'package:flutter/painting.dart';
import 'package:super_editor/super_editor.dart';

class SyntaxTheme {
  const SyntaxTheme({
    required this.background,
    required this.baseTextStyle,
    required this.strong,
    required this.emphasis,
    required this.bullet,
    required this.quote,
    required this.link,
    required this.number,
    required this.regexp,
    required this.literal,
    required this.code,
    required this.keyword,
    required this.section,
    required this.attribute,
    required this.name,
    required this.variable,
    required this.params,
    required this.string,
    required this.subst,
    required this.type,
    required this.builtIn,
    required this.builtInName,
    required this.symbol,
    required this.templateTag,
    required this.templateVariable,
    required this.addition,
    required this.comment,
    required this.deletion,
    required this.meta,
  });

  final Color background;
  final TextStyle baseTextStyle;
  final TextStyle strong;
  final TextStyle emphasis;
  final TextStyle bullet;
  final TextStyle quote;
  final TextStyle link;
  final TextStyle number;
  final TextStyle regexp;
  final TextStyle literal;
  final TextStyle code;
  final TextStyle keyword;
  final TextStyle section;
  final TextStyle attribute;
  final TextStyle name;
  final TextStyle variable;
  final TextStyle params;
  final TextStyle string;
  final TextStyle subst;
  final TextStyle type;
  final TextStyle builtIn;
  final TextStyle builtInName;
  final TextStyle symbol;
  final TextStyle templateTag;
  final TextStyle templateVariable;
  final TextStyle addition;
  final TextStyle comment;
  final TextStyle deletion;
  final TextStyle meta;
}

const comment = NamedAttribution("comment");
const variableName = NamedAttribution("variableName");
