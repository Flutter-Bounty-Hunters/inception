import 'common_types.dart';

// TODO: maybe we want to get rid of TextDocumentPositionParams.
class DefinitionsParams with TextDocumentPositionParams {
  DefinitionsParams({
    this.textDocument = const TextDocumentIdentifier(uri: ''),
    this.position = const Position(line: -1, character: -1),
  });

  @override
  final TextDocumentIdentifier textDocument;

  @override
  final Position position;
}
