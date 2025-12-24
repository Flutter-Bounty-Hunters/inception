import 'package:flutter_test/flutter_test.dart';
import 'package:inception/src/document/selection.dart';
import 'package:inception/src/test/code_layout/code_layout_finders.dart';

abstract class CodeLinesInspector {
  /// Finds a [CodeLines] in the widget tree and returns the [CodePosition] where that
  /// [CodeLines] currently thinks it's displaying a caret.
  ///
  /// We say it's where the [CodeLines] "thinks" its displaying a caret because this method doesn't
  /// inspect any pixels. Its up to [CodeLines] to ensure that its logical configuration matches
  /// its visual presentation.
  static CodePosition? findCaretPosition({
    Finder? codeLinesFinder,
  }) {
    final codeLines = findCodeLines("find caret position", codeLinesFinder);
    return codeLines.caretPosition;
  }

  static CodePosition? findPositionBefore(
    CodePosition position, {
    Finder? codeLinesFinder,
  }) {
    final codeLines = findCodeLines("find position before $position", codeLinesFinder);
    return codeLines.findPositionBefore(position);
  }

  static CodePosition? findPositionAfter(
    CodePosition position, {
    Finder? codeLinesFinder,
  }) {
    final codeLines = findCodeLines("find position after $position", codeLinesFinder);
    return codeLines.findPositionAfter(position);
  }

  static CodePosition findEndPosition({
    Finder? codeLinesFinder,
  }) {
    final codeLines = findCodeLines("find end position", codeLinesFinder);
    return codeLines.findEndPosition();
  }
}
