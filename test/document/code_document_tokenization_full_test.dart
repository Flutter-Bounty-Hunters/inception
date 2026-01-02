import 'package:flutter_test/flutter_test.dart';
import 'package:inception/inception.dart';

void main() {
  group('CodeDocument tokenization', () {
    late CodeDocument doc;

    setUp(() {
      doc = CodeDocument(DartLexer(), '');
    });

    test('initial empty document produces zero tokens', () {
      expect(doc.tokens, isEmpty);
    });

    test('simple document tokenizes correctly', () {
      doc.replaceRange(0, 0, 'var x = 42;');
      final tokens = doc.tokens;

      expect(tokens, isNotEmpty);
      expect(tokens.first.start, 0);
      expect(tokens.last.end, doc.length);

      // Example: check that "var" is tokenized as a keyword
      final localToken = tokens.firstWhere((t) => doc.text.substring(t.start, t.end) == 'var');
      expect(localToken.kind, SyntaxKind.keyword);
    });

    test('token ranges shift correctly after insertion', () {
      doc.replaceRange(0, 0, '+');

      // Insert at start
      doc.replaceRange(0, 0, 'a');
      doc.insert(doc.length, 'b');

      expect(doc.text, 'a+b');
      final after = doc.tokens;

      // Ensure punctuation and word tokens are correct
      expect(after.length, 3);
      expect(doc.text.substring(after[0].start, after[0].end), 'a');
      expect(doc.text.substring(after[1].start, after[1].end), '+');
      expect(doc.text.substring(after[2].start, after[2].end), 'b');
    });

    test('token ranges shrink correctly after deletion', () {
      doc.replaceRange(0, 0, 'void main() {}');
      final before = List.of(doc.tokens);

      // Expect initial tokens.
      expect(before, [
        const LexerToken(0, 4, SyntaxKind.identifier),
        const LexerToken(4, 5, SyntaxKind.whitespace),
        const LexerToken(5, 9, SyntaxKind.identifier),
        const LexerToken(9, 10, SyntaxKind.punctuation),
        const LexerToken(10, 11, SyntaxKind.punctuation),
        const LexerToken(11, 12, SyntaxKind.whitespace),
        const LexerToken(12, 13, SyntaxKind.punctuation),
        const LexerToken(13, 14, SyntaxKind.punctuation),
      ]);

      // Delete "main"
      doc.replaceRange(5, 9, '');
      expect(doc.text, 'void () {}');
      final after = doc.tokens;

      // Expect tokens adjusted after deletion.
      expect(after, [
        const LexerToken(0, 4, SyntaxKind.identifier),
        const LexerToken(4, 5, SyntaxKind.whitespace),
        const LexerToken(5, 6, SyntaxKind.punctuation),
        const LexerToken(6, 7, SyntaxKind.punctuation),
        const LexerToken(7, 8, SyntaxKind.whitespace),
        const LexerToken(8, 9, SyntaxKind.punctuation),
        const LexerToken(9, 10, SyntaxKind.punctuation),
      ]);
    });

    test('selection-aware highlighting returns intersecting tokens', () {
      doc.replaceRange(0, 0, 'var example = 42;\var sample = 99;');

      final start = doc.text.indexOf('example');
      final end = start + 'example'.length;

      final selected = doc.tokensInRange(start, end);
      expect(selected, isNotEmpty);

      for (final t in selected) {
        expect(!(t.end <= start || t.start >= end), isTrue, reason: 'Token must intersect selection');
      }
    });

    test('selection-aware highlighting returns empty for non-overlapping range', () {
      doc.replaceRange(0, 0, 'var a = 1;\var b = 2;');

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

    test('does not tokenize newlines', () {
      doc.replaceRange(0, 0, 'var example = 42;\nvar sample = 99;');

      expect(doc.tokens[7], const LexerToken(16, 17, SyntaxKind.punctuation));
      expect(doc.tokens[8], const LexerToken(18, 21, SyntaxKind.keyword));
    });
  });
}
