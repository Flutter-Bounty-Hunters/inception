import 'common_types.dart';

class DidOpenTextDocumentParams {
  DidOpenTextDocumentParams({
    required this.textDocument,
  });

  final TextDocumentItem textDocument;

  Map<String, dynamic> toJson() => {
        'textDocument': textDocument.toJson(),
      };
}

class DidCloseTextDocumentParams {
  DidCloseTextDocumentParams({
    required this.textDocument,
  });

  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() => {
        'textDocument': textDocument.toJson(),
      };
}

class TextDocumentItem {
  TextDocumentItem({
    required this.uri,
    required this.languageId,
    required this.version,
    required this.text,
  });

  String uri;
  String languageId;
  int version;
  String text;

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'languageId': languageId,
        'version': version,
        'text': text,
      };
}
