import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:example/lsp_exploration/lsp/messages/common_types.dart';
import 'package:example/lsp_exploration/lsp/messages/did_open_text_document.dart';
import 'package:example/lsp_exploration/lsp/messages/document_symbols.dart';
import 'package:example/lsp_exploration/lsp/messages/hover.dart';
import 'package:example/lsp_exploration/lsp/messages/initialize.dart';
import 'package:example/lsp_exploration/lsp/messages/semantic_tokens.dart';
import 'package:example/lsp_exploration/lsp/messages/type_hierarchy.dart';

class LspClient {
  LspJsonRpcClient? _lspClientCommunication;

  Future<void> start() async {
    _lspClientCommunication = LspJsonRpcClient();
    await _lspClientCommunication!.start();
  }

  Future<InitializeResult> initialize(InitializeParams request) async {
    final data = await _lspClientCommunication!.sendRequest(
      'initialize',
      request.toJson(),
    );

    if (data is! LspObject) {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }

    return InitializeResult.fromJson(data.value);
  }

  Future<void> initialized() async {
    await _lspClientCommunication!.sendNotification(
      'initialized',
    );
  }

  void stop() {
    _lspClientCommunication?.stop();
  }

  Future<void> didOpenTextDocument(DidOpenTextDocumentParams params) async {
    await _lspClientCommunication!.sendNotification(
      'textDocument/didOpen',
      params.toJson(),
    );
  }

  Future<Hover?> hover(HoverParams params) async {
    final data = await _lspClientCommunication!.sendRequest(
      'textDocument/hover',
      params.toJson(),
    );

    if (data is LspNull) {
      return null;
    }

    if (data is! LspObject) {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }

    return Hover(
      contents: data.value['contents'],
      range: data.value['range'] == null ? null : Range.fromJson(data.value['range']),
    );
  }

  Future<List<DocumentSymbol>?> documentSymbols(DocumentSymbolsParams params) async {
    final data = await _lspClientCommunication!.sendRequest(
      'textDocument/documentSymbol',
      params.toJson(),
    );

    if (data is LspNull) {
      return null;
    }

    if (data is! LspArray) {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }

    return List<DocumentSymbol>.from(
      data.value.map((json) => DocumentSymbol.fromJson(json)),
    );
  }

  Future<SemanticTokens?> semanticTokens(SemanticTokensParms params) async {
    final data = await _lspClientCommunication!.sendRequest(
      'textDocument/semanticTokens/full',
      params.toJson(),
    );

    if (data is LspNull) {
      return null;
    }

    if (data is! LspObject) {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }

    return SemanticTokens(
      resultId: data.value['resultId'],
      data: List<int>.from(data.value['data']),
    );
  }

  // TODO: Replace TextDocumentPositionParams with a TypeHierarchyPrepareParams
  Future<List<TypeHierarchyItem>?> prepareTypeHierarchy(PrepareTypeHierarchyParams params) async {
    final data = await _lspClientCommunication!.sendRequest(
      'textDocument/prepareTypeHierarchy',
      params.toJson(),
    );

    if (data is LspNull) {
      return null;
    }

    if (data is! LspArray) {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }

    return data.value.map((itemJson) => TypeHierarchyItem.fromJson(itemJson)).toList();
  }
}

class LspJsonRpcClient {
  Process? _lspProcess;
  int _currentCommandId = 0;

  final _pendingResponses = <int, Completer<LspAny>>{};
  String _buffer = '';
  bool _didParseHeader = false;

  int? _contentLength;
  String? _contentType;

  Future<void> start() async {
    _buffer = '';
    _pendingResponses.clear();
    _didParseHeader = false;

    final process = await Process.start('dart', [
      'language-server', //
      '--client-id', 'inception.plugin', //
      '--client-version', '0.1'
    ]);
    process.stdout.listen(_onData);
    process.stderr.listen(_onError);

    _lspProcess = process;
  }

  Future<LspAny> sendRequest(String method, Map<String, dynamic> params) async {
    if (_lspProcess == null) {
      throw Exception('LSP process not started. Did you forget to call start?');
    }

    _currentCommandId += 1;
    final messageId = _currentCommandId;
    final completer = Completer<LspAny>();
    _pendingResponses[messageId] = completer;

    _send(messageId, method, params);

    return completer.future;
  }

  Future<void> sendNotification(String method, [Map<String, dynamic>? params]) async {
    if (_lspProcess == null) {
      throw Exception('LSP process not started. Did you forget to call start?');
    }

    if (_lspProcess == null) {
      throw Exception('LSP process not started. Did you forget to call start?');
    }

    _currentCommandId += 1;

    return _send(_currentCommandId, method, params ?? const {});
  }

  Future<void> stop() async {
    _lspProcess?.kill();
  }

  Future<void> _send(int messageId, String method, Map<String, dynamic> params) async {
    final request = {
      'jsonrpc': '2.0',
      'id': messageId,
      'method': method,
      'params': params,
    };

    final payload = jsonEncode(request);
    final message = 'Content-Length: ${payload.length}\r\n\r\n$payload\r\n';

    _lspProcess!.stdin.write(message);
  }

  void _onData(List<int> event) {
    _buffer += String.fromCharCodes(event);

    print("_onData - buffer:\n${_buffer.toString()}");

    while (_tryParse()) {
      // Keep trying to parse until we either finish parsing the message
      // or we reach the end of the data buffer.
    }
  }

  bool _tryParse() {
    if (!_didParseHeader) {
      if (!_tryParseHeader()) {
        return false;
      }
    }

    return _tryParseContent();
  }

  bool _tryParseHeader() {
    int indexOfNextNewLine = _buffer.indexOf('\r\n');
    if (indexOfNextNewLine == -1) {
      // A new line marks the end of the header. We don't have a header yet.
      return false;
    }

    while (indexOfNextNewLine > -1) {
      final headerLine = _buffer.substring(0, indexOfNextNewLine);

      if (headerLine.isEmpty) {
        // Two consecutive new lines mark the end of the header. Remove the new line
        // from the buffer.
        _buffer = _buffer.substring(indexOfNextNewLine + 2);
        break;
      }

      final keyAndValue = headerLine.split(':');
      if (keyAndValue.length != 2) {
        // The header is not in an expected format.
        return false;
      }

      _handleHeader(keyAndValue[0], keyAndValue[1].trim());

      _buffer = _buffer.substring(indexOfNextNewLine + 2);
      indexOfNextNewLine = _buffer.indexOf('\r\n');
    }

    _didParseHeader = true;
    return true;
  }

  bool _tryParseContent() {
    if (_contentLength == null) {
      // We don't have a content length yet.
      return false;
    }

    if (_buffer.length < _contentLength!) {
      // We don't have enough data to parse the content yet.
      return false;
    }

    if (_contentType == null) {
      // We don't have a content type yet.
      return false;
    }

    if (_contentType != 'application/vscode-jsonrpc; charset=utf-8') {
      // The response is not in the expected format.
      return false;
    }

    final content = _buffer.substring(0, _contentLength);

    // Remove the current content from the buffer.
    _buffer = _buffer.substring(_contentLength!);

    // Reset to parse the next message.
    _didParseHeader = false;
    _contentLength = null;
    _contentType = null;

    final map = jsonDecode(content);

    // TODO: should we handle malformed responses?
    final commandId = map['id'] as int?;
    if (commandId == null) {
      // We received a notification.
      return true;
    }

    final completer = _pendingResponses.remove(commandId);

    if (completer == null) {
      // We received a response for a command we didn't send.
      return true;
    }

    final error = map['error'] as Map<String, dynamic>?;

    if (error != null) {
      completer.completeError(LspResponseError.fromJson(error));
    } else {
      completer.complete(jsonTypeToLspType(map["result"]));
    }

    return true;
  }

  void _handleHeader(String name, String value) {
    switch (name) {
      case 'Content-Length':
        _contentLength = int.tryParse(value);
        break;
      case 'Content-Type':
        _contentType = value;
        break;
    }
  }

  void _onError(List<int> event) {
    print(event);
  }
}

/// Converts a Dart Type to a Language Server Protocol primitive type, e.g., a List
/// to an [LspList].
LspAny jsonTypeToLspType(dynamic value) {
  return switch (value) {
    Map<String, dynamic> map => LspObject(map),
    List<dynamic> list => LspArray(list),
    String string => LspString(string),
    int integer => LspInteger(integer),
    double decimal => LspDecimal(decimal),
    bool boolean => LspBool(boolean),
    null => LspNull(),
    _ => throw Exception('Unknown type: $value'),
  };
}

class LspResponseError {
  LspResponseError({
    required this.code,
    required this.message,
    this.data,
  });

  final int code;
  final String message;
  final dynamic data;

  factory LspResponseError.fromJson(Map<String, dynamic> json) {
    return LspResponseError(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'],
    );
  }
}

sealed class LspAny {}

class LspObject extends LspAny {
  LspObject(this.value);

  final Map<String, dynamic> value;
}

class LspArray extends LspAny {
  final List<dynamic> value;

  LspArray(this.value);
}

class LspString extends LspAny {
  LspString(this.value);

  final String value;
}

class LspInteger extends LspAny {
  final int value;

  LspInteger(this.value);
}

class LspDecimal extends LspAny {
  LspDecimal(this.value);

  final double value;
}

class LspBool extends LspAny {
  final bool value;

  LspBool(this.value);
}

class LspNull extends LspAny {
  LspNull();
}