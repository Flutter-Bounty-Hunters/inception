import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inception/src/editor/code_layout.dart';

/// Finds and returns the [CodeLinesState] to a [CodeLines] widget in the widget tree.
///
/// The [CodeLines] widget is found with the given [codeLinesFinder], or is found `byType()` if no
/// [codeLinesFinder] is provided.
///
/// If zero, or 2+ [CodeLines] are found with the [Finder], an exception is thrown. The exception
/// uses the given [interactionDescription] to specify what the code was trying to do when the exception
/// was thrown. Example:
///
///     Tried to "click on line 3 at offset 10", but didn't find a CodeLines in the widget tree.
///
CodeLinesState findCodeLines(String interactionDescription, [Finder? codeLinesFinder]) {
  final finderResults = (codeLinesFinder ?? find.byType(CodeLines)).evaluate();
  if (finderResults.isEmpty) {
    throw Exception(
      "Tried to $interactionDescription, but didn't find a CodeLinesLayout in the widget tree.",
    );
  }
  if (finderResults.length > 1) {
    throw Exception(
      "Tried to $interactionDescription, but multiple CodeLinesLayout were fund in the widget tree.",
    );
  }

  final codeLayoutElement = finderResults.first;
  if (codeLayoutElement is! StatefulElement) {
    throw Exception(
      "Tried to $interactionDescription, but CodeLinesLayout isn't a StatefulWidget. It should be.",
    );
  }
  final codeLayout = codeLayoutElement.state;
  if (codeLayout is! CodeLinesState) {
    throw Exception(
      "Tried to $interactionDescription, but the StatefulWidget isn't a CodeLinesState. It should be.",
    );
  }

  return codeLayout;
}

/// Finds and returns the [CodeLinesLayout] and the [RenderBox] belonging to a [CodeLines] widget
/// in the widget tree.
///
/// The [CodeLines] widget is found with the given [codeLayoutFinder], or is found `byType()` if no
/// [codeLayoutFinder] is provided.
///
/// If zero, or 2+ [CodeLines] are found with the [Finder], an exception is thrown. The exception
/// uses the given [interactionDescription] to specify what the code was trying to do when the exception
/// was thrown. Example:
///
///     Tried to "click on line 3 at offset 10", but didn't find a CodeLinesLayout in the widget tree.
///
(CodeLinesLayout, RenderBox) findCodeLayout(String interactionDescription, [Finder? codeLayoutFinder]) {
  final finderResults = (codeLayoutFinder ?? find.byType(CodeLines)).evaluate();
  if (finderResults.isEmpty) {
    throw Exception(
      "Tried to $interactionDescription, but didn't find a CodeLinesLayout in the widget tree.",
    );
  }
  if (finderResults.length > 1) {
    throw Exception(
      "Tried to $interactionDescription, but multiple CodeLinesLayout were fund in the widget tree.",
    );
  }

  final codeLayoutElement = finderResults.first;
  if (codeLayoutElement is! StatefulElement) {
    throw Exception(
      "Tried to $interactionDescription, but CodeLinesLayout isn't a StatefulWidget. It should be.",
    );
  }
  final codeLayout = codeLayoutElement.state;
  if (codeLayout is! CodeLinesLayout) {
    throw Exception(
      "Tried to $interactionDescription, but the StatefulWidget doesn't implement CodeLinesLayout. It should.",
    );
  }

  return (codeLayout as CodeLinesLayout, codeLayoutElement.state.context.findRenderObject() as RenderBox);
}
