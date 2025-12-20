import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Lexer (lexical analyzer) for a programming language.
///
/// A lexer scans code text for tokens. A token might be a keyword, identifier, literal,
/// operator, etc. See [SyntaxKind] for a complete list.
abstract class Lexer {
  /// Tokenize the entire document into [LexerToken]s.
  List<LexerToken> tokenize(String fullText);

  /// Tokenize only a specific range.
  ///
  /// Implementations may:
  /// - use the range to limit parsing work,
  /// - or fall back to full tokenization.
  ///
  /// Returning `null` means "I don’t support partial tokenization; fall back to full".
  List<LexerToken>? tokenizePartial({required String fullText, required TextRange range});
}

class LexerToken {
  const LexerToken(this.start, this.end, this.kind);

  final int start;
  final int end;

  final SyntaxKind kind;

  @override
  String toString() => "[LexerToken] - $start -> $end, $kind";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LexerToken &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          kind == other.kind;

  @override
  int get hashCode => start.hashCode ^ end.hashCode ^ kind.hashCode;
}

enum SyntaxKind {
  keyword,
  identifier,
  string,
  number,
  comment,
  operatorToken,
  punctuation,
  whitespace,
  unknown,
  @visibleForTesting
  testToken,
}
