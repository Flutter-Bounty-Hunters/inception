import 'dart:ui';

import 'package:inception/inception.dart';

class FakeLexer implements Lexer {
  @override
  List<LexerToken> tokenize(String fullText) {
    return [];
  }

  @override
  List<LexerToken>? tokenizePartial({required String fullText, required TextRange range}) {
    return null;
  }
}
