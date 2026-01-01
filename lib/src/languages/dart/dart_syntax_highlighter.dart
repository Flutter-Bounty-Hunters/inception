import 'package:flutter/widgets.dart';
import 'package:inception/src/document/code_document.dart';
import 'package:inception/src/document/lexing.dart';
import 'package:inception/src/document/syntax_highlighter.dart';
import 'package:inception/src/languages/dart/dart_theme.dart';

class DartSyntaxHighlighter implements CodeDocumentSyntaxHighlighter {
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
    if (doc == null) return;

    final startLine = doc.offsetToCodePosition(start).line;
    final endLine = doc.offsetToCodePosition(end).line;

    final oldLineCount = _lineSpans.length;
    final newLineCount = doc.lineCount;
    final lineDelta = newLineCount - oldLineCount;

    // Rebuild affected lines
    final rebuiltSpans = <TextSpan>[];
    for (int lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
      if (lineIndex >= 0 && lineIndex < newLineCount) {
        rebuiltSpans.add(_buildLineSpan(doc, lineIndex));
      }
    }

    final removeCount = endLine - startLine + 1;
    _lineSpans.replaceRange(
      startLine,
      startLine + removeCount.clamp(0, _lineSpans.length - startLine),
      rebuiltSpans,
    );

    // Adjust for line insertions/deletions
    if (lineDelta > 0) {
      for (int i = 0; i < lineDelta; i++) {
        _lineSpans.insert(endLine + 1 + i, _buildLineSpan(doc, endLine + 1 + i));
      }
    } else if (lineDelta < 0) {
      _lineSpans.removeRange(newLineCount, oldLineCount);
    }
  }

  void _rebuildAllLines() {
    final doc = _attachedDocument;
    if (doc == null) return;

    _lineSpans.clear();
    for (int i = 0; i < doc.lineCount; i++) {
      _lineSpans.add(_buildLineSpan(doc, i));
    }
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
    final lineEnd = (lineIndex + 1 < doc.lineCount) ? doc.getLineStart(lineIndex + 1) : text.length;

    final lineTokens = doc.tokensInRange(lineStart, lineEnd);

    final List<TextSpan> spans = [];
    int lastOffset = lineStart;

    for (final token in lineTokens) {
      final clippedStart = token.start.clamp(lineStart, lineEnd);
      final clippedEnd = token.end.clamp(lineStart, lineEnd);

      if (clippedStart >= clippedEnd) continue;

      // Add unstyled gap text
      if (clippedStart > lastOffset) {
        spans.add(TextSpan(
          text: text.substring(lastOffset, clippedStart),
          style: _baseTextStyle,
        ));
      }

      final tokenText = text.substring(clippedStart, clippedEnd);

      TextStyle tokenKindStyle = _genericStyles[token.kind] ?? _theme.baseTextStyle;

      // Highlight built-in types
      if (token.kind == SyntaxKind.identifier && _builtinTypes.contains(tokenText)) {
        tokenKindStyle = _genericStyles[SyntaxKind.number]!; // or another existing kind
      }

      // Highlight keywords
      if (token.kind == SyntaxKind.identifier && _builtinKeywords.contains(tokenText)) {
        tokenKindStyle = _genericStyles[SyntaxKind.keyword]!;
      }

      // Merge with default style
      final effectiveStyle = _baseTextStyle.merge(tokenKindStyle);

      spans.add(TextSpan(
        text: tokenText.replaceAll('\n', ''),
        style: effectiveStyle,
      ));

      lastOffset = clippedEnd;
    }

    if (lastOffset < lineEnd) {
      spans.add(TextSpan(
        text: text.substring(lastOffset, lineEnd),
        style: _baseTextStyle,
      ));
    }

    return TextSpan(children: spans);
  }
}
