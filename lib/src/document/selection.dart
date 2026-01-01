import 'dart:ui';

class CodeSelection {
  const CodeSelection.collapsed(CodePosition position)
      : base = position,
        extent = position;

  const CodeSelection({
    required this.base,
    required this.extent,
  });

  final CodePosition base;
  final CodePosition extent;

  /// Returns the [CodePosition] at the most upstream point in the selection, which might be the
  /// [base] or the [extent], depending on the direction of the selection.
  CodePosition get start => base <= extent ? base : extent;

  /// Returns the [CodePosition] at the most downstream point in the selection, which might be the
  /// [base] or the [extent], depending on the direction of the selection.
  CodePosition get end => base <= extent ? extent : base;

  bool get isCollapsed => base == extent;

  bool get isExpanded => base != extent;

  /// Returns `true` if the selection points from upstream to downstream, e.g., the
  /// base of the selection comes before the extent.
  bool get isDownstream => extent >= base;

  /// Returns `true` if the selection points from downstream to upstream, e.g., the
  /// extent of the selection comes before the base.
  bool get isUpstream => base > extent;

  CodeRange toRange() {
    final affinity = extent.line > base.line || extent.characterOffset >= base.characterOffset
        ? TextAffinity.downstream
        : TextAffinity.upstream;

    return CodeRange(
      affinity == TextAffinity.downstream ? base : extent,
      affinity == TextAffinity.downstream ? extent : base,
    );
  }

  @override
  String toString() =>
      "[CodeRange]: L${base.line}:C${base.characterOffset} -> L${extent.line}:C${extent.characterOffset}";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeSelection && runtimeType == other.runtimeType && base == other.base && extent == other.extent;

  @override
  int get hashCode => base.hashCode ^ extent.hashCode;
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
  static const start = CodePosition(0, 0);

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodePosition &&
          runtimeType == other.runtimeType &&
          line == other.line &&
          characterOffset == other.characterOffset;

  @override
  int get hashCode => line.hashCode ^ characterOffset.hashCode;
}
