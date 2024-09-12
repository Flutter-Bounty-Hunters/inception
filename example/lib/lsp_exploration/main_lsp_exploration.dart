import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lsp_client/lsp_client.dart';

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

    final client = LspClient();
    await client.start();
    print("LSP client is started");

    await client.initialize(
      InitializeParams(
        rootUri: 'file://$directoryPath',
        capabilities: const ClientCapabilities(
          experimental: {
            'supportsDartTextDocumentContentProvider': true,
          },
        ),
      ),
    );

    final initializedFuture = await client.initialized();
    print("LSP is initialized");

    // final analyzedFuture = await client.awaitAnalyzed();
    // print("LSP analysis is done");

    print("Sending textDocumentSymbol request");
    await client.dartTextDocumentSymbol('$directoryPath/lib/main.dart');

    // final contentResult = await client.dartTextDocumentContent(
    //   DartTextDocumentContentParams(
    //     uri: 'file://$directoryPath/lib/main.dart',
    //   ),
    // );
    print("Received content result");

    // print(contentResult.content); // ignore: avoid_print
    await client.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
