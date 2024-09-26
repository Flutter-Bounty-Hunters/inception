import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:example/lsp_exploration/lsp/messages/common_types.dart';
import 'package:example/lsp_exploration/lsp/messages/document_symbols.dart';

class PrepareTypeHierarchyParams with TextDocumentPositionParams {
  PrepareTypeHierarchyParams({
    this.textDocument = const TextDocumentIdentifier(uri: ''),
    this.position = const Position(line: -1, character: -1),
  });

  @override
  final TextDocumentIdentifier textDocument;

  @override
  final Position position;

  // TODO: This is not a real LSP params type - the real one also mixes in work progress - match the real definition.
}

class TypeHierarchyItem {
  static TypeHierarchyItem fromJson(Map<String, dynamic> json) {
    return TypeHierarchyItem(
      name: json['name'],
      kind: SymbolKind.fromJson(json['kind']),
      tags: json['tags'] != null ? (json['tags'] as List<dynamic>).cast<int>() : [],
      detail: json['detail'],
      uri: json['uri'],
      range: Range.fromJson(json['range']),
      selectionRange: Range.fromJson(json['selectionRange']),
      data: jsonTypeToLspType(json['data']),
    );
  }

  const TypeHierarchyItem({
    required this.name,
    required this.kind,
    required this.tags,
    required this.detail,
    required this.uri,
    required this.range,
    required this.selectionRange,
    required this.data,
  });

  final String name;
  final SymbolKind kind;
  final List<int>? tags;
  final String? detail;
  final DocumentUri uri;
  final Range range;
  final Range selectionRange;
  final LspAny? data;
}

typedef DocumentUri = String;
