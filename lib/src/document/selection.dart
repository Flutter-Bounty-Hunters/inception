import 'dart:ui';

class CodeSelection {
  const CodeSelection({
    required this.base,
    required this.extent,
  });

  final CodePosition base;
  final CodePosition extent;

  CodeRange toRange() {
    final affinity = extent.line > base.line || extent.characterOffset >= base.characterOffset
        ? TextAffinity.downstream
        : TextAffinity.upstream;

    return CodeRange(
      affinity == TextAffinity.downstream ? base : extent,
      affinity == TextAffinity.downstream ? extent : base,
    );
  }
}

/// A range of code, from a starting line and offset, to an ending line and offset.
class CodeRange {
  const CodeRange(this.start, this.end) : assert(start <= end);

  final CodePosition start;
  final CodePosition end;

  CodeSelection toSelection([TextAffinity affinity = TextAffinity.downstream]) {
    return CodeSelection(
      base: affinity == TextAffinity.downstream ? start : end,
      extent: affinity == TextAffinity.downstream ? end : start,
    );
  }

  @override
  String toString() => "[CodeRange - $start -> $end]";
}

class CodePosition implements Comparable<CodePosition> {
  const CodePosition(this.line, this.characterOffset);

  final int line;
  final int characterOffset;

  bool operator <(CodePosition other) {
    return compareTo(other) < 0;
  }

  bool operator <=(CodePosition other) {
    return compareTo(other) <= 0;
  }

  bool operator >(CodePosition other) {
    return compareTo(other) > 0;
  }

  bool operator >=(CodePosition other) {
    return compareTo(other) >= 0;
  }

  @override
  int compareTo(CodePosition other) {
    if (line == other.line) {
      return characterOffset - other.characterOffset;
    }

    return line - other.line;
  }

  @override
  String toString() => "(line: $line, offset: $characterOffset)";
}
