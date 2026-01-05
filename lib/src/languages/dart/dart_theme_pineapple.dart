import 'package:flutter/material.dart';
import 'package:inception/src/languages/dart/dart_theme.dart';

final pineappleDartTheme = DartTheme(
  baseTextStyle: const TextStyle(
    color: Color(0xFFECE7D5),
    fontSize: 14,
    height: 1.4,
  ),

  // Keywords like class, void, final
  keyword: const TextStyle(
    color: Color(0xFFF2C94C), // pineapple yellow
    fontWeight: FontWeight.w600,
  ),

  // Control flow like if, else, for, while, return
  controlFlow: const TextStyle(
    color: Color(0xFFE1B12C), // deeper golden yellow
    fontWeight: FontWeight.w600,
  ),

  // Identifiers: variables, functions, class names
  identifier: const TextStyle(
    color: Color(0xFFECE7D5),
  ),

  // Strings
  string: const TextStyle(
    color: Color(0xFF2D9C5A), // pineapple leaf green
  ),

  // Numbers
  number: const TextStyle(
    color: Color(0xFFF2994A), // mango / papaya orange
  ),

  // Comments
  comment: const TextStyle(
    color: Color(0xFF6B8E6E), // muted tropical green
    fontStyle: FontStyle.italic,
  ),

  // Operators: = + - * / => etc
  operator: const TextStyle(
    color: Color(0xFF5C4A32), // darker brown for structure
  ),

  // Punctuation: {} () [] , ;
  punctuation: const TextStyle(
    color: Color(0xFF7CD992),
  ),

  // Whitespace (usually invisible, but keep defined)
  whitespace: const TextStyle(
    color: Color(0xFF3A2E1F),
  ),

  // Unknown / fallback tokens
  unknown: const TextStyle(
    color: Color(0xFFB08968), // soft sand tone
  ),
);
