import 'package:example/lsp_exploration/lsp/messages/common_types.dart';

class DocumentSymbolsParams {
  DocumentSymbolsParams({
    required this.textDocument,
  });

  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() => {
        'textDocument': textDocument.toJson(),
      };
}

class DocumentSymbol {
  DocumentSymbol({
    required this.name,
    this.detail,
    required this.kind,
    required this.range,
  });

  final String name;
  final String? detail;
  final SymbolKind kind;
  final Range range;

  factory DocumentSymbol.fromJson(Map<String, dynamic> json) {
    return DocumentSymbol(
      name: json['name'],
      detail: json['detail'],
      kind: SymbolKind.values.firstWhere((e) => e.value == json['kind']),
      range: Range.fromJson(json['location']['range']),
    );
  }
}

enum SymbolKind {
  file(1),
  module(2),
  namespace(3),
  package(4),
  class_(5),
  method(6),
  property(7),
  field(8),
  constructor(9),
  enum_(10),
  interface(11),
  function(12),
  variable(13),
  constant(14),
  string(15),
  number(16),
  boolean(17),
  array(18),
  object(19),
  key(20),
  null_(21),
  enumMember(22),
  struct(23),
  event(24),
  operator(25),
  typeParameter(26);

  const SymbolKind(this.value);

  final int value;
}
