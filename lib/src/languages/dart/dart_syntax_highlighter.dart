import 'package:flutter/widgets.dart';
import 'package:inception/src/document/code_document.dart';
import 'package:inception/src/document/lexing.dart';
import 'package:inception/src/document/syntax_highlighter.dart';
import 'package:inception/src/languages/dart/dart_theme.dart';

class DartSyntaxHighlighter with ChangeNotifier implements CodeDocumentSyntaxHighlighter {
  DartSyntaxHighlighter(this._theme, this._baseTextStyle) {
    _genericStyles = {
      SyntaxKind.keyword: _theme.keyword,
      SyntaxKind.controlFlow: _theme.controlFlow,
      SyntaxKind.identifier: _theme.identifier,
      SyntaxKind.string: _theme.string,
      SyntaxKind.number: _theme.number,
      SyntaxKind.comment: _theme.comment,
      SyntaxKind.operatorToken: _theme.operator,
      SyntaxKind.punctuation: _theme.punctuation,
      SyntaxKind.whitespace: _theme.whitespace,
      SyntaxKind.unknown: _theme.unknown,
    };
  }

  TextStyle _baseTextStyle;

  @override
  set baseTextStyle(TextStyle baseTextStyle) {
    if (_baseTextStyle == baseTextStyle) {
      return;
    }

    _baseTextStyle = baseTextStyle;
    _rebuildAllLines();
  }

  DartTheme _theme;

  @override
  set theme(DartTheme theme) {
    if (theme == _theme) {
      return;
    }

    _theme = theme;

    if (_attachedDocument != null) {
      // Re-highlight with the new theme.
      _rebuildAllLines();
    }
  }

  CodeDocument? _attachedDocument;

  @override
  int get lineCount => _lineSpans.length;

  @override
  TextSpan? getStyledLineAt(int lineIndex) {
    if (lineIndex < 0 || lineIndex >= _lineSpans.length) return null;
    return _lineSpans[lineIndex];
  }

  final List<TextSpan> _lineSpans = [];

  @override
  void attachToDocument(CodeDocument document) {
    detachFromDocument();
    _attachedDocument = document;
    _attachedDocument!.addTokenChangeListener(this);
    _rebuildAllLines();
  }

  @override
  void detachFromDocument() {
    _attachedDocument?.removeTokenChangeListener(this);
    _attachedDocument = null;
    _lineSpans.clear();
  }

  @override
  void onTokensChanged(int start, int end, List<LexerToken> newTokens) {
    final doc = _attachedDocument;
    if (doc == null) {
      return;
    }

    final startLine = doc.offsetToCodePosition(start).line;
    final endLine = doc.offsetToCodePosition(end).line;

    // If line count changed → rebuild everything
    if (_lineSpans.length != doc.lineCount) {
      _rebuildAllLines();
      return;
    }

    // Otherwise rebuild only affected lines
    for (int line = startLine; line <= endLine; line++) {
      if (line >= 0 && line < _lineSpans.length) {
        _lineSpans[line] = _buildLineSpan(doc, line);
      }
    }

    notifyListeners();
  }

  void _rebuildAllLines() {
    final doc = _attachedDocument;
    if (doc == null) return;

    _lineSpans.clear();
    for (int i = 0; i < doc.lineCount; i++) {
      _lineSpans.add(_buildLineSpan(doc, i));
    }

    notifyListeners();
  }

  // ---------------------
  // Styling helpers
  // ---------------------

  late final Map<SyntaxKind, TextStyle> _genericStyles;

  // Dart built-in types and keywords we want highlighted specially
  static const Set<String> _builtinTypes = {
    'int',
    'double',
    'num',
    'String',
    'bool',
    'dynamic',
    'void',
    'Object',
    'List',
    'Map',
    'Set',
    'Future',
    'Stream',
    'DateTime',
    'RegExp',
  };

  static const Set<String> _builtinKeywords = {
    'if',
    'else',
    'for',
    'while',
    'do',
    'switch',
    'case',
    'default',
    'break',
    'continue',
    'return',
    'try',
    'catch',
    'finally',
    'throw',
    'class',
    'extends',
    'implements',
    'abstract',
    'enum',
    'const',
    'final',
    'var',
    'late',
    'async',
    'await',
    'yield',
    'super',
    'this',
    'new',
  };

  // ---------------------
  // Main line builder
  // ---------------------

  TextSpan _buildLineSpan(CodeDocument doc, int lineIndex) {
    final text = doc.text;
    final lineStart = doc.getLineStart(lineIndex);
    final lineEnd = doc.getLineEnd(lineIndex);

    final lineTokens = doc.tokensInRange(lineStart, lineEnd);

    final List<TextSpan> spans = [];
    int lastOffset = lineStart;

    for (final token in lineTokens) {
      // Clip the token to the current line
      final clippedStart = token.start.clamp(lineStart, lineEnd);
      final clippedEnd = token.end.clamp(lineStart, lineEnd);

      // Skip empty spans
      if (clippedStart >= clippedEnd) continue;

      // Add any unstyled text between last token and current token,
      // but give it an explicit default style so rendering can't "inherit".
      if (clippedStart > lastOffset) {
        final gapText = text.substring(lastOffset, clippedStart);
        spans.add(TextSpan(text: gapText, style: _baseTextStyle));
      }

      // Token text
      final tokenText = text.substring(clippedStart, clippedEnd);

      // Decide token style: base tokenKind style, possibly overridden by token text.
      TextStyle tokenKindStyle = _genericStyles[token.kind] ?? _theme.baseTextStyle;

      // If tokenizer labeled this as an identifier but its literal text is a builtin type
      // color it like a number/type.
      if (token.kind == SyntaxKind.identifier && _builtinTypes.contains(tokenText)) {
        tokenKindStyle = _genericStyles[SyntaxKind.number]!;
      }

      // Also highlight the token "type" as a keyword-ish indicator if it appears.
      if (token.kind == SyntaxKind.identifier && tokenText == 'type') {
        tokenKindStyle = _genericStyles[SyntaxKind.keyword]!;
      }

      // Ensure the final style explicitly sets color (merge with default)
      final effectiveStyle = _baseTextStyle.merge(tokenKindStyle);

      spans.add(TextSpan(text: tokenText.replaceAll('\n', ''), style: effectiveStyle));

      lastOffset = clippedEnd;
    }

    // Add remaining text at the end of the line, if any (with explicit default style)
    if (lastOffset < lineEnd) {
      final trailing = text.substring(lastOffset, lineEnd);
      spans.add(TextSpan(text: trailing, style: _baseTextStyle));
    }

    // IMPORTANT: do NOT supply a `style:` on the parent TextSpan.
    // Parent style would be inherited by children that lack style and may cause
    // unintended uniform coloring. Each child has an explicit style above.
    return TextSpan(children: spans);
  }
}
