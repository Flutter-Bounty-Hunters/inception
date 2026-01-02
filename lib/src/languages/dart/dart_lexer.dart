import 'dart:ui';

import 'package:inception/src/document/lexing.dart';

class DartLexer implements Lexer {
  @override
  List<LexerToken> tokenize(String source) {
    return _tokenizeRange(source, 0, source.length);
  }

  @override
  List<LexerToken> tokenizePartial({required String fullText, required TextRange range}) {
    // Expand range slightly to avoid cutting tokens
    final int safeStart = _expandBackward(fullText, range.start);
    final int safeEnd = _expandForward(fullText, range.end);

    final tokens = _tokenizeRange(fullText, safeStart, safeEnd);

    // Return only tokens that overlap the requested range
    return tokens.where((t) => t.end > range.start && t.start < range.end).toList();
  }

  // ─────────────────────────────────────────────
  // Core tokenizer
  // ─────────────────────────────────────────────

  List<LexerToken> _tokenizeRange(String source, int start, int end) {
    final List<LexerToken> tokens = [];
    int index = start;

    while (index < end) {
      final int tokenStart = index;
      final String char = source[index];

      if (char == '\n') {
        // Don't tokenize newlines.
        index += 1;
        continue;
      }

      // Whitespace
      if (_isWhitespace(char)) {
        index++;
        while (index < end && _isWhitespace(source[index])) {
          index++;
        }
        tokens.add(LexerToken(tokenStart, index, SyntaxKind.whitespace));
        continue;
      }

      // Line comment
      if (_startsWith(source, index, '//')) {
        index += 2;
        while (index < end && source[index] != '\n') {
          index++;
        }
        tokens.add(LexerToken(tokenStart, index, SyntaxKind.comment));
        continue;
      }

      // Block comment
      if (_startsWith(source, index, '/*')) {
        index += 2;
        while (index < end && !_startsWith(source, index, '*/')) {
          index++;
        }
        if (index < end) index += 2;
        tokens.add(LexerToken(tokenStart, index, SyntaxKind.comment));
        continue;
      }

      // Strings
      if (char == '"' || char == "'") {
        final String quote = char;
        index++;

        final bool isTriple = index + 1 < end && source[index] == quote && source[index + 1] == quote;

        if (isTriple) {
          index += 2;
          while (index < end && !_startsWith(source, index, '$quote$quote$quote')) {
            index++;
          }
          if (index < end) index += 3;
        } else {
          while (index < end) {
            if (source[index] == '\\') {
              index += 2;
              continue;
            }
            if (source[index] == quote) {
              index++;
              break;
            }
            index++;
          }
        }

        tokens.add(LexerToken(tokenStart, index, SyntaxKind.string));
        continue;
      }

      // Numbers
      if (_isDigit(char)) {
        index++;
        while (index < end && _isDigit(source[index])) {
          index++;
        }
        if (index < end && source[index] == '.') {
          index++;
          while (index < end && _isDigit(source[index])) {
            index++;
          }
        }
        tokens.add(LexerToken(tokenStart, index, SyntaxKind.number));
        continue;
      }

      // Identifiers / keywords
      if (_isIdentifierStart(char)) {
        index++;
        while (index < end && _isIdentifierPart(source[index])) {
          index++;
        }

        final String word = source.substring(tokenStart, index);

        if (_dartControlFlow.contains(word)) {
          tokens.add(LexerToken(tokenStart, index, SyntaxKind.controlFlow));
        } else if (_dartKeywords.contains(word)) {
          tokens.add(LexerToken(tokenStart, index, SyntaxKind.keyword));
        } else {
          tokens.add(LexerToken(tokenStart, index, SyntaxKind.identifier));
        }
        continue;
      }

      // Operators
      if (_isOperatorChar(char)) {
        index++;
        while (index < end && _isOperatorChar(source[index])) {
          index++;
        }
        tokens.add(LexerToken(tokenStart, index, SyntaxKind.operatorToken));
        continue;
      }

      // Punctuation
      if (_isPunctuation(char)) {
        index++;
        tokens.add(LexerToken(tokenStart, index, SyntaxKind.punctuation));
        continue;
      }

      // Fallback
      index++;
      tokens.add(LexerToken(tokenStart, index, SyntaxKind.unknown));
    }

    return tokens;
  }
}

/// ─────────────────────────────────────────────
/// Range expansion helpers
/// ─────────────────────────────────────────────

int _expandBackward(String source, int index) {
  while (index > 0) {
    final c = source[index - 1];
    if (c == '\n' || c == ';') break;
    index--;
  }
  return index;
}

int _expandForward(String source, int index) {
  while (index < source.length) {
    final c = source[index];
    if (c == '\n' || c == ';') break;
    index++;
  }
  return index;
}

/// ─────────────────────────────────────────────
/// Character helpers
/// ─────────────────────────────────────────────

bool _startsWith(String source, int index, String pattern) {
  if (index + pattern.length > source.length) return false;
  return source.substring(index, index + pattern.length) == pattern;
}

bool _isWhitespace(String c) => c == ' ' || c == '\t' || c == '\n' || c == '\r';

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

bool _isIdentifierStart(String c) {
  final int code = c.codeUnitAt(0);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || c == '_' || c == r'$';
}

bool _isIdentifierPart(String c) => _isIdentifierStart(c) || _isDigit(c);

bool _isOperatorChar(String c) => '+-*/%=!<>|&^~?.'.contains(c);

bool _isPunctuation(String c) => '(){}[];,.:'.contains(c);

/// ─────────────────────────────────────────────
/// Dart keyword tables
/// ─────────────────────────────────────────────

const Set<String> _dartKeywords = {
  'class',
  'enum',
  'extends',
  'implements',
  'with',
  'mixin',
  'typedef',
  'import',
  'export',
  'library',
  'part',
  'as',
  'show',
  'hide',
  'const',
  'final',
  'var',
  'late',
  'static',
  'abstract',
  'base',
  'interface',
  'sealed',
  'factory',
  'operator',
  'external',
  'get',
  'set',
  'async',
  'sync',
  'await',
  'yield',
  'on',
  'required',
};

const Set<String> _dartControlFlow = {
  'if',
  'else',
  'for',
  'while',
  'do',
  'switch',
  'case',
  'default',
  'break',
  'continue',
  'return',
  'throw',
  'try',
  'catch',
  'finally',
  'rethrow',
};
