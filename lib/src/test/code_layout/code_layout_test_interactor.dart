import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:inception/inception.dart';
import 'package:inception/src/infrastructure/flutter_extensions/render_box_extensions.dart';
import 'package:super_editor/super_editor.dart' show kTapMinTime, kTapTimeout;

extension CodeLayoutTestInteractor on WidgetTester {
  /// Clicks between characters (or before/after characters) within the given [line], at the given
  /// [characterOffset].
  ///
  /// The [characterOffset] refers to the offset of the character that comes **after** the caret position.
  /// For example, a [characterOffset] of `0` refers to the caret position that appears before the
  /// first character in the code line. A [characterOffset] of `1` refers to the caret position that
  /// appears after the first character in the code line.
  ///
  /// To click within a character box, instead of between characters, use [clickOnCodePosition].
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

    final globalCaretRect = codeBox.localRectToGlobal(
      codeLayout.getLocalRectForCaret(CodePosition(line, characterOffset)),
    );

    final clickOffset = Offset(
      globalCaretRect.left + (globalCaretRect.width / 2),
      globalCaretRect.top + (globalCaretRect.height / 2),
    );

    await tapAt(clickOffset);
    await pump(kTapTimeout);

    if (settle) {
      await pumpAndSettle();
    }
  }

  /// Clicks on a character within the given [line], at the given [characterOffset].
  ///
  /// {@template character_click_box_affinity}
  /// The simulated click will happen either slightly to the left, or slightly to the right
  /// of the center of the character, as determined by the given [affinity]. This is done
  /// because caret and selection logic depends on proximity to the edge of a character - not
  /// the character box, itself.
  /// {@endtemplate}
  ///
  /// To click between character boxes, or to click at the start or end of text, beyond a character
  /// box, use [clickOnCaretPosition].
  Future<void> clickOnCodePosition(
    int line,
    int characterOffset, {
    TextAffinity affinity = TextAffinity.downstream,
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    return _multiClickAtCodePosition(
      line,
      characterOffset,
      clickCount: 1,
      affinity: affinity,
      settle: settle,
      codeLayoutFinder: codeLayoutFinder,
    );
  }

  /// Double clicks on the character box in the given [line] at the given [characterOffset].
  ///
  /// {@macro character_click_box_affinity}
  Future<void> doubleClickAtCodePosition(
    int line,
    int characterOffset, {
    TextAffinity affinity = TextAffinity.downstream,
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    return _multiClickAtCodePosition(
      line,
      characterOffset,
      clickCount: 2,
      affinity: affinity,
      settle: settle,
      codeLayoutFinder: codeLayoutFinder,
    );
  }

  /// Triple clicks on the character box in the given [line] at the given [characterOffset].
  ///
  /// {@macro character_click_box_affinity}
  Future<void> tripleClickAtCodePosition(
    int line,
    int characterOffset, {
    TextAffinity affinity = TextAffinity.downstream,
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    return _multiClickAtCodePosition(
      line,
      characterOffset,
      clickCount: 3,
      affinity: affinity,
      settle: settle,
      codeLayoutFinder: codeLayoutFinder,
    );
  }

  Future<void> _multiClickAtCodePosition(
    int line,
    int characterOffset, {
    required int clickCount,
    TextAffinity affinity = TextAffinity.downstream,
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    assert(clickCount >= 1);

    final (codeLayout, codeBox) = findCodeLayout(
      "multi-tap ($clickCount) at code position (line: $line, offset: $characterOffset)",
      codeLayoutFinder,
    );

    final globalCharacterRect = codeBox.localRectToGlobal(
      codeLayout.getLocalRectForCodePosition(CodePosition(line, characterOffset)),
    );

    final proportionalXAdjustment = switch (affinity) {
      TextAffinity.upstream => globalCharacterRect.width * 0.25,
      TextAffinity.downstream => globalCharacterRect.width * 0.75,
    };
    final clickOffset = Offset(
      globalCharacterRect.left + proportionalXAdjustment,
      globalCharacterRect.top + (globalCharacterRect.height / 2),
    );

    for (int i = 0; i < clickCount; i += 1) {
      await tapAt(clickOffset);
      await pump(kTapMinTime + const Duration(milliseconds: 1));
    }
    await pump(kTapTimeout);

    if (settle) {
      await pumpAndSettle();
    }
  }
}
