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

  static TextRange? _applyWordBoundary(String text, int offset, TextAffinity affinity) {
    if (_boundaryRegex.hasMatch(text[offset])) {
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
