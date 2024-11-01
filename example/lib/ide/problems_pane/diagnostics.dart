class Diagnostic {
  final String code;
  final String message;
  final Range range;
  final int severity;
  final String source;

  Diagnostic({
    required this.code,
    required this.message,
    required this.range,
    required this.severity,
    required this.source,
  });

  factory Diagnostic.fromJson(Map<String, dynamic> json) {
    return Diagnostic(
      code: json['code'] as String,
      message: json['message'] as String,
      range: Range.fromJson(json['range'] as Map<String, dynamic>),
      severity: json['severity'] as int,
      source: json['source'] as String,
    );
  }
}

class Range {
  final Position start;
  final Position end;

  Range({
    required this.start,
    required this.end,
  });

  factory Range.fromJson(Map<String, dynamic> json) {
    return Range(
      start: Position.fromJson(json['start'] as Map<String, dynamic>),
      end: Position.fromJson(json['end'] as Map<String, dynamic>),
    );
  }
}

class Position {
  final int line;
  final int character;

  Position({
    required this.line,
    required this.character,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      line: json['line'] as int,
      character: json['character'] as int,
    );
  }
}
