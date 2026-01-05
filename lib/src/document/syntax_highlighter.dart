import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:inception/src/document/code_document.dart';

/// Syntax highlighter, which highlights every line of code in an attached [CodeDocument].
///
/// To highlight a document, and continue highlighting it when it changes, call [attachToDocument].
///
/// To display the styled lines, get the [lineCount] and then query desired lines with [getStyledLineAt].
abstract class CodeDocumentSyntaxHighlighter implements LexerTokenListener, ChangeNotifier {
  /// Sets the base text style, on top of which the [theme] is applied.
  ///
  /// When the base text style is changed, all syntax highlighting is re-run, recreating
  /// all styled lines in the document.
  set baseTextStyle(TextStyle textStyle);

  /// Sets the theme for this syntax highlighter.
  ///
  /// When the theme is changed, all syntax highlighting is re-run, recreating all
  /// styled lines in the document.
  set theme(covariant SyntaxTheme theme);

  /// Highlights the code in the given [document], and begins watching for changes,
  /// which trigger syntax highlight updates.
  void attachToDocument(CodeDocument document);

  /// Stops watching the attached document for changes, and clears out all styled lines.
  void detachFromDocument();

  /// The number of lines that this highlighter has highlighted, each of which are
  /// available from [getStyledLineAt].
  int get lineCount;

  /// Returns the syntax-highlighted line at index [lineIndex].
  TextSpan? getStyledLineAt(int lineIndex);
}

abstract class SyntaxTheme {
  // Marker interface for all syntax themes. Each language's theme might care about
  // different tokens and context, so there's no universal API for a theme.
}
