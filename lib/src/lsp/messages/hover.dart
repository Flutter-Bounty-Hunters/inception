import 'common_types.dart';

class HoverParams {
  HoverParams({
    required this.textDocument,
    required this.position,
    this.workDoneToken,
  });

  final TextDocumentIdentifier textDocument;
  final Position position;
  final String? workDoneToken;

  Map<String, dynamic> toJson() {
    return {
      'textDocument': textDocument.toJson(),
      'position': position.toJson(),
    };
  }
}

class Hover {
  Hover({
    required this.contents,
    this.range,
  });

  final dynamic contents;
  final Range? range;
}
