import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:inception/src/infrastructure/text/code_comment_selection_rules.dart';

void main() {
  group("Code comment selection rules >", () {
    group("dart >", () {
      test("selects surround word", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _dartCommentLine,
          9,
          TextAffinity.downstream,
          _dartCommentSyntaxes,
        );
        expect(range.textInside(_dartCommentLine), "This");
      });

      test("selects whole line when clicking comment syntax", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _dartCommentLine,
          5,
          TextAffinity.downstream,
          _dartCommentSyntaxes,
        );
        expect(range.textInside(_dartCommentLine), _dartCommentLine);
      });

      test("selects all of indent spaces", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _dartCommentLine,
          2,
          TextAffinity.downstream,
          _dartCommentSyntaxes,
        );
        expect(range.textInside(_dartCommentLine), "    ");
      });

      test("selects nearest word when clicking in whitespace", () {
        var range = CodeCommentSelection.findNearestSelectableToken(
          _dartCommentLine,
          11,
          TextAffinity.upstream,
          _dartCommentSyntaxes,
        );
        expect(range.textInside(_dartCommentLine), "This");

        range = CodeCommentSelection.findNearestSelectableToken(
          _dartCommentLine,
          11,
          TextAffinity.downstream,
          _dartCommentSyntaxes,
        );
        expect(range.textInside(_dartCommentLine), "is");
      });

      test("finds leading word boundary upstream", () {
        // "    // This is a comment line|" to
        // "    // This is a comment |line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 29),
          25,
        );

        // "    // This is a comment |line" to
        // "    // This is a |comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 24),
          17,
        );

        // "    // This is a |comment line" to
        // "    // This is |a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 17),
          15,
        );

        // "    // This is |a comment line" to
        // "    // This |is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 15),
          12,
        );

        // "    // This |is a comment line" to
        // "    // |This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 12),
          7,
        );

        // "    // |This is a comment line" to
        // "    |// This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 7),
          4,
        );

        // "    |// This is a comment line" to
        // "|    // This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 4),
          0,
        );

        //----------------- EDGE CASES ----------------

        // "|    // This is a comment line" to
        // "|    // This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 0),
          0,
        );

        // "  |  // This is a comment line" to
        // "|    // This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 2),
          0,
        );

        // "    |// This is a comment line" to
        // "|    // This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 4),
          0,
        );

        // "    /|/ This is a comment line" to
        // "    |// This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 5),
          4,
        );

        // "    //| This is a comment line" to
        // "    |// This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 6),
          4,
        );

        // "    // This is a com|ment line" to
        // "    // This is a |comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore(_dartCommentLine, _dartCommentSyntaxes, 20),
          17,
        );

        // Ensure that some other language's comment syntax doesn't completely break things.
        // "-- This is a comment line|" to
        // "-- This is a comment |line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore("-- This is a comment line", _dartCommentSyntaxes, 25),
          21,
        );

        // "-- |This is a comment line" to
        // "-|- This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAheadOfTokenBefore("-- This is a comment line", _dartCommentSyntaxes, 3),
          1,
        );
      });

      test("finds trailing word boundary downstream", () {
        // "|    // This is a comment line" to
        // "    //| This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 0),
          6,
        );

        // "    //| This is a comment line" to
        // "    // This| is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 7),
          11,
        );

        // "    // This| is a comment line" to
        // "    // This is| a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 11),
          14,
        );

        // "    // This is| a comment line" to
        // "    // This is a| comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 14),
          16,
        );

        // "    // This is a| comment line" to
        // "    // This is a comment| line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 16),
          24,
        );

        // "    // This is a comment| line" to
        // "    // This is a comment line|"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 24),
          29,
        );

        //----------------- EDGE CASES ----------------

        // Indentation in a comment line with no leading comment syntax.
        // "|  This is a comment line" to
        // "  |This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter("  This is a comment line", _dartCommentSyntaxes, 0),
          2,
        );

        // "|// This is a comment line" to
        // "//| This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter("// This is a comment line", _dartCommentSyntaxes, 0),
          2,
        );

        // "  |  // This is a comment line" to
        // "    //| This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 2),
          6,
        );

        // "    |// This is a comment line" to
        // "    //| This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 4),
          6,
        );

        // "    /|/ This is a comment line" to
        // "    //| This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 5),
          6,
        );

        // "    //| This is a comment line" to
        // "    // This| is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 6),
          11,
        );

        // "    // This is a comment line|" to
        // "    // This is a comment line|"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter(_dartCommentLine, _dartCommentSyntaxes, 29),
          29,
        );

        // Ensure that some other language's comment syntax doesn't completely break things.
        // "|-- This is a comment line" to
        // "-|- This is a comment line"
        expect(
          CodeCommentSelection.findCaretOffsetAtEndOfTokenAfter("-- This is a comment line", _dartCommentSyntaxes, 0),
          1,
        );
      });
    });

    group("luau >", () {
      test("selects surround word", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _luauCommentLine,
          9,
          TextAffinity.downstream,
          _luauCommentSyntaxes,
        );
        expect(range.textInside(_luauCommentLine), "This");
      });

      test("selects whole line when clicking comment syntax", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _luauCommentLine,
          5,
          TextAffinity.downstream,
          _luauCommentSyntaxes,
        );
        expect(range.textInside(_luauCommentLine), _luauCommentLine);
      });

      test("selects all of indent spaces", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _luauCommentLine,
          2,
          TextAffinity.downstream,
          _luauCommentSyntaxes,
        );
        expect(range.textInside(_luauCommentLine), "    ");
      });

      test("selects nearest word when clicking in whitespace", () {
        var range = CodeCommentSelection.findNearestSelectableToken(
          _luauCommentLine,
          11,
          TextAffinity.upstream,
          _luauCommentSyntaxes,
        );
        expect(range.textInside(_luauCommentLine), "This");

        range = CodeCommentSelection.findNearestSelectableToken(
          _luauCommentLine,
          11,
          TextAffinity.downstream,
          _luauCommentSyntaxes,
        );
        expect(range.textInside(_luauCommentLine), "is");
      });
    });
  });
}

const _dartCommentLine = "    // This is a comment line";
const _dartCommentSyntaxes = ["///", "//"];

const _luauCommentLine = "    -- This is a comment line";
const _luauCommentSyntaxes = ["--"];
