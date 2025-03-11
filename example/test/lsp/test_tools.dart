import 'dart:async';
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
    final tester = LspTester();
    try {
      await tester.initialize(
        workspacePath: workspacePath ?? path.join(path.context.current, 'test', 'lsp', 'test_project'),
      );

      await body(tester);
    } finally {
      tester.stop();
    }
  });
}

/// A class to make it easier to perform some operations with the LSP.
///
/// For example, initializing the LSP and waiting it to finish analysis or opening a file.
class LspTester {
  late LspClient client;

  Completer<void> _pendingAnalysis = Completer<void>();

  Future<void> initialize({
    required String workspacePath,
  }) async {
    client = LspClient();

    // Start the LSP process.
    await client.start();

    try {
      // Listen for the $/analyzerStatus notification to know when the LSP has finished analysis.
      // Some operations, like code actions, return an empty array if the LSP is still analyzing.
      _pendingAnalysis = Completer<void>();
      client.addNotificationListener(_onLspAnalyzerListener);

      // Initialize the LSP.
      await client.initialize(
        InitializeParams(
          processId: pid,
          rootUri: 'file://$workspacePath',
          capabilities: LspClientCapabilities(),
          initializationOptions: {
            'outline': true,
          },
        ),
      );

      // Tell the LSP we are ready.
      await client.initialized();

      // Wait until we receive a notification that the LSP has finished analysis.
      await _pendingAnalysis.future;
    } catch (e) {
      // Avoid letting a dangling LSP proccess running.
      client.stop();

      rethrow;
    } finally {
      client.removeNotificationListener(_onLspAnalyzerListener);
    }
  }

  void stop() {
    client.stop();
  }

  /// Opens the file with the given [filePath] in the LSP.
  ///
  /// The [filePath] can be relative to the project root or an absolute path.
  Future<void> openFile(String filePath) async {
    final fileUri = filePathToUri(filePath);

    await client.didOpenTextDocument(
      DidOpenTextDocumentParams(
        textDocument: TextDocumentItem(
          uri: fileUri,
          languageId: 'dart',
          version: 1,
          text: File(Uri.parse(fileUri).path).readAsStringSync(),
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

  /// Waits for a notification from the LSP that the analyzer has finished analysis.
  void _onLspAnalyzerListener(LspNotification notification) {
    if ((notification.method == r'$/analyzerStatus') &&
        (notification.params['isAnalyzing'] == false) &&
        !_pendingAnalysis.isCompleted) {
      _pendingAnalysis.complete();
    }
  }
}

typedef LspTestCallback = Future<void> Function(LspTester lspTester);
