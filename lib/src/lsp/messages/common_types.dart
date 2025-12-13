class TextDocumentIdentifier {
  const TextDocumentIdentifier({
    required this.uri,
  });
  final String uri;

  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
    };
  }
}

mixin TextDocumentPositionParams {
  final TextDocumentIdentifier textDocument = const TextDocumentIdentifier(uri: '');
  final Position position = const Position(line: -1, character: -1);

  Map<String, dynamic> toJson() {
    return {
      'textDocument': textDocument.toJson(),
      'position': position.toJson(),
    };
  }
}

class Position {
  const Position({
    required this.line,
    required this.character,
  });

  final int line;
  final int character;

  Map<String, dynamic> toJson() {
    return {
      'line': line,
      'character': character,
    };
  }
}

class Range {
  const Range({
    required this.start,
    required this.end,
  });

  final Position start;
  final Position end;

  Map<String, dynamic> toJson() {
    return {
      'start': start.toJson(),
      'end': end.toJson(),
    };
  }

  factory Range.fromJson(Map<String, dynamic> json) {
    return Range(
      start: Position(
        line: json['start']['line'] as int,
        character: json['start']['character'] as int,
      ),
      end: Position(
        line: json['end']['line'] as int,
        character: json['end']['character'] as int,
      ),
    );
  }
}

class Location {
  Location({
    required this.uri,
    required this.range,
  });

  final String uri;
  final Range range;

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      uri: json['uri'],
      range: Range.fromJson(json['range']),
    );
  }
}
