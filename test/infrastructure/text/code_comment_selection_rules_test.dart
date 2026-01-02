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
          ["///", "//"],
        );
        expect(range.textInside(_dartCommentLine), "This");
      });

      test("selects whole line when clicking comment syntax", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _dartCommentLine,
          5,
          TextAffinity.downstream,
          ["///", "//"],
        );
        expect(range.textInside(_dartCommentLine), _dartCommentLine);
      });

      test("selects all of indent spaces", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _dartCommentLine,
          2,
          TextAffinity.downstream,
          ["///", "//"],
        );
        expect(range.textInside(_dartCommentLine), "    ");
      });

      test("selects nearest word when clicking in whitespace", () {
        var range = CodeCommentSelection.findNearestSelectableToken(
          _dartCommentLine,
          11,
          TextAffinity.upstream,
          ["///", "//"],
        );
        expect(range.textInside(_dartCommentLine), "This");

        range = CodeCommentSelection.findNearestSelectableToken(
          _dartCommentLine,
          11,
          TextAffinity.downstream,
          ["///", "//"],
        );
        expect(range.textInside(_dartCommentLine), "is");
      });
    });

    group("luau >", () {
      test("selects surround word", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _luauCommentLine,
          9,
          TextAffinity.downstream,
          ["--"],
        );
        expect(range.textInside(_luauCommentLine), "This");
      });

      test("selects whole line when clicking comment syntax", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _luauCommentLine,
          5,
          TextAffinity.downstream,
          ["--"],
        );
        expect(range.textInside(_luauCommentLine), _luauCommentLine);
      });

      test("selects all of indent spaces", () {
        final range = CodeCommentSelection.findNearestSelectableToken(
          _luauCommentLine,
          2,
          TextAffinity.downstream,
          ["--"],
        );
        expect(range.textInside(_luauCommentLine), "    ");
      });

      test("selects nearest word when clicking in whitespace", () {
        var range = CodeCommentSelection.findNearestSelectableToken(
          _luauCommentLine,
          11,
          TextAffinity.upstream,
          ["--"],
        );
        expect(range.textInside(_luauCommentLine), "This");

        range = CodeCommentSelection.findNearestSelectableToken(
          _luauCommentLine,
          11,
          TextAffinity.downstream,
          ["--"],
        );
        expect(range.textInside(_luauCommentLine), "is");
      });
    });
  });
}

const _dartCommentLine = "    // This is a comment line";
const _luauCommentLine = "    -- This is a comment line";
