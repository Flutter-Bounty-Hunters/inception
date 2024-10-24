import 'dart:io';

import 'package:example/ide/ide.dart';
import 'package:example/ide/workspace.dart';
import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:example/lsp_exploration/lsp/messages/common_types.dart';
import 'package:example/lsp_exploration/lsp/messages/did_open_text_document.dart';
import 'package:example/lsp_exploration/lsp/messages/document_symbols.dart';
import 'package:example/lsp_exploration/lsp/messages/initialize.dart';
import 'package:example/lsp_exploration/lsp/messages/type_hierarchy.dart';
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
  final _workspace = Workspace(
    // Currently, the workspace directory is pulled from a variable defined by
    // the run command so that different developers can open up directories on
    // their respective machines.
    Directory(const String.fromEnvironment("CONTENT_DIRECTORY")),
  );

  // @override
  // void initState() {
  //   super.initState();
  //
  //   _doDemo();
  // }

  // Future<void> _doDemo() async {
  //   // final directory = await _selectSourceDirectory();
  //   // if (directory == null) {
  //   //   print("Failed to select a directory");
  //   //   return;
  //   // }
  //   final directory = Directory(const String.fromEnvironment("CONTENT_DIRECTORY"));
  //
  //   await _connectToLsp(directory);
  // }
  //
  // Future<Directory?> _selectSourceDirectory() async {
  //   final directoryPath = await FilePicker.platform.getDirectoryPath();
  //   if (directoryPath == null) {
  //     return null;
  //   }
  //
  //   return Directory(directoryPath);
  // }
  //
  // Future<void> _connectToLsp(Directory directory) async {
  //   print("Connecting to LSP...");
  //   // final pwd = Directory.current.path;
  //   // const pwd = "/Users/matt/Projects/inception/example";
  //   print("Source directory: ${directory.absolute.path}");
  //   final directoryPath = directory.absolute.path;
  //
  //   _client = LspClient();
  //   await _client.start();
  //   print("LSP client is started");
  //
  //   try {
  //     await _client.initialize(
  //       InitializeParams(
  //         rootUri: 'file://$directoryPath',
  //         capabilities: LspClientCapabilities(
  //             // experimental: {
  //             //   'supportsDartTextDocumentContentProvider': true,
  //             // },
  //             ),
  //       ),
  //     );
  //
  //     // Notify the LSP server that we are done handling the initialize result.
  //     await _client.initialized();
  //
  //     // // final analyzedFuture = await client.awaitAnalyzed();
  //     // // print("LSP analysis is done");
  //     // // Notify the LSP server that we have opened a text document.
  //     // final exampleFile = '$directoryPath/lib/main.dart';
  //     // final fileUri = 'file://$exampleFile';
  //     // final content = await File(exampleFile).readAsString();
  //     // await _client.didOpenTextDocument(
  //     //   DidOpenTextDocumentParams(
  //     //     textDocument: TextDocumentItem(
  //     //       uri: fileUri,
  //     //       languageId: 'dart',
  //     //       version: 1,
  //     //       text: content,
  //     //     ),
  //     //   ),
  //     // );
  //     //
  //     // final typeHierarchy = await _client.prepareTypeHierarchy(
  //     //   PrepareTypeHierarchyParams(
  //     //     textDocument: TextDocumentIdentifier(uri: fileUri),
  //     //     position: Position(line: 11, character: 9),
  //     //   ),
  //     // );
  //     // print("Prepare type hierarchy result:");
  //     // if (typeHierarchy == null) {
  //     //   print(" - No type hierarchy found");
  //     // } else {
  //     //   for (final type in typeHierarchy) {
  //     //     print(
  //     //         " - name: ${type.name}, detail: ${type.detail}, URI: ${type.uri}, range: ${type.range}, tags: ${type.tags}, symbol kind: ${type.kind}");
  //     //   }
  //     // }
  //     // print("------");
  //
  //     /////////////////////////////
  //     // final symbols = await client.documentSymbols(
  //     //   DocumentSymbolsParams(
  //     //     textDocument: TextDocumentIdentifier(uri: fileUri),
  //     //   ),
  //     // );
  //     // if (symbols != null) {
  //     //   for (final symbol in symbols) {
  //     //     print("${symbol.name} (${symbol.kind}) at ${symbol.range.start.line}:${symbol.range.start.character}");
  //     //   }
  //     // }
  //
  //     /////////////////////////////
  //     //print("Sending textDocumentSymbol request");
  //     //await client.dartTextDocumentSymbol('$directoryPath/lib/main.dart');
  //
  //     // final contentResult = await client.dartTextDocumentContent(
  //     //   DartTextDocumentContentParams(
  //     //     uri: 'file://$directoryPath/lib/main.dart',
  //     //   ),
  //     // );
  //     //print("Received content result");
  //
  //     // print(contentResult.content); // ignore: avoid_print
  //   } on LspResponseError catch (e) {
  //     print('Error ${e.code}: ${e.message}');
  //   } finally {
  //     // _client.stop();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return IDE(
      workspace: _workspace,
    );
  }
}
