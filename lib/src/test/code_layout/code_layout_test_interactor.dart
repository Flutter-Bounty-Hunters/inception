import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inception/inception.dart';
import 'package:inception/src/infrastructure/flutter_extensions/render_box_extensions.dart';
import 'package:inception/src/test/code_layout/code_layout_finders.dart';

extension CodeLayoutTestInteractor on WidgetTester {
  /// Click's on the character in the given [line], at the given [characterOffset], and clicks
  /// slightly towards the upstream side of the character (e.g., the left side for LTR languages).
  ///
  /// {@template why_not_click_center}
  /// ### Why doesn't this method click on the center of the character?
  /// In practice, clicking on a character will place the caret on one side of the character,
  /// or the other. Rather than leave that ambiguous, this API makes it clear which side of
  /// the character is clicked, and therefore which side of the character the caret will be
  /// placed.
  /// {@endtemplate}
  Future<void> clickOnCharacterUpstream(
    int line,
    int characterOffset, {
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    final (codeLayout, codeBox) = findCodeLayout(
      "tap at code position (line: $line, offset: $characterOffset)",
      codeLayoutFinder,
    );

    final globalCharacterRect = codeBox.localRectToGlobal(
      codeLayout.getLocalRectForCodePosition(CodePosition(line, characterOffset)),
    );

    final clickOffset = Offset(
      globalCharacterRect.left + (globalCharacterRect.width * 0.25),
      globalCharacterRect.top + (globalCharacterRect.height / 2),
    );

    await tapAt(clickOffset);

    if (settle) {
      await pumpAndSettle();
    }
  }

  /// Click's on the character in the given [line], at the given [characterOffset], and clicks
  /// slightly towards the downstream side of the character (e.g., the right side for LTR languages).
  ///
  /// {@macro why_not_click_center}
  Future<void> clickOnCharacterDownstream(
    int line,
    int characterOffset, {
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    final (codeLayout, codeBox) = findCodeLayout(
      "tap at code position (line: $line, offset: $characterOffset)",
      codeLayoutFinder,
    );

    final globalCharacterRect = codeBox.localRectToGlobal(
      codeLayout.getLocalRectForCodePosition(CodePosition(line, characterOffset)),
    );

    final clickOffset = Offset(
      globalCharacterRect.left + (globalCharacterRect.width * 0.75),
      globalCharacterRect.top + (globalCharacterRect.height / 2),
    );

    await tapAt(clickOffset);

    if (settle) {
      await pumpAndSettle();
    }
  }

  /// Clicks between characters (or before/after characters) within the given [line], at the given
  /// [characterOffset].
  ///
  /// The [characterOffset] refers to the offset of the character that comes **after** the caret position.
  /// For example, a [characterOffset] of `0` refers to the caret position that appears before the
  /// first character in the code line. A [characterOffset] of `1` refers to the caret position that
  /// appears after the first character in the code line.
  Future<void> clickOnCaretPosition(
    int line,
    int characterOffset, {
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    final (codeLayout, codeBox) = findCodeLayout(
      "tap at code position (line: $line, offset: $characterOffset)",
      codeLayoutFinder,
    );

    final globalCharacterRect = codeBox.localRectToGlobal(
      codeLayout.getLocalRectForCaret(CodePosition(line, characterOffset)),
    );

    final clickOffset = Offset(
      globalCharacterRect.left + (globalCharacterRect.width / 2),
      globalCharacterRect.top + (globalCharacterRect.height / 2),
    );

    await tapAt(clickOffset);

    if (settle) {
      await pumpAndSettle();
    }
  }

  Future<void> doubleClickAtCodePosition(
    int line,
    int offset, {
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    // TODO:
  }

  Future<void> tripleClickAtCodePosition(
    int line,
    int offset, {
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    // TODO:
  }
}
