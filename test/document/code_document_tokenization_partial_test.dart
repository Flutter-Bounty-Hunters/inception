import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:inception/inception.dart';
import 'package:inception/language_dart.dart';

void main() {
  group('CodeDocument tokenization', () {
    late CodeDocument doc;
    late SpyTokenProvider spy;

    setUp(() {
      // Use the real Dart lexer wrapped in a spy
      spy = SpyTokenProvider(DartLexer());
      doc = CodeDocument(spy, '');
    });

    test(
      'partial tokenization only tokenizes changed region',
      () {
        // Initial text
        doc.replaceRange(0, 0, 'print("Hello")\nprint("World")');
        spy.reset();

        // Edit only "Hello" → "Hi"
        final start = doc.text.indexOf('Hello');
        final end = start + 'Hello'.length;
        doc.replaceRange(start, end, 'Hi');

        // Only one call expected
        expect(spy.calls, 1);

        // Partial tokenization should cover the changed region
        expect(spy.recordedRanges.length, 1);
        final range = spy.recordedRanges.first;
        expect(range.start, start);
        expect(range.end, start + 2); // "Hi" length

        // Tokens outside that region should be identical objects
        final oldTokens = spy.lastFullTokensBeforeEdit;
        final newTokens = doc.tokens;

        final secondLineStart = doc.text.indexOf('\n') + 1;
        final oldSecond = oldTokens.where((t) => t.start >= secondLineStart);
        final newSecond = newTokens.where((t) => t.start >= secondLineStart);

        for (var i = 0; i < oldSecond.length && i < newSecond.length; i++) {
          expect(
            identical(oldSecond.elementAt(i), newSecond.elementAt(i)),
            isTrue,
            reason: 'Unchanged regions should preserve token objects',
          );
        }
      },
      // Skipping until partial tokenization is implemented correctly.
      skip: true,
    );
  });
}

/// ------------------
/// Spy wrapper for TokenProvider to verify partial tokenization
/// ------------------
class SpyTokenProvider implements Lexer {
  final Lexer _inner;

  SpyTokenProvider(this._inner);

  int calls = 0;
  final List<TextRange> recordedRanges = [];
  List<LexerToken> lastFullTokensBeforeEdit = const [];

  @override
  List<LexerToken> tokenize(String fullText) {
    calls++;
    lastFullTokensBeforeEdit = _inner.tokenize(fullText);
    return lastFullTokensBeforeEdit;
  }

  @override
  List<LexerToken>? tokenizePartial({required String fullText, required TextRange range}) {
    calls++;
    recordedRanges.add(range);
    return _inner.tokenizePartial(fullText: fullText, range: range);
  }

  void reset() {
    calls = 0;
    recordedRanges.clear();
  }
}
