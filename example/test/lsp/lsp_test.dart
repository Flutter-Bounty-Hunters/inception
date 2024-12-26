import 'dart:io';

import 'package:example/ide/infrastructure/user_settings.dart';
import 'package:example/ide/workspace.dart';
import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:example/lsp_exploration/lsp/messages/code_actions.dart';
import 'package:example/lsp_exploration/lsp/messages/common_types.dart';
import 'package:example/lsp_exploration/lsp/messages/document_symbols.dart';
import 'package:example/lsp_exploration/lsp/messages/hover.dart';
import 'package:example/lsp_exploration/lsp/messages/rename_files_params.dart';
import 'package:example/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'test_tools.dart';

void main() {
  testLsp('produces hover information', (lspTester) async {
    const filePath = 'lib/counter.dart';

    await lspTester.openFile(filePath);

    final hover = await lspTester.client.hover(
      HoverParams(
        textDocument: TextDocumentIdentifier(uri: lspTester.filePathToUri(filePath)),
        position: const Position(line: 3, character: 9),
      ),
    );

    expect(hover?.contents, isNotEmpty);
  });

  testLsp('produces code actions for a widget', (lspTester) async {
    const filePath = 'lib/counter.dart';

    await lspTester.openFile(filePath);

    // Query code actions for "MaterialApp" in the build method.
    final actions = await lspTester.client.codeAction(
      CodeActionsParams(
        textDocument: TextDocumentIdentifier(uri: lspTester.filePathToUri(filePath)),
        range: const Range(
          start: Position(line: 9, character: 17),
          end: Position(line: 9, character: 17),
        ),
        context: const CodeActionContext(
          only: [CodeActionKind.refactor],
          triggerKind: CodeActionTriggerKind.invoked,
        ),
      ),
    );

    // Ensure the expected actions are present.
    expect(actions!.map((e) => e.title).toList(), [
      'Wrap with widget...',
      'Wrap with Builder',
      'Wrap with StreamBuilder',
      'Wrap with Center',
      'Wrap with Container',
      'Wrap with Padding',
      'Wrap with SizedBox',
      'Wrap with Column',
      'Wrap with Row',
      'Extract Method',
      'Extract Local Variable',
      'Extract Widget',
    ]);
  });

  // testLsp('produces refactorings for file rename', (tester) async {
  //   const filePath = 'lib/counter.dart';
  //   const newPath = 'lib/counter_2.dart';

  //   final res = await tester.client.willRenameFiles(
  //     RenameFilesParams(
  //       files: [
  //         FileRename(
  //           oldUri: tester.filePathToUri(filePath),
  //           newUri: tester.filePathToUri(newPath),
  //         )
  //       ],
  //     ),
  //   );

  //   expect(res, isNotNull);
  //   expect(res!['documentChanges'], isNotNull);
  //   expect((res['documentChanges'] as List<dynamic>), isNotEmpty);
  //});

  testLsp('lists test files', (lspTester) async {
    try {
      const testFolder = './test/lsp';

      final directory = Directory(testFolder);

      List<String> testFiles = [];

      directory.listSync().forEach((e) {
        if (isTestFile(e.path)) {
          testFiles.add(e.path);
        }
      });

      print('Test Files: $testFiles');

      const filepath =
          "file:///Users/rutviktak/flutter_projects/os_contributions/inception/example/test/lsp/lsp_test.dart"; //lspTester.filePathToUri(testFiles.first);

      print("File path-->$filepath");

      final documentSymboles = await lspTester.client.documentSymbols(
        DocumentSymbolsParams(textDocument: const TextDocumentIdentifier(uri: filepath)),
      );

      for (var element in documentSymboles!) {
        switch (element.kind) {
          case SymbolKind.method:
            final testDescription = extractTestNameFromOutline(element.name);

            print('Document Symbols: ${element.kind} $testDescription');
            break;
          case SymbolKind.function:
            break;
          default:
        }
      }

      // filter methods

      // discover test suites within each test file
    } on LspResponseError catch (e) {
      print('Error: ${e.message}');
    } catch (e) {
      print('Error: $e');
    }
  });
}

bool isTestFile(String file) {
  // To be a test, you must be _test.dart AND inside a test folder (unless allowTestsOutsideTestFolder).
  // https://github.com/Dart-Code/Dart-Code/issues/1165
  // https://github.com/Dart-Code/Dart-Code/issues/2021
  // https://github.com/Dart-Code/Dart-Code/issues/2034
  return isDartFile(file) &&
      (isInsideFolderNamed(file, "test") ||
          isInsideFolderNamed(file, "integration_test") ||
          isInsideFolderNamed(file, "test_driver") ||
          false) &&
      file.toLowerCase().endsWith("_test.dart");
}

bool isDartFile(String file) {
  return path.extension(file.toLowerCase()) == ".dart" &&
      File(file).existsSync() &&
      File(file).statSync().type == FileSystemEntityType.file;
}

bool isInsideFolderNamed(String? file, String folderName) {
  if (file == null) return false;

  final ws = path.dirname(file); // workspace.getWorkspaceFolder(Uri.file(file));

  if (ws == ".") return false;

  final relPath = path.relative(fsPath(Uri.parse(ws)).toLowerCase(), from: file.toLowerCase());

  final segments = relPath.split(path.separator);

  return segments.contains(folderName.toLowerCase());
}

String fsPath(Uri uri, {useRealCasing = false}) {
  // tslint:disable-next-line:disallow-fspath
  final newPath = uri.toFilePath();

  return File(newPath).absolute.path;

  // if (useRealCasing) {
  // 	final realPath = File(newPath).absolute.path;
  // 	// Since realpathSync.native will resolve symlinks, only do anything if the paths differ
  // 	// _only_ by case.
  // 	// when there was no symlink (eg. the lowercase version of both paths match).
  // 	if (realPath && realPath.toLowerCase() === newPath.toLowerCase() && realPath !== newPath) {
  // 		console.warn(`Rewriting path:\n  ${newPath}\nto:\n  ${realPath} because the casing appears incorrect`);
  // 		newPath = realPath;
  // 	}
  // }

  // newPath = forceWindowsDriveLetterToUppercase(newPath);

  // return newPath;
}

String? extractTestNameFromOutline(String elementName) {
  // Strip off the function name/parent like test( or testWidget(
  final openParen = elementName.indexOf("(");
  final closeParen = elementName.lastIndexOf(")");
  if (openParen == -1 || closeParen == -1 || openParen >= closeParen) return null;

  elementName = elementName.substring(openParen + 2, closeParen - 1);

  // For tests with variables, we often end up with additional quotes wrapped
  // around them...
  if ((elementName.startsWith("'") || elementName.startsWith('"')) &&
      (elementName.endsWith("'") || elementName.endsWith('"')))
    elementName = elementName.substring(1, elementName.length - 1);

  return elementName;
}
