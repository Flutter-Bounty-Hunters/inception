import 'package:inception/src/document/lexing.dart';

class DartContextualizer {
  const DartContextualizer();

  /// Contextualizes lexer tokens by reclassifying identifiers based on
  /// surrounding syntax (functions, parameters, types, etc).
  ///
  /// This method NEVER mutates existing tokens.
  List<LexerToken> contextualize(String source, List<LexerToken> tokens) {
    final List<LexerToken> result = <LexerToken>[];

    for (int i = 0; i < tokens.length; i++) {
      final LexerToken token = tokens[i];

      if (token.kind == SyntaxKind.identifier) {
        final SyntaxKind? contextualKind = _classifyIdentifier(tokens, i);

        if (contextualKind != null && contextualKind != token.kind) {
          result.add(
            LexerToken(token.start, token.end, contextualKind),
          );
          continue;
        }
      }

      result.add(token);
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Identifier classification
  // ---------------------------------------------------------------------------

  SyntaxKind? _classifyIdentifier(
    List<LexerToken> tokens,
    int index,
  ) {
    if (_isFunctionName(tokens, index)) {
      return SyntaxKind.keyword;
    }

    if (_isParameter(tokens, index)) {
      return SyntaxKind.controlFlow;
    }

    if (_isTypeName(tokens, index)) {
      return SyntaxKind.keyword;
    }

    if (_isEnumValue(tokens, index)) {
      return SyntaxKind.number;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Detection helpers
  // ---------------------------------------------------------------------------

  bool _isFunctionName(List<LexerToken> tokens, int index) {
    // identifier followed by '('
    if (!_hasNext(tokens, index)) return false;

    final LexerToken next = tokens[index + 1];
    return next.kind == SyntaxKind.punctuation;
  }

  bool _isParameter(List<LexerToken> tokens, int index) {
    // identifier inside parameter list: ( identifier , identifier )
    if (!_hasPrevious(tokens, index) || !_hasNext(tokens, index)) {
      return false;
    }

    final LexerToken prev = tokens[index - 1];
    final LexerToken next = tokens[index + 1];

    return (prev.kind == SyntaxKind.punctuation || prev.kind == SyntaxKind.operatorToken) &&
        (next.kind == SyntaxKind.punctuation || next.kind == SyntaxKind.operatorToken);
  }

  bool _isTypeName(List<LexerToken> tokens, int index) {
    // identifier after keywords like class, enum, extends, implements
    if (!_hasPrevious(tokens, index)) return false;

    final LexerToken prev = tokens[index - 1];

    if (prev.kind != SyntaxKind.keyword) return false;

    // We don't have token text, so we rely on structure only
    return true;
  }

  bool _isEnumValue(List<LexerToken> tokens, int index) {
    // identifier following enum declaration body punctuation
    if (!_hasPrevious(tokens, index)) return false;

    final LexerToken prev = tokens[index - 1];
    return prev.kind == SyntaxKind.punctuation;
  }

  // ---------------------------------------------------------------------------
  // Bounds helpers
  // ---------------------------------------------------------------------------

  bool _hasNext(List<LexerToken> tokens, int index) {
    return index + 1 < tokens.length;
  }

  bool _hasPrevious(List<LexerToken> tokens, int index) {
    return index - 1 >= 0;
  }
}
