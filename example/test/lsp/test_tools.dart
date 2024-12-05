import 'dart:io';

import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:example/lsp_exploration/lsp/messages/did_open_text_document.dart';
import 'package:example/lsp_exploration/lsp/messages/initialize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// A dart test that initializes an LSP client and provides it to the test.
///
/// The LSP client is obtained from the [LspTester] passed as argument to the test body.
///
/// Provide a [workspacePath] to specify the root of the project.
///
/// If [workspacePath] is not provided, the root of the project running the test
/// will be used.
///
/// The LSP is stopped after the test body is executed.
@isTest
void testLsp(
  String description,
  LspTestCallback body, {
  String? workspacePath,
}) async {
  test(description, () async {
    final client = await initLsp(
      workspacePath: workspacePath ?? path.context.current,
    );
    try {
      final tester = LspTester(client: client);

      await body(tester);
    } finally {
      client.stop();
    }
  });
}

/// Initializes an LSP client with the given [workspacePath] as the
/// project root.
Future<LspClient> initLsp({
  required String workspacePath,
}) async {
  final client = LspClient();

  // Start the LSP process.
  await client.start();

  try {
    await client.initialize(
      InitializeParams(
        rootUri: 'file://$workspacePath',
        capabilities: LspClientCapabilities(),
      ),
    );

    // Tell the LSP we are ready.
    await client.initialized();
  } catch (e) {
    // Avoid letting a dangling LSP proccess running.
    client.stop();

    rethrow;
  }

  return client;
}

/// A class to make it easier to perform some operations with the LSP.
///
/// For example, opening a file in the LSP.
class LspTester {
  LspTester({
    required this.client,
  });

  final LspClient client;

  /// Opens the file with the given [filePath] in the LSP.
  ///
  /// The [filePath] can be relative to the project root or an absolute path.
  Future<void> openFile(String filePath) async {
    final file = filePathToUri(filePath);

    await client.didOpenTextDocument(
      DidOpenTextDocumentParams(
        textDocument: TextDocumentItem(
          uri: file,
          languageId: 'dart',
          version: 1,
          text: File(filePath).readAsStringSync(),
        ),
      ),
    );
  }

  /// Converts a file path to a URI.
  ///
  /// The [filePath] can be relative to the project root or an absolute path.
  ///
  /// The file URI starts with `file://`.
  String filePathToUri(String filePath) {
    final absolutePath = path.isAbsolute(filePath) //
        ? filePath
        : path.join(client.rootPath, filePath);
    return 'file://$absolutePath';
  }
}

typedef LspTestCallback = Future<void> Function(LspTester tester);
