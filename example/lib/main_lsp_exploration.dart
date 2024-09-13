import 'dart:io';

import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:example/lsp_exploration/lsp/messages/common_types.dart';
import 'package:example/lsp_exploration/lsp/messages/did_open_text_document.dart';
import 'package:example/lsp_exploration/lsp/messages/document_symbols.dart';
import 'package:example/lsp_exploration/lsp/messages/initialize.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: _Screen(),
    ),
  );
}

class _Screen extends StatefulWidget {
  const _Screen();

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  @override
  void initState() {
    super.initState();

    _doDemo();
  }

  Future<void> _doDemo() async {
    final directory = await _selectSourceDirectory();
    if (directory == null) {
      print("Failed to select a directory");
      return;
    }

    await _connectToLsp(directory);
  }

  Future<Directory?> _selectSourceDirectory() async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      return null;
    }

    return Directory(directoryPath);
  }

  Future<void> _connectToLsp(Directory directory) async {
    print("Connecting to LSP...");
    // final pwd = Directory.current.path;
    // const pwd = "/Users/matt/Projects/inception/example";
    print("Source directory: ${directory.absolute.path}");
    final directoryPath = directory.absolute.path;

    final client = SuperLsp();
    await client.start();
    print("LSP client is started");

    try {
      await client.initialize(
        InitializeParams(
          rootUri: 'file://$directoryPath',
          capabilities: LspClientCapabilities(
              // experimental: {
              //   'supportsDartTextDocumentContentProvider': true,
              // },
              ),
        ),
      );

      // Notify the LSP server that we are done handling the initialize result.
      await client.initialized();

      // final analyzedFuture = await client.awaitAnalyzed();
      // print("LSP analysis is done");
      // Notify the LSP server that we have opened a text document.
      final exampleFile = '$directoryPath/lib/main.dart';
      final fileUri = 'file://$exampleFile';
      final content = await File(exampleFile).readAsString();
      await client.didOpenTextDocument(
        DidOpenTextDocumentParams(
          textDocument: TextDocumentItem(
            uri: fileUri,
            languageId: 'dart',
            version: 1,
            text: content,
          ),
        ),
      );

      final symbols = await client.documentSymbols(
        DocumentSymbolsParams(
          textDocument: TextDocumentIdentifier(uri: fileUri),
        ),
      );
      if (symbols != null) {
        for (final symbol in symbols) {
          print("${symbol.name} (${symbol.kind}) at ${symbol.range.start.line}:${symbol.range.start.character}");
        }
      }

      //print("Sending textDocumentSymbol request");
      //await client.dartTextDocumentSymbol('$directoryPath/lib/main.dart');

      // final contentResult = await client.dartTextDocumentContent(
      //   DartTextDocumentContentParams(
      //     uri: 'file://$directoryPath/lib/main.dart',
      //   ),
      // );
      //print("Received content result");

      // print(contentResult.content); // ignore: avoid_print
    } on LspResponseError catch (e) {
      print('Error ${e.code}: ${e.message}');
    } finally {
      client.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
