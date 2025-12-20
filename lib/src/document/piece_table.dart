class PieceTable {
  PieceTable(String text) : _original = text {
    if (text.isNotEmpty) {
      _pieces.add(Piece(BufferType.original, 0, text.length));
    }
  }

  /// Read-only access to the current sequence of pieces.
  List<Piece> get pieces => List.unmodifiable(_pieces);

  /// Read-only access to the original buffer string.
  String get original => _original;

  /// Read-only access to the added buffer string.
  String get addBuffer => _addBuffer.toString();

  /// Read text from a piece.
  String readPiece(Piece p) {
    return p.buffer == BufferType.original
        ? _original.substring(p.start, p.start + p.length)
        : _addBuffer.toString().substring(p.start, p.start + p.length);
  }

  final String _original;
  final StringBuffer _addBuffer = StringBuffer();

  /// The sequence of pieces that make up the current document.
  final List<Piece> _pieces = [];

  int get length => _pieces.fold(0, (sum, piece) => sum + piece.length);

  void insert(int offset, String text) {
    if (offset < 0 || offset > length) {
      throw RangeError('Insert offset out of range');
    }
    if (text.isEmpty) return;

    // Fast path: empty document -> just append to add buffer and create one piece.
    if (_pieces.isEmpty) {
      final addStart = _addBuffer.length;
      _addBuffer.write(text);
      _pieces.add(Piece(BufferType.add, addStart, text.length));
      return;
    }

    final addStart = _addBuffer.length;
    _addBuffer.write(text);

    final (pieceIndex, innerOffset) = _findPiece(offset);
    final target = _pieces[pieceIndex];

    // Split piece if inserting in the middle of an existing piece
    final List<Piece> newPieces = [];

    // Left part of split (before insertion point)
    if (innerOffset > 0) {
      newPieces.add(Piece(target.buffer, target.start, innerOffset));
    }

    // Inserted text piece (appended to add buffer)
    newPieces.add(Piece(BufferType.add, addStart, text.length));

    // Right part of split (after insertion point)
    final rightLength = target.length - innerOffset;
    if (rightLength > 0) {
      newPieces.add(Piece(target.buffer, target.start + innerOffset, rightLength));
    }

    // Replace target piece with new pieces
    _pieces
      ..removeAt(pieceIndex)
      ..insertAll(pieceIndex, newPieces);

    if (pieceIndex > 0 && _pieces.isNotEmpty) {
      // Attempt to merge back-to-back pieces.
      _coalesce(pieceIndex - 1);
    }
  }

  void delete({required int offset, required int count}) {
    if (count == 0) {
      return;
    }

    if (offset < 0 || offset + count > length) {
      throw RangeError('Delete range out of bounds');
    }

    int remaining = count;
    int currentOffset = offset;

    while (remaining > 0) {
      final (pieceIndex, innerOffset) = _findPiece(currentOffset);
      final piece = _pieces[pieceIndex];

      final available = piece.length - innerOffset;
      final toDelete = (remaining < available) ? remaining : available;

      final List<Piece> replacement = [];

      // Left piece if deletion is in the middle or end
      if (innerOffset > 0) {
        replacement.add(Piece(piece.buffer, piece.start, innerOffset));
      }

      // Right piece after the deleted segment
      final rightLen = piece.length - (innerOffset + toDelete);
      if (rightLen > 0) {
        replacement.add(Piece(piece.buffer, piece.start + innerOffset + toDelete, rightLen));
      }

      _pieces
        ..removeAt(pieceIndex)
        ..insertAll(pieceIndex, replacement);

      if (pieceIndex > 0 && _pieces.isNotEmpty) {
        // Attempt to merge back-to-back pieces.
        _coalesce(pieceIndex - 1);
      }

      remaining -= toDelete;
      // After deletion, don't advance currentOffset because the deletion
      // removed exactly the range at that position.
    }
  }

  String getText() {
    final sb = StringBuffer();
    for (final p in _pieces) {
      sb.write(_readPiece(p));
    }
    return sb.toString();
  }

  String _readPiece(Piece p) {
    if (p.buffer == BufferType.original) {
      return _original.substring(p.start, p.start + p.length);
    } else {
      return _addBuffer.toString().substring(p.start, p.start + p.length);
    }
  }

  /// Finds the index in the piece list and offset within the piece
  /// for a given document offset.
  /// Returns (pieceIndex, pieceInnerOffset)
  (int pieceIndex, int innerOffset) _findPiece(int offset) {
    // Handle empty doc (shouldn't usually be called in that case if insert handles it,
    // but make this robust anyway).
    if (_pieces.isEmpty) {
      return (0, 0);
    }

    int pos = 0;
    for (int i = 0; i < _pieces.length; i++) {
      final p = _pieces[i];
      final pieceEnd = pos + p.length;
      // If offset is within this piece (including exact end only if it's the final document position)
      if (offset < pieceEnd || (offset == pieceEnd && i == _pieces.length - 1)) {
        return (i, offset - pos);
      }
      pos = pieceEnd;
    }

    // If offset == length (append at end), return last piece and inner offset == last.length
    final lastIndex = _pieces.length - 1;
    return (lastIndex, _pieces[lastIndex].length);
  }

  /// Merges adjacent pieces starting from [startIndex] when they are contiguous
  /// within the same underlying buffer.
  ///
  /// Example merge condition:
  ///   p1.buffer == p2.buffer &&
  ///   p2.start == p1.start + p1.length
  void _coalesce(int startIndex) {
    if (_pieces.length < 2) return;
    if (startIndex < 0) startIndex = 0;
    if (startIndex >= _pieces.length - 1) return;

    int i = startIndex;

    while (i < _pieces.length - 1) {
      final current = _pieces[i];
      final next = _pieces[i + 1];

      // Check if these two pieces can be merged.
      final sameBuffer = current.buffer == next.buffer;
      final isContiguous = next.start == current.start + current.length;

      if (!sameBuffer || !isContiguous) {
        // Cannot merge; move forward
        i++;
        continue;
      }

      // Merge: expand current piece to include next
      final merged = Piece(current.buffer, current.start, current.length + next.length);

      // Replace current with merged, remove next
      _pieces[i] = merged;
      _pieces.removeAt(i + 1);

      // Do not advance i — the new `merged` piece may merge with the next one too
    }
  }
}

class Piece {
  Piece(this.buffer, this.start, this.length);

  final BufferType buffer;
  final int start;
  final int length;

  @override
  String toString() => 'Piece($buffer, $start, $length)';
}

enum BufferType { original, add }
