import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:inception/inception.dart';
import 'package:inception/src/infrastructure/flutter_extensions/render_box_extensions.dart';
import 'package:super_editor/super_editor.dart' show kTapMinTime, kTapTimeout;

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
  // TODO: De-dup this implementation with double and triple click.
  Future<void> clickOnCodePosition(
    int line,
    int characterOffset, {
    TextAffinity affinity = TextAffinity.downstream,
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

    final proportionalXAdjustment = switch (affinity) {
      TextAffinity.upstream => globalCharacterRect.width * 0.25,
      TextAffinity.downstream => globalCharacterRect.width * 0.75,
    };
    final clickOffset = Offset(
      globalCharacterRect.left + proportionalXAdjustment,
      globalCharacterRect.top + (globalCharacterRect.height / 2),
    );

    await tapAt(clickOffset);
    await pump(kTapTimeout);

    if (settle) {
      await pumpAndSettle();
    }
  }

  /// Double clicks on the character box in the given [line] at the given [characterOffset].
  ///
  /// {@macro character_click_box_affinity}
  // TODO: De-dup this implementation with single and triple click.
  Future<void> doubleClickAtCodePosition(
    int line,
    int characterOffset, {
    TextAffinity affinity = TextAffinity.downstream,
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    final (codeLayout, codeBox) = findCodeLayout(
      "double tap at code position (line: $line, offset: $characterOffset)",
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

    await tapAt(clickOffset);
    await pump(kTapMinTime + const Duration(milliseconds: 1));
    await tapAt(clickOffset);
    await pump(kTapTimeout);

    if (settle) {
      await pumpAndSettle();
    }
  }

  // TODO: De-dup this implementation with single and double click.
  Future<void> tripleClickAtCodePosition(
    int line,
    int characterOffset, {
    TextAffinity affinity = TextAffinity.downstream,
    bool settle = true,
    Finder? codeLayoutFinder,
  }) async {
    final (codeLayout, codeBox) = findCodeLayout(
      "triple tap at code position (line: $line, offset: $characterOffset)",
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

    await tapAt(clickOffset);
    await pump(kTapMinTime + const Duration(milliseconds: 1));
    await tapAt(clickOffset);
    await pump(kTapMinTime + const Duration(milliseconds: 1));
    await tapAt(clickOffset);
    await pump(kTapTimeout);

    if (settle) {
      await pumpAndSettle();
    }
  }
}
