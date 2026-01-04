import 'package:flutter/material.dart';
import 'package:inception/src/document/syntax_highlighter.dart';

/// A theme for Dart code syntax highlighting.
class DartTheme implements SyntaxTheme {
  DartTheme({
    required this.baseTextStyle,
    required this.keyword,
    required this.controlFlow,
    required this.identifier,
    required this.string,
    required this.number,
    required this.comment,
    required this.operator,
    required this.punctuation,
    required this.whitespace,
    required this.unknown,
  });

  /// Base style applied to plain text.
  final TextStyle baseTextStyle;

  // Syntax kinds
  final TextStyle keyword;
  final TextStyle controlFlow;
  final TextStyle identifier;
  final TextStyle string;
  final TextStyle number;
  final TextStyle comment;
  final TextStyle operator;
  final TextStyle punctuation;
  final TextStyle whitespace;
  final TextStyle unknown;

  /// Create a copy of the theme with optional overrides.
  DartTheme copyWith({
    TextStyle? baseTextStyle,
    TextStyle? keyword,
    TextStyle? controlFlow,
    TextStyle? identifier,
    TextStyle? string,
    TextStyle? number,
    TextStyle? comment,
    TextStyle? operator,
    TextStyle? punctuation,
    TextStyle? whitespace,
    TextStyle? unknown,
  }) {
    return DartTheme(
      baseTextStyle: baseTextStyle ?? this.baseTextStyle,
      keyword: keyword ?? this.keyword,
      controlFlow: controlFlow ?? this.controlFlow,
      identifier: identifier ?? this.identifier,
      string: string ?? this.string,
      number: number ?? this.number,
      comment: comment ?? this.comment,
      operator: operator ?? this.operator,
      punctuation: punctuation ?? this.punctuation,
      whitespace: whitespace ?? this.whitespace,
      unknown: unknown ?? this.unknown,
    );
  }

  /// Converts the theme to JSON.
  Map<String, dynamic> toJson() => {
        'baseTextStyle': _textStyleToJson(baseTextStyle),
        'keyword': _textStyleToJson(keyword),
        'controlFlow': _textStyleToJson(controlFlow),
        'identifier': _textStyleToJson(identifier),
        'string': _textStyleToJson(string),
        'number': _textStyleToJson(number),
        'comment': _textStyleToJson(comment),
        'operator': _textStyleToJson(operator),
        'punctuation': _textStyleToJson(punctuation),
        'whitespace': _textStyleToJson(whitespace),
        'unknown': _textStyleToJson(unknown),
      };

  /// Creates a DartTheme from JSON.
  factory DartTheme.fromJson(Map<String, dynamic> json) {
    return DartTheme(
      baseTextStyle: _textStyleFromJson(json['baseTextStyle']),
      keyword: _textStyleFromJson(json['keyword']),
      controlFlow: _textStyleFromJson(json['controlFlow']),
      identifier: _textStyleFromJson(json['identifier']),
      string: _textStyleFromJson(json['string']),
      number: _textStyleFromJson(json['number']),
      comment: _textStyleFromJson(json['comment']),
      operator: _textStyleFromJson(json['operator']),
      punctuation: _textStyleFromJson(json['punctuation']),
      whitespace: _textStyleFromJson(json['whitespace']),
      unknown: _textStyleFromJson(json['unknown']),
    );
  }

  // ---------------------
  // Helpers for TextStyle serialization
  // ---------------------
  static Map<String, dynamic> _textStyleToJson(TextStyle style) {
    return {
      'color': style.color?.toARGB32(),
      'fontSize': style.fontSize,
      'fontWeight': style.fontWeight?.index,
      'fontStyle': style.fontStyle?.index,
      'letterSpacing': style.letterSpacing,
      'height': style.height,
    };
  }

  static TextStyle _textStyleFromJson(Map<String, dynamic>? json) {
    if (json == null) return const TextStyle();
    return TextStyle(
      color: json['color'] != null ? Color(json['color']) : null,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontWeight: json['fontWeight'] != null ? FontWeight.values[json['fontWeight']] : null,
      fontStyle: json['fontStyle'] != null ? FontStyle.values[json['fontStyle']] : null,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );
  }
}
