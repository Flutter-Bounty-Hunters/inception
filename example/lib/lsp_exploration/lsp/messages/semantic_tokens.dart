import 'package:example/lsp_exploration/lsp/messages/common_types.dart';

class SemanticTokensParms {
  SemanticTokensParms({
    required this.textDocument,
  });

  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() => {
        'textDocument': textDocument.toJson(),
      };
}

class SemanticTokens {
  SemanticTokens({
    required this.resultId,
    required this.data,
  });

  final String? resultId;
  final List<int> data;

  factory SemanticTokens.fromJson(Map<String, dynamic> json) {
    return SemanticTokens(
      resultId: json['resultId'],
      data: List<int>.from(json['data']),
    );
  }
}
