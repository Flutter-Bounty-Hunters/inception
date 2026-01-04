import 'dart:ui';

abstract class CodeCommentSelection {
  /// Characters that are considered non-words, e.g., spaces, `\n`, ":", etc.
  static final RegExp _boundaryRegex = RegExp(r'\W');

  /// Given a [clickOffset] within a [codeCommentLine], this method searches for a sequence
  /// of characters that can be selected as a group, e.g., selecting the entire word around
  /// the given [clickOffset].
  ///
  /// Rules:
  ///  * When [clickOffset] points to the indent space before the comment, selects all of the
  ///    indent space.
  ///  * When [clickOffset] points to a character in the comment syntax, e.g., "//", selects
  ///    the whole line.
  ///  * When [clickOffset] is in the middle of a word, selects the whole word.
  ///  * When [clickOffset] points to a non-word character, e.g., ":", selects just that character.
  ///  * When [clickOffset] points to a space, searches in the given [affinity] direction for
  ///    a word or a non-word-token to select, and if none can be found, searches the
  ///    opposite direction for the same.
  static TextRange findNearestSelectableToken(
    String codeCommentLine,
    int clickOffset,
    TextAffinity affinity,
    List<String> commentLineStartSyntaxes,
  ) {
    if (codeCommentLine.isEmpty) {
      return TextRange.empty;
    }

    // 1. Rule: Clicked inside indentation space
    // Find where the actual content starts
    int firstNonWs = codeCommentLine.indexOf(RegExp(r'\S'));

    // If click is before the first non-whitespace character
    if (firstNonWs == -1 || clickOffset < firstNonWs) {
      // If the line is only whitespace, select the whole line.
      // Otherwise, select from start to the first non-whitespace char.
      return TextRange(start: 0, end: firstNonWs == -1 ? codeCommentLine.length : firstNonWs);
    }

    bool didClickInStartSyntax = false;
    for (final startSyntax in commentLineStartSyntaxes) {
      final startRegExp = RegExp("\\s*($startSyntax)");
      final match = startRegExp.firstMatch(codeCommentLine);
      if (match != null) {
        // This line begins with the given `startSyntax`. Now, check if the click offset
        // is somewhere in that starting syntax.
        if (match.start <= clickOffset && clickOffset <= match.end) {
          didClickInStartSyntax = true;
          break;
        }
      }
    }
    if (didClickInStartSyntax) {
      return TextRange(start: 0, end: codeCommentLine.length);
    }

    // 3. Default: Word boundary selection (\W)
    return _applyWordBoundary(codeCommentLine, clickOffset, affinity) ??
        TextRange(start: clickOffset, end: clickOffset);
  }

  static int findCaretOffsetAheadOfTokenBefore(
    String line,
    List<String> commentLineStartSyntaxes,
    int searchStart,
  ) {
    if (searchStart == 0) {
      return 0;
    }

    final leadingSpace = line.length - line.trimLeft().length;
    if (searchStart <= leadingSpace) {
      // Jump to start of line.
      return 0;
    }

    var realSearchStart = searchStart;
    while (realSearchStart > 0 && line[realSearchStart - 1] == ' ') {
      realSearchStart -= 1;
    }

    // Handle case where search offset is in the middle of, or end of, the comment
    // line initiation syntax, e.g., "//" in Dart.
    final nearbyCodeCommentSyntaxRange =
        _maybeFindCommentSyntaxAroundOffset(line, realSearchStart, commentLineStartSyntaxes);
    if (nearbyCodeCommentSyntaxRange != null && realSearchStart != nearbyCodeCommentSyntaxRange.start) {
      // Jump to the start of the comment syntax.
      return nearbyCodeCommentSyntaxRange.start;
    }

    // Handle case where search offset is in the middle of a word.
    final currentWordRange = _applyWordBoundary(line, realSearchStart, TextAffinity.upstream);
    if (currentWordRange != null && realSearchStart != currentWordRange.start) {
      // Return the start of the currently selected token.
      return currentWordRange.start;
    }

    // Handle case where search offset already sits at leading edge of a word.
    if (currentWordRange != null && realSearchStart == currentWordRange.start && realSearchStart > 0) {
      // The search offset is already at the lead edge of a token. Find the next
      // token upstream and return its edge.
      final upstreamWordRange = _applyWordBoundary(line, realSearchStart - 1, TextAffinity.upstream);

      if (upstreamWordRange != null) {
        // Return the start of the upstream token.
        return upstreamWordRange.start;
      }
    }

    return realSearchStart;
  }

  static int findCaretOffsetAtEndOfTokenAfter(
    String line,
    List<String> commentLineStartSyntaxes,
    int searchStart,
  ) {
    if (searchStart >= line.length) {
      return searchStart;
    }

    final leadingSpace = line.length - line.trimLeft().length;
    if (searchStart <= leadingSpace) {
      // Search offset is in indentation space. Jump to end of comment syntax.
      final commentSyntaxRange = _maybeFindCommentSyntaxAroundOffset(line, leadingSpace + 1, commentLineStartSyntaxes);
      if (commentSyntaxRange == null) {
        if (line[searchStart] == ' ') {
          // This is probably a line in a multi-line comment, which has no comment
          // syntax at all. Jump past all the indentation.
          return leadingSpace;
        } else {
          // This shouldn't happen, but it might happen if a language doesn't pass in the
          // correct comment syntax, e.g., pass Dart syntax "//" when it should be Luau
          // syntax "--".
          //
          // Move forward by one character as a reasonable backup behavior.
          return searchStart + 1;
        }
      }

      return commentSyntaxRange.end;
    }

    final nearestWordRange = _applyWordBoundary(line, searchStart, TextAffinity.downstream);
    if (nearestWordRange != null && searchStart != nearestWordRange.end) {
      return nearestWordRange.end;
    }

    return searchStart;
  }

  /// Check if the given [offset] sits in the middle of, or edge of, the given [commentLineStartSyntaxes],
  /// e.g., "/|/" or "//|" in Dart.
  ///
  /// This query is helpful when jumping tokens upstream and downstream, as well as selecting entire tokens, because
  /// the comment syntax should be jumped or selected all as one token, rather than treated as a series of
  /// independent slashes "/" or dashes "-", etc.
  static TextRange? _maybeFindCommentSyntaxAroundOffset(
    String codeCommentLine,
    int offset,
    List<String> commentLineStartSyntaxes,
  ) {
    for (final startSyntax in commentLineStartSyntaxes) {
      final startRegExp = RegExp("\\s*($startSyntax)");
      final match = startRegExp.firstMatch(codeCommentLine);
      if (match != null) {
        // This line begins with the given `startSyntax`. Now, check if the click offset
        // is somewhere in that starting syntax.
        final leadingSpaceCount = codeCommentLine.length - codeCommentLine.trimLeft().length;
        if (leadingSpaceCount <= offset && offset <= match.end) {
          return TextRange(start: leadingSpaceCount, end: match.end);
        }
      }
    }

    return null;
  }

  static TextRange? _applyWordBoundary(String text, int offset, TextAffinity affinity) {
    if (offset > text.length) {
      return null;
    }

    if (offset < text.length && _boundaryRegex.hasMatch(text[offset])) {
      if (text[offset] != ' ') {
        // User selected a non-word character, which also isn't a space.
        // Select just this character.
        return TextRange(start: offset, end: offset + 1);
      } else {
        // User selected a space. Either select upstream or downstream.
        return switch (affinity) {
          TextAffinity.upstream => _findUpstreamWordRange(text, offset) ?? _findDownstreamWordRange(text, offset),
          TextAffinity.downstream => _findDownstreamWordRange(text, offset) ?? _findUpstreamWordRange(text, offset),
        };
      }
    }

    int start = offset;
    while (start > 0 && !_boundaryRegex.hasMatch(text[start - 1])) {
      start--;
    }

    int end = offset;
    while (end < text.length && !_boundaryRegex.hasMatch(text[end])) {
      end++;
    }

    return TextRange(start: start, end: end);
  }

  static TextRange? _findUpstreamWordRange(String line, int startOffset) {
    if (startOffset <= 0) {
      // No text upstream to search.
      return null;
    }

    var endOfWord = startOffset - 1;
    while (line[endOfWord] == ' ') {
      endOfWord -= 1;
    }
    if (endOfWord < 0) {
      // There were spaces all the way to the beginning of the line.
      return null;
    }

    final isEndNonWordCharacter = _boundaryRegex.hasMatch(line[endOfWord]);
    if (isEndNonWordCharacter) {
      // This is a non-word character, like ";" or ":". Select just this character.
      return TextRange(start: endOfWord, end: endOfWord + 1);
    }

    var startOfWord = endOfWord;
    while (startOfWord >= 1 && !_boundaryRegex.hasMatch(line[startOfWord - 1])) {
      startOfWord -= 1;
    }

    return TextRange(start: startOfWord, end: endOfWord + 1); // +1 because exclusive.
  }

  static TextRange? _findDownstreamWordRange(String line, int startOffset) {
    if (startOffset >= line.length) {
      // No text downstream to search.
      return null;
    }

    var startOfWord = startOffset + 1;
    while (line[startOfWord] == ' ') {
      startOfWord += 1;
    }
    if (startOfWord >= line.length) {
      // There were spaces all the way to the end of the line.
      return null;
    }

    final isStartNonWordCharacter = _boundaryRegex.hasMatch(line[startOfWord]);
    if (isStartNonWordCharacter) {
      // This is a non-word character, like ";" or ":". Select just this character.
      return TextRange(start: startOfWord, end: startOfWord + 1);
    }

    var endOfWord = startOfWord;
    while (endOfWord < line.length - 1 && !_boundaryRegex.hasMatch(line[endOfWord + 1])) {
      endOfWord += 1;
    }

    return TextRange(start: startOfWord, end: endOfWord + 1); // +1 because exclusive.
  }
}
