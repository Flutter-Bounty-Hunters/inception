import 'package:flutter/painting.dart';
import 'package:inception/src/document/code_document.dart';
import 'package:inception/src/document/lexing.dart';

class DeprecatedLuauSyntaxHighlighter implements LexerTokenListener {
  CodeDocument? _attachedDocument;

  int get lineCount => _lineSpans.length;

  TextSpan? getStyledLineAt(int lineIndex) {
    if (lineIndex < 0 || lineIndex >= _lineSpans.length) {
      return null;
    }

    return _lineSpans[lineIndex];
  }

  /// One top-level TextSpan per line, each containing styled sub-spans
  final List<TextSpan> _lineSpans = [];

  void attachToDocument(CodeDocument document) {
    detachFromDocument();

    _attachedDocument = document;
    _attachedDocument!.addTokenChangeListener(this);

    _rebuildAllLines();
  }

  void detachFromDocument() {
    _attachedDocument?.removeTokenChangeListener(this);
    _attachedDocument = null;

    _lineSpans.clear();
  }

  @override
  void onTokensChanged(int start, int end, List<LexerToken> newTokens) {
    final doc = _attachedDocument;
    if (doc == null) return;

    final startLine = doc.offsetToLineColumn(start).$1;
    final endLine = doc.offsetToLineColumn(end).$1;

    // Determine how many lines changed
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

    // Replace old spans for affected lines
    final removeCount = endLine - startLine + 1;
    _lineSpans.replaceRange(startLine, startLine + removeCount.clamp(0, _lineSpans.length - startLine), rebuiltSpans);

    // Adjust for line insertions
    if (lineDelta > 0) {
      // Insert placeholders if new lines were added
      for (int i = 0; i < lineDelta; i++) {
        _lineSpans.insert(endLine + 1 + i, _buildLineSpan(doc, endLine + 1 + i));
      }
    } else if (lineDelta < 0) {
      // Remove extra spans if lines were deleted
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

  // Default text style applied to any plain text or merged with token styles.
  TextStyle get _defaultStyle => const TextStyle(color: Color(0xFFD4D4D4), fontSize: 14.0);

  Map<SyntaxKind, TextStyle> get _tokenStyles => _obsidianStyleMap;

  /// Maps token kinds to text styles
  final Map<SyntaxKind, TextStyle> _genericStyles = {
    SyntaxKind.keyword: const TextStyle(color: Color(0xFF569CD6), fontWeight: FontWeight.bold),
    SyntaxKind.identifier: const TextStyle(color: Color(0xFFD4D4D4)),
    SyntaxKind.string: const TextStyle(color: Color(0xFFCE9178)),
    SyntaxKind.number: const TextStyle(color: Color(0xFFB5CEA8)),
    SyntaxKind.comment: const TextStyle(color: Color(0xFF6A9955), fontStyle: FontStyle.italic),
    SyntaxKind.operatorToken: const TextStyle(color: Color(0xFFD4D4D4)),
    SyntaxKind.punctuation: const TextStyle(color: Color(0xFFD4D4D4)),
    SyntaxKind.whitespace: const TextStyle(color: Color(0xFFD4D4D4)),
    SyntaxKind.unknown: const TextStyle(color: Color(0xFFFF0000)),
  };

  final Map<SyntaxKind, TextStyle> _obsidianStyleMap = {
    SyntaxKind.keyword: const TextStyle(color: Color(0xFF569CD6), fontWeight: FontWeight.bold), // bluish keywords
    SyntaxKind.identifier: const TextStyle(color: Color(0xFFD4D4D4)), // default code text
    SyntaxKind.string: const TextStyle(color: Color(0xFFCE9178)), // warm string color
    SyntaxKind.number: const TextStyle(color: Color(0xFFB5CEA8)), // green-ish numbers
    SyntaxKind.comment: const TextStyle(color: Color(0xFF6A9955), fontStyle: FontStyle.italic), // muted green comments
    SyntaxKind.operatorToken: const TextStyle(color: Color(0xFFD4D4D4)), // same as normal text
    // Assignment needs to be inferred during highlighting, not during tokenization, to keep tokenization
    // more stable.
    // SyntaxKind.assignment: TextStyle(color: Color(0xFF9CDCFE), fontWeight: FontWeight.bold),
    SyntaxKind.punctuation: const TextStyle(color: Color(0xFFD4D4D4)), // punctuation neutral
    // Generic braces need to be inferred during highlighting, not during tokenization, to keep tokenization
    // more stable.
    // SyntaxKind.genericBrace: TextStyle(color: Color(0xFF4FC1FF)), // light blue braces
    SyntaxKind.unknown: const TextStyle(color: Color(0xFFFF0000)), // bright red for unknown/error
  };

  // Builtin Luau type names we want to color specially even if tokenizer marks as identifier.
  static const Set<String> _builtinTypes = {
    'number',
    'string',
    'boolean',
    'nil',
    'table',
    'Vector3',
    'Instance', // common Roblox types (optional)
    // add any other builtins you want highlighted differently
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
      // Clip the token to the current line
      final clippedStart = token.start.clamp(lineStart, lineEnd);
      final clippedEnd = token.end.clamp(lineStart, lineEnd);

      // Skip empty spans
      if (clippedStart >= clippedEnd) continue;

      // Add any unstyled text between last token and current token,
      // but give it an explicit default style so rendering can't "inherit".
      if (clippedStart > lastOffset) {
        final gapText = text.substring(lastOffset, clippedStart);
        spans.add(TextSpan(text: gapText, style: _defaultStyle));
      }

      // Token text
      final tokenText = text.substring(clippedStart, clippedEnd);

      // Decide token style: base tokenKind style, possibly overridden by token text.
      TextStyle tokenKindStyle = _tokenStyles[token.kind] ?? _genericStyles[token.kind] ?? const TextStyle();

      // If tokenizer labeled this as an identifier but its literal text is a builtin type
      // color it like a number/type.
      if (token.kind == SyntaxKind.identifier && _builtinTypes.contains(tokenText)) {
        tokenKindStyle = _tokenStyles[SyntaxKind.number] ?? _genericStyles[SyntaxKind.number]!;
      }

      // Also highlight the token "type" as a keyword-ish indicator if it appears.
      if (token.kind == SyntaxKind.identifier && tokenText == 'type') {
        tokenKindStyle = _tokenStyles[SyntaxKind.keyword] ?? _genericStyles[SyntaxKind.keyword]!;
      }

      // Ensure the final style explicitly sets color (merge with default)
      final effectiveStyle = _defaultStyle.merge(tokenKindStyle);

      spans.add(TextSpan(text: tokenText.replaceAll('\n', ''), style: effectiveStyle));

      lastOffset = clippedEnd;
    }

    // Add remaining text at the end of the line, if any (with explicit default style)
    if (lastOffset < lineEnd) {
      final trailing = text.substring(lastOffset, lineEnd);
      spans.add(TextSpan(text: trailing, style: _defaultStyle));
    }

    // IMPORTANT: do NOT supply a `style:` on the parent TextSpan.
    // Parent style would be inherited by children that lack style and may cause
    // unintended uniform coloring. Each child has an explicit style above.
    return TextSpan(children: spans);
  }
}
