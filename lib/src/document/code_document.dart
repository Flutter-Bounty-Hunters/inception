import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:inception/src/document/lexing.dart';
import 'package:inception/src/document/piece_table.dart';
import 'package:inception/src/document/selection.dart';

class CodeDocument {
  @visibleForTesting
  static const batchInterval = Duration(milliseconds: 750);

  CodeDocument(this.lexer, String text)
      : _pieceTable = PieceTable(text),
        _lineStarts = [0] {
    _rebuildLineIndex();
    _recomputeTokens();
  }

  final PieceTable _pieceTable;
  final List<int> _lineStarts;

  String get text => _pieceTable.getText();
  int get length => _pieceTable.length;

  /// Extracts and returns a list of substrings for every line in the document.
  List<String> computeLines() {
    final lines = <String>[];
    for (int i = 0; i < lineCount; i += 1) {
      lines.add(getLine(i)!);
    }
    return lines;
  }

  String? getLine(int lineIndex) {
    if (lineIndex < 0 || lineIndex >= lineCount) {
      return null;
    }

    return text.substring(getLineStart(lineIndex), getLineEnd(lineIndex));
  }

  /// Returns `true` if the given [position] points to a location in this document
  /// that exists, or `false` otherwise.
  ///
  /// A [position] can be invalid in one of four ways:
  ///  1. Points to a negative line index.
  ///  2. Points to a line beyond the end of this document.
  ///  3. Points to a negative character offset.
  ///  4. Points to a character offset beyond the end of the line.
  bool containsPosition(CodePosition position) {
    return position.line >= 0 &&
        position.line < lineCount &&
        position.characterOffset >= 0 &&
        position.characterOffset <= getLine(position.line)!.length;
  }

  // ----- START TOKENS --------
  Lexer lexer;
  List<LexerToken> _tokens = const [];
  List<LexerToken> get tokens => _tokens;
  int _tokenizedDocumentLength = -1;
  final _tokenChangeListeners = <LexerTokenListener>{};

  bool highlightCurrentLine = true;
  bool highlightMatchingBracket = true;
  bool highlightIdentifierOccurrences = true;

  TextRange? _lastEditRange;

  void addTokenChangeListener(LexerTokenListener listener) {
    _tokenChangeListeners.add(listener);
  }

  void removeTokenChangeListener(LexerTokenListener listener) {
    _tokenChangeListeners.remove(listener);
  }

  void _onTokensChanged(int start, int end, List<LexerToken> newTokens) {
    for (final listener in _tokenChangeListeners) {
      listener.onTokensChanged(start, end, newTokens);
    }
  }

  LexerToken? findTokenAt(CodePosition position) {
    final textOffset = lineColumnToOffset(position.line, position.characterOffset);
    final tokens = _tokens.where((t) => textOffset == t.start || (t.start < textOffset && textOffset < t.end));

    if (tokens.length > 1) {
      throw Exception(
        "Something went wrong when finding the token at $position - we expect to find either 0 or 1, but we found ${tokens.length}",
      );
    }
    if (tokens.isEmpty) {
      return null;
    }

    return tokens.first;
  }

  LexerToken? findTokenToTheLeftOnSameLine(
    CodePosition from, {
    TokenFilter? filter,
  }) {
    if (!containsPosition(from)) {
      return null;
    }

    // FIXME: This logic probably needs to use a character iterator, rather than
    // an index integer. Look into it and make the switch if necessary.
    var tokenAtStartingPoint = findTokenAt(from);
    var textIndex = lineColumnToOffset(from.line, from.characterOffset) - 1;
    while (textIndex >= 0 && offsetToCodePosition(textIndex).line == from.line) {
      final nextPosition = offsetToCodePosition(textIndex);
      final nextToken = findTokenAt(nextPosition);
      if (nextToken != tokenAtStartingPoint &&
          nextToken != null &&
          (filter == null || filter(nextToken, nextPosition))) {
        // This is the nearest token to the left, that we're looking for.
        return nextToken;
      }

      // Move one character to the left.
      textIndex -= 1;
    }

    return null;
  }

  LexerToken? findTokenToTheRightOnSameLine(
    CodePosition from, {
    TokenFilter? filter,
  }) {
    if (!containsPosition(from)) {
      return null;
    }

    // FIXME: This logic probably needs to use a character iterator, rather than
    // an index integer. Look into it and make the switch if necessary.
    var tokenAtStartingPoint = findTokenAt(from);
    var textIndex = lineColumnToOffset(from.line, from.characterOffset) + 1;
    while (textIndex < length && offsetToCodePosition(textIndex).line == from.line) {
      final nextPosition = offsetToCodePosition(textIndex);
      final nextToken = findTokenAt(nextPosition);
      if (nextToken != tokenAtStartingPoint &&
          nextToken != null &&
          (filter == null || filter(nextToken, nextPosition))) {
        // This is the nearest token to the left, that we're looking for.
        return nextToken;
      }

      // Move one character to the right.
      textIndex += 1;
    }

    return null;
  }

  /// Returns all tokens that overlap the current selection or cursor position.
  /// If there is no selection, this returns an empty list.
  List<LexerToken> tokensInSelection() {
    if (selectionStart < 0 || selectionEnd < 0) {
      return const [];
    }

    final selStart = selectionStart;
    final selEnd = selectionEnd;

    if (selStart == selEnd) {
      // Cursor case: include tokens containing the cursor position
      return _tokens.where((t) => selStart >= t.start && selStart < t.end).toList();
    }

    // Range case: include any token that overlaps the range [selStart, selEnd)
    return _tokens.where((t) {
      return !(t.end <= selStart || t.start >= selEnd);
    }).toList();
  }

  List<LexerToken> tokensInRange(int start, int end) {
    if (start == end) {
      // Cursor case: include tokens containing the cursor position
      return _tokens.where((t) => start >= t.start && end < t.end).toList();
    }

    // Range case: include any token that overlaps the range [selStart, selEnd)
    return _tokens.where((t) {
      return !(t.end <= start || t.start >= end);
    }).toList();
  }

  void _recomputeTokens() {
    final provider = lexer;

    if (text.isEmpty) {
      _tokens = const [];
      _onTokensChanged(0, 0, const []);
      _lastEditRange = null;
      _tokenizedDocumentLength = length;
      return;
    }

    // 🚨 Undo/redo must fully recompute
    if (_isUndoRedo) {
      _tokens = provider.tokenize(text);
      _onTokensChanged(0, text.length, _tokens);
      _lastEditRange = null;
      _tokenizedDocumentLength = length;
      return;
    }

    final editRange = _lastEditRange;

    // No edit info → full tokenize
    if (editRange == null) {
      _tokens = provider.tokenize(text);
      _onTokensChanged(0, text.length, _tokens);
      _tokenizedDocumentLength = length;
      return;
    }

    final isMultiLineEdit =
        text.substring(editRange.start, editRange.end.clamp(editRange.start, text.length)).contains('\n');
    if (isMultiLineEdit) {
      // A multi-line change requires full re-tokenizing. We can avoid that
      // by implementing incremental re-mapping, but we haven't done that yet.

      _tokens = provider.tokenize(text);

      // IMPORTANT: full document invalidation
      _lastEditRange = null;
      _tokenizedDocumentLength = length;

      // Notify AFTER state is fully consistent
      _onTokensChanged(0, length, _tokens);

      return;
    }

    final didDocumentChangeLength = length != _tokenizedDocumentLength;
    if (didDocumentChangeLength) {
      // Due to lack of token stability during undo/redo, whenever the document changes length
      // we have to retokenize everything. This essentially makes our incremental
      // tokenization useless. I put this here to get tests passing again, but we need
      // to re-work something in the document structure to avoid constant re-tokenizing.
      _tokens = provider.tokenize(text);
      _onTokensChanged(0, text.length, _tokens);
      _lastEditRange = null;
      _tokenizedDocumentLength = length;

      return;
    }

    // Partial tokenization path
    final partial = provider.tokenizePartial(fullText: text, range: editRange);

    // Provider does not support partial → fallback
    if (partial == null) {
      _tokens = provider.tokenize(text);
      _onTokensChanged(0, text.length, _tokens);
      _lastEditRange = null;
      _tokenizedDocumentLength = length;
      return;
    }

    // Clamp edit range to valid text bounds
    final start = editRange.start.clamp(0, text.length);
    final end = editRange.end.clamp(0, text.length);

    final before = <LexerToken>[];
    final after = <LexerToken>[];

    // Partition old tokens
    for (final t in _tokens) {
      if (t.end <= start) {
        before.add(t);
      } else if (t.start >= end) {
        after.add(t);
      }
    }

    // Merge = before + partial + after
    final merged = <LexerToken>[...before, ...partial, ...after];

    // ---- Normalize tokens ----
    merged.sort((a, b) {
      final c = a.start.compareTo(b.start);
      return c != 0 ? c : a.end.compareTo(b.end);
    });

    final normalized = <LexerToken>[];
    for (final t in merged) {
      if (normalized.isEmpty) {
        normalized.add(t);
        continue;
      }

      final last = normalized.last;

      // Exact duplicate → skip
      if (last.start == t.start && last.end == t.end && last.kind == t.kind) {
        continue;
      }

      // Non-overlapping → append
      if (t.start >= last.end) {
        normalized.add(t);
        continue;
      }

      // Overlap case: keep left of last if applicable
      normalized.removeLast();
      if (last.start < t.start) {
        normalized.add(LexerToken(last.start, t.start, last.kind));
      }
      normalized.add(t);
    }

    // Debug sanity checks
    assert(() {
      for (final t in normalized) {
        if (t.start < 0 || t.end > text.length || t.start >= t.end) {
          throw StateError("Invalid token span: $t (of available text length ${text.length})");
        }
      }
      for (int i = 1; i < normalized.length; i++) {
        if (normalized[i - 1].end > normalized[i].start) {
          throw StateError("Overlapping tokens after normalize: ${normalized[i - 1]} and ${normalized[i]}");
        }
      }
      return true;
    }());

    _tokens = List.unmodifiable(normalized);

    // Notify listeners about the updated region
    _onTokensChanged(start, end, _tokens.where((t) => t.end > start && t.start < end).toList());

    // Consume edit range
    _lastEditRange = null;

    _tokenizedDocumentLength = length;
  }

  // ----- END TOKENS --------

  void insert(int offset, String text) {
    _pieceTable.insert(offset, text);
    _updateLineIndexIncremental(offset, 0, text);
    _recordEdit(_InsertAction(offset, text));

    // Record the affected range
    _lastEditRange = TextRange(start: offset, end: offset + text.length);

    _recomputeTokens();
    _startBatchTimer();
  }

  void delete({required int offset, required int count}) {
    final deletedText = text.substring(offset, offset + count);
    _pieceTable.delete(offset: offset, count: count);
    _updateLineIndexIncremental(offset, count, '');
    _recordEdit(_DeleteAction(offset, deletedText));

    // Record the affected range
    _lastEditRange = TextRange(start: offset, end: offset);

    _recomputeTokens();
    _startBatchTimer();
  }

  /// The start of the selection. If equal to [selectionEnd], the selection is collapsed (cursor).
  int selectionStart = -1;

  /// The end of the selection. If equal to [selectionStart], the selection is collapsed (cursor).
  int selectionEnd = -1;

  /// Returns true if there is an active selection (start != end)
  bool get hasSelection => selectionStart >= 0 && selectionEnd >= 0 && selectionStart != selectionEnd;

  /// Returns the current cursor position (same as [selectionEnd])
  int get cursor => selectionEnd;

  /// Sets the selection range. Automatically normalizes so that start <= end.
  void setSelection(int start, int end) {
    start = start.clamp(0, length);
    end = end.clamp(0, length);
    selectionStart = start;
    selectionEnd = end;
  }

  /// Collapse the selection to one end (default: end)
  void collapseSelection({bool toStart = false}) {
    if (toStart) {
      selectionEnd = selectionStart;
    } else {
      selectionStart = selectionEnd;
    }
  }

  /// Extend the selection to a new cursor position, keeping the anchor fixed
  void extendSelection(int newEnd) {
    newEnd = newEnd.clamp(0, length);
    selectionEnd = newEnd;
  }

  /// Inserts text at a collapsed selection.
  void insertAtCursor(String text) {
    replaceSelection(text);
  }

  /// Deletes a range defined by selection.
  void deleteSelection() {
    replaceSelection('');
  }

  /// Replaces the text in the range [start, end) with [replacement].
  /// Fully integrated with undo/redo, line indexing, tokenization, and batching.
  void replaceRange(int start, int end, String replacement) {
    assert(start >= 0 && end >= start && end <= length);

    // Normalize
    start = start.clamp(0, length);
    end = end.clamp(start, length);

    final deleteCount = end - start;

    // ---- DELETE PHASE ----
    if (deleteCount > 0) {
      final deletedText = text.substring(start, end);
      _pieceTable.delete(offset: start, count: deleteCount);
      _updateLineIndexIncremental(start, deleteCount, '');
      _recordEdit(_DeleteAction(start, deletedText));
    }

    // ---- INSERT PHASE ----
    if (replacement.isNotEmpty) {
      _pieceTable.insert(start, replacement);
      _updateLineIndexIncremental(start, 0, replacement);
      _recordEdit(_InsertAction(start, replacement));
    }

    // Record the affected range for incremental tokenization
    _lastEditRange = TextRange(start: start, end: start + replacement.length);

    // Recompute tokens (incremental if provider supports it)
    _recomputeTokens();

    _startBatchTimer();
  }

  void replaceSelection(String replacement) {
    if (selectionStart < 0 || selectionEnd < 0) {
      return;
    }

    final start = selectionStart;
    final end = selectionEnd;

    replaceRange(start, end, replacement);

    // Move cursor after inserted text
    final newOffset = start + replacement.length;
    selectionStart = newOffset;
    selectionEnd = newOffset;
  }

  /// Returns the absolute offset range of the current line.
  /// If there is no selection, returns null.
  ({int start, int end})? get currentLineRange {
    if (!highlightCurrentLine || selectionStart < 0) {
      return null;
    }

    final startLine = offsetToCodePosition(selectionStart).line;
    final startOffset = getLineStart(startLine);
    final endOffset = startLine + 1 < lineCount ? getLineStart(startLine + 1) : length;

    return (start: startOffset, end: endOffset);
  }

  CodePosition offsetToCodePosition(int offset) {
    final lineIndex = _findLineIndex(offset);
    return CodePosition(lineIndex, offset - _lineStarts[lineIndex]);
  }

  int lineColumnToOffset(int line, int column) => _lineStarts[line] + column;

  int get lineCount => _lineStarts.length;

  int getLineStart(int line) => _lineStarts[line];

  int getLineEnd(int line) => line < lineCount - 1 //
      ? getLineStart(line + 1) - 1 // -1 to remove the trailing newline at the end of the line.
      : length;

  // ----- Undo/redo ------
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    _commitPendingBatch();
    if (!canUndo) return;

    _isUndoRedo = true;
    try {
      final action = _undoStack.removeLast();
      action.undo(this);
      _redoStack.add(action);
    } finally {
      _isUndoRedo = false;
    }
  }

  void redo() {
    _commitPendingBatch();
    if (!canRedo) return;

    _isUndoRedo = true;
    try {
      final action = _redoStack.removeLast();
      action.redo(this);
      _undoStack.add(action);
    } finally {
      _isUndoRedo = false;
    }
  }

  void _commitPendingBatch() {
    if (_pendingBatch != null) {
      _undoStack.add(_pendingBatch!);
      _redoStack.clear();
      _pendingBatch = null;
      _batchTimer?.cancel();
    }
  }

  final List<_EditAction> _undoStack = [];
  final List<_EditAction> _redoStack = [];
  bool _suppressingHistory = false;
  bool _isUndoRedo = false;

  _EditAction? _pendingBatch;
  DateTime? _lastEditTime;
  Timer? _batchTimer;

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer(batchInterval, () {
      _commitPendingBatch();
    });
  }

  void _recordEdit(_EditAction action) {
    if (_suppressingHistory) return;

    final now = DateTime.now();
    final shouldBatch = _pendingBatch != null &&
        action.canBatchWith(_pendingBatch!) &&
        _lastEditTime != null &&
        now.difference(_lastEditTime!) < batchInterval;

    if (shouldBatch) {
      // Merge into existing batch
      _pendingBatch = _pendingBatch!.appendAtEnd(action);
    } else {
      // Commit previous batch if exists
      if (_pendingBatch != null) {
        _undoStack.add(_pendingBatch!);
        _redoStack.clear();
      }
      _pendingBatch = action;
    }

    _lastEditTime = now;
  }

  void _suppressHistory(void Function() callback) {
    final previous = _suppressingHistory;
    _suppressingHistory = true;
    try {
      callback();
    } finally {
      _suppressingHistory = previous;
    }
  }
  // ----- END undo/redo ----

  void _rebuildLineIndex() {
    _lineStarts.clear();
    _lineStarts.add(0);

    int offset = 0;
    for (final piece in _pieceTable.pieces) {
      final text = _pieceTable.readPiece(piece);
      for (int i = 0; i < text.length; i++) {
        if (text.codeUnitAt(i) == 0x0A) _lineStarts.add(offset + i + 1);
      }
      offset += text.length;
    }
  }

  void _updateLineIndexIncremental(int start, int deletedLength, String insertedText) {
    final oldEnd = start + deletedLength;
    final delta = insertedText.length - deletedLength;

    final startLine = _findLineIndex(start);
    final endLine = _findLineIndex(oldEnd);

    _lineStarts.removeRange(startLine + 1, endLine + 1);

    int insertPos = startLine;
    for (int i = 0; i < insertedText.length; i++) {
      if (insertedText.codeUnitAt(i) == 0x0A) {
        insertPos++;
        _lineStarts.insert(insertPos, start + i + 1);
      }
    }

    if (delta != 0) {
      for (int i = insertPos + 1; i < _lineStarts.length; i++) {
        _lineStarts[i] += delta;
      }
    }
  }

  int _findLineIndex(int offset) {
    int low = 0;
    int high = _lineStarts.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midVal = _lineStarts[mid];
      if (midVal == offset) return mid;
      if (midVal < offset) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return low - 1;
  }

  int? findMatchingBracket(int offset) {
    if (!highlightMatchingBracket) return null;
    if (offset < 0 || offset >= length) return null;

    final ch = text.codeUnitAt(offset);
    final bracket = String.fromCharCode(ch);
    final match = _bracketPairs[bracket];
    if (match == null) return null;

    final isOpening = bracket == '(' || bracket == '{' || bracket == '[';
    final targetCode = match.codeUnitAt(0);

    int depth = 1;

    if (isOpening) {
      // Forward search
      for (int i = offset + 1; i < length; i++) {
        final c = text.codeUnitAt(i);
        if (c == ch) depth++;
        if (c == targetCode) {
          depth--;
          if (depth == 0) return i;
        }
      }
    } else {
      // Backward search
      for (int i = offset - 1; i >= 0; i--) {
        final c = text.codeUnitAt(i);
        if (c == ch) depth++;
        if (c == targetCode) {
          depth--;
          if (depth == 0) return i;
        }
      }
    }

    return null;
  }

  ({int start, int end})? get matchingBracketRange {
    if (!highlightMatchingBracket) {
      return null;
    }
    if (selectionStart < 0) {
      return null;
    }

    final pos = selectionStart;

    // Try cursor left
    int? match = findMatchingBracket(pos);
    if (match != null) {
      return (start: match, end: match + 1);
    }

    // Try cursor just before (if at right side of a bracket)
    if (pos > 0) {
      match = findMatchingBracket(pos - 1);
      if (match != null) {
        return (start: match, end: match + 1);
      }
    }

    return null;
  }

  List<({int start, int end})> get identifierOccurrences {
    final base = identifierRange;
    if (base == null) {
      return const [];
    }

    final name = text.substring(base.start, base.end);
    final List<({int start, int end})> result = [];

    int index = 0;
    while (true) {
      index = text.indexOf(name, index);
      if (index == -1) break;

      // Ensure match is a full identifier
      final prev = index > 0 ? text.codeUnitAt(index - 1) : null;
      final next = index + name.length < length ? text.codeUnitAt(index + name.length) : null;

      if (prev != null && _isIdentifierChar(prev)) {
        index += name.length;
        continue;
      }
      if (next != null && _isIdentifierChar(next)) {
        index += name.length;
        continue;
      }

      result.add((start: index, end: index + name.length));
      index += name.length;
    }

    return result;
  }

  ({int start, int end})? get identifierRange {
    if (!highlightIdentifierOccurrences || selectionStart < 0) {
      return null;
    }

    final pos = selectionStart;
    if (pos < 0 || pos >= length) return null;

    // Must be inside an identifier
    if (!_isIdentifierChar(text.codeUnitAt(pos))) return null;

    // Expand left
    int start = pos;
    while (start > 0 && _isIdentifierChar(text.codeUnitAt(start - 1))) {
      start--;
    }

    // Expand right
    int end = pos;
    while (end < length && _isIdentifierChar(text.codeUnitAt(end))) {
      end++;
    }

    return (start: start, end: end);
  }

  bool _isIdentifierChar(int code) {
    return (code >= 0x41 && code <= 0x5A) || // A-Z
        (code >= 0x61 && code <= 0x7A) || // a-z
        (code >= 0x30 && code <= 0x39) || // 0-9
        code == 0x5F; // _
  }
}

typedef TokenFilter = bool Function(LexerToken token, CodePosition position);

class _InsertAction implements _EditAction {
  _InsertAction(this.offset, this.text);

  final int offset;
  final String text;

  @override
  bool canBatchWith(_EditAction existingBatch) {
    if (existingBatch is! _InsertAction) return false;

    // Must be adjacent and forward-contiguous
    return existingBatch.offset + existingBatch.text.length == offset;
  }

  @override
  _EditAction appendAtEnd(_EditAction actionToAppend) {
    final newInsertion = actionToAppend as _InsertAction;
    return _InsertAction(offset, text + newInsertion.text);
  }

  @override
  void undo(CodeDocument doc) {
    doc._suppressHistory(() => doc.delete(offset: offset, count: text.length));
  }

  @override
  void redo(CodeDocument doc) {
    doc._suppressHistory(() => doc.insert(offset, text));
  }

  @override
  String toString() => '[InsertAction] - at $offset: "$text"';
}

class _DeleteAction implements _EditAction {
  _DeleteAction(this.offset, this.text);

  final int offset;
  final String text;

  @override
  bool canBatchWith(_EditAction existingBatch) {
    if (existingBatch is! _DeleteAction) {
      return false;
    }

    // Only batch with deletions that deleted text immediately preceding
    // this existing delete actions deletion. E.g., "abcd", delete "d", can
    // then batch with delete "bc". But, delete "d" cannot batch with delete "b".
    return offset == existingBatch.offset - text.length;
  }

  @override
  _EditAction appendAtEnd(_EditAction actionToAppend) {
    final newDeletion = actionToAppend as _DeleteAction;
    return _DeleteAction(newDeletion.offset, newDeletion.text + text);
  }

  @override
  void undo(CodeDocument doc) {
    doc._suppressHistory(() => doc.insert(offset, text));
  }

  @override
  void redo(CodeDocument doc) {
    doc._suppressHistory(() => doc.delete(offset: offset, count: text.length));
  }

  @override
  String toString() => '[DeleteAction] - at $offset: "$text"';
}

abstract class _EditAction {
  void undo(CodeDocument doc);
  void redo(CodeDocument doc);

  bool canBatchWith(_EditAction existingBatch) => false;

  _EditAction appendAtEnd(_EditAction actionToAppend) => throw UnsupportedError('Cannot merge actions');
}

abstract class LexerTokenListener {
  /// Called after tokens in the given document range changed.
  ///
  /// [start]: the starting offset of the change (inclusive)
  /// [end]:   the ending offset of the change (exclusive)
  /// [newTokens]: the tokens now covering that range
  void onTokensChanged(int start, int end, List<LexerToken> newTokens);
}

const _bracketPairs = {'(': ')', '{': '}', '[': ']', ')': '(', '}': '{', ']': '['};
