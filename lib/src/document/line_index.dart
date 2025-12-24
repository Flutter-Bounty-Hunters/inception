class LineIndex {
  LineIndex(String text) {
    _computeLineStarts(text);
  }

  // High-level public API -----------------------------------------------------

  int get lineCount => _lineStarts.length;

  /// Returns (line, column) for a given offset.
  (int line, int column) offsetToLineColumn(int offset) {
    final line = _findLineForOffset(offset);
    final lineStart = _lineStarts[line];
    return (line, offset - lineStart);
  }

  /// Returns the absolute offset for a given (line, column).
  int lineColumnToOffset(int line, int column) {
    if (line < 0 || line >= _lineStarts.length) {
      throw RangeError('Invalid line: $line');
    }
    return _lineStarts[line] + column;
  }

  /// Rebuilds the line index from the given full document text.
  /// Call this after applying edits.
  void rebuild(String text) {
    _computeLineStarts(text);
  }

  // Lower-level public API ----------------------------------------------------

  int getLineStart(int line) => _lineStarts[line];

  // Private -------------------------------------------------------------------

  late List<int> _lineStarts;

  void _computeLineStarts(String text) {
    final starts = <int>[0];

    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);

      if (codeUnit == 0x0A) {
        // '\n'
        starts.add(i + 1);
      }
      // Optional: handle CRLF "\r\n" if needed
    }

    _lineStarts = starts;
  }

  int _findLineForOffset(int offset) {
    // Binary search
    int low = 0;
    int high = _lineStarts.length - 1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final start = _lineStarts[mid];

      if (start == offset) {
        return mid;
      }
      if (start < offset) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return high; // greatest lineStart <= offset
  }
}
