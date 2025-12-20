import 'dart:async';
import 'dart:io';

import 'package:example/ide/lsp/outline.dart';
import 'package:example/ide/testing/outline_test_extractor.dart';
import 'package:inception/inception.dart';
import 'package:path/path.dart' as path;

import 'package:example/ide/testing/test_node.dart';

/// Discovers tests in the root path of the LSP client.
///
/// This class uses the LSP client to extract the [Outline] of each test file and then
/// extracts the tests from the outline.
///
/// Looks for test files in the `test` and `test_goldens` folders.
class LspTestDiscoverer {
  LspTestDiscoverer({
    required this.lspClient,
  });

  final LspClient lspClient;

  /// A map that holds the pending notifications for each file URI.
  ///
  /// For each file that we open to extract the outline, we store a [Completer] that will be completed
  /// when we receive the outline notification from the LSP.
  final _pendingNotifications = <String, Completer<Outline>>{};

  Future<List<TestSuite>> discoverTests() async {
    lspClient.addNotificationListener(_onLspNotification);
    try {
      final testSuites = <TestSuite>[];

      final testFolder = Directory.fromUri(Uri.parse(_filePathToUri('test')));
      if (await testFolder.exists()) {
        final tests = await _discoverTestsInFolder(testFolder, false);
        testSuites.addAll(tests);
      }

      final goldenTestFolder = Directory.fromUri(Uri.parse(_filePathToUri('test_goldens')));
      if (await goldenTestFolder.exists()) {
        final tests = await _discoverTestsInFolder(goldenTestFolder, true);
        testSuites.addAll(tests);
      }

      for (final suite in testSuites) {
        debugPrintTestSuite(suite);
      }

      return testSuites;
    } finally {
      lspClient.removeNotificationListener(_onLspNotification);
    }
  }

  Future<List<TestSuite>> _discoverTestsInFolder(Directory testDirectory, bool isGoldenTestFolder) async {
    final testSuites = <TestSuite>[];

    final children = testDirectory.listSync();
    for (final child in children) {
      if (child is File && child.path.endsWith('_test.dart')) {
        final testSuite = await _discoverTestsInFile(child, isGoldenTestFolder);
        if (testSuite.children.isNotEmpty) {
          testSuites.add(testSuite);
        }
      } else if (child is Directory) {
        final tests = await _discoverTestsInFolder(child, isGoldenTestFolder);
        testSuites.addAll(tests);
      }
    }

    return testSuites;
  }

  Future<TestSuite> _discoverTestsInFile(File file, bool isGoldenTestFolder) async {
    try {
      final outline = await _extractOutlineFromFile(file);

      final extractor = OutlineTestExtractor();
      return extractor.extractTests(
        outline,
        file.uri.toString(),
        isGoldenTestFolder,
      );
    } on Exception {
      // We fail to extract the outline from the file.
      return TestSuite(
        fileUri: file.uri.toString(),
        nodes: [],
      );
    }
  }

  Future<Outline> _extractOutlineFromFile(File file) async {
    final uri = _filePathToUri(file.path);

    final completer = Completer<Outline>();

    // Store the completer so we can resolve the future when we receive the
    // outline notification.
    _pendingNotifications[uri] = completer;

    // Open the file so the LSP analyzes it and provides the outline.
    //
    // TODO: we should handle the cases where the file is already open.
    await lspClient.didOpenTextDocument(
      DidOpenTextDocumentParams(
        textDocument: TextDocumentItem(
          uri: uri,
          languageId: 'dart',
          version: 1,
          text: file.readAsStringSync(),
        ),
      ),
    );

    // TODO: should we add a timeout?
    return completer.future;
  }

  void _onLspNotification(LspNotification notification) {
    if (notification.method != "dart/textDocument/publishOutline") {
      return;
    }

    final uri = notification.params['uri'] as String;

    final completer = _pendingNotifications.remove(uri);
    if (completer == null) {
      // We are not waiting for the notification for this URI.
      return;
    }

    // Close the file so the LSP can release resources.
    //
    // TODO: we should handle the cases where the file was opened elsewhere.
    lspClient.didCloseTextDocument(
      DidCloseTextDocumentParams(
        textDocument: TextDocumentIdentifier(uri: uri),
      ),
    );

    try {
      final outline = OutlineNotification.fromJson(notification.params);
      completer.complete(outline.outline);
    } on Exception catch (e) {
      completer.completeError(e);
    }
  }

  String _filePathToUri(String filePath) {
    final absolutePath = path.isAbsolute(filePath) //
        ? filePath
        : path.join(lspClient.rootPath, filePath);
    return 'file://$absolutePath';
  }
}
