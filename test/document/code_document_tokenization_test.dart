import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:inception/inception.dart';

void main() {
  group('CodeDocument tokenization', () {
    late CodeDocument doc;
    late SpyTokenProvider spy;

    setUp(() {
      // Use the real LuauTokenizer wrapped in a spy
      spy = SpyTokenProvider(LuauLexer());
      doc = CodeDocument('')..lexer = spy;
    });

    test('initial empty document produces zero tokens', () {
      expect(doc.tokens, isEmpty);
    });

    test('simple document tokenizes correctly', () {
      doc.replaceRange(0, 0, 'local x = 42;');
      final tokens = doc.tokens;

      expect(tokens, isNotEmpty);
      expect(tokens.first.start, 0);
      expect(tokens.last.end, doc.length);

      // Example: check that "local" is tokenized as a keyword
      final localToken = tokens.firstWhere((t) => doc.text.substring(t.start, t.end) == 'local');
      expect(localToken.kind, SyntaxKind.keyword);
    });

    test('partial tokenization only tokenizes changed region', () {
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
    });

    test('token ranges shift correctly after insertion', () {
      doc.replaceRange(0, 0, '+');

      // Insert at start
      doc.replaceRange(0, 0, 'a');
      doc.insert(doc.length, 'b');

      expect(doc.text, 'a+b');
      final after = doc.tokens;
      print("Token: $after");

      // Ensure punctuation and word tokens are correct
      expect(after.length, 3);
      expect(doc.text.substring(after[0].start, after[0].end), 'a');
      expect(doc.text.substring(after[1].start, after[1].end), '+');
      expect(doc.text.substring(after[2].start, after[2].end), 'b');
    });

    test('token ranges shrink correctly after deletion', () {
      doc.replaceRange(0, 0, 'abcdef');
      final before = List.of(doc.tokens);

      // Delete "cd"
      doc.replaceRange(2, 4, '');
      final after = doc.tokens;

      // Remaining tokens should shift left
      for (var i = 0; i < after.length; i++) {
        final a = after[i];
        final b = before[i + 1]; // token after deleted region
        expect(a.start, equals(b.start - 2));
        expect(a.end, equals(b.end - 2));
      }
    });

    test('selection-aware highlighting returns intersecting tokens', () {
      doc.replaceRange(0, 0, 'local example = 42;\nlocal sample = 99;');

      final start = doc.text.indexOf('example');
      final end = start + 'example'.length;

      final selected = doc.tokensInRange(start, end);
      expect(selected, isNotEmpty);

      for (final t in selected) {
        expect(!(t.end <= start || t.start >= end), isTrue, reason: 'Token must intersect selection');
      }
    });

    test('selection-aware highlighting returns empty for non-overlapping range', () {
      doc.replaceRange(0, 0, 'local a = 1;\nlocal b = 2;');

      final selected = doc.tokensInRange(1000, 1010);
      expect(selected, isEmpty);
    });

    test('large insertions produce tokens without failure', () {
      final large = 'x' * 50000;
      doc.replaceRange(0, 0, large);
      expect(doc.tokens, isNotEmpty);
    });

    test('rapid consecutive edits maintain valid tokens', () {
      doc.replaceRange(0, 0, 'abc');
      doc.replaceRange(1, 2, 'ZZ');
      doc.replaceRange(0, 0, '---');
      doc.replaceRange(doc.length - 1, doc.length, '*');

      expect(doc.tokens, isNotEmpty);
      expect(doc.length, equals(doc.text.length));
    });
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
