//import 'package:path/path.dart' as path;
import 'package:example/lsp_exploration/lsp/messages/common_types.dart';
import 'package:example/lsp_exploration/lsp/messages/hover.dart';
//import 'package:example/lsp_exploration/lsp/messages/rename_files_params.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_tools.dart';

void main() {
  testLsp('produces hover information', (lspTester) async {
    const filePath = 'lib/ide/editor/editor.dart';

    await lspTester.openFile(filePath);

    final hover = await lspTester.client.hover(
      HoverParams(
        textDocument: TextDocumentIdentifier(uri: lspTester.filePathToUri(filePath)),
        position: const Position(line: 8, character: 16),
      ),
    );

    expect(hover?.contents, isNotEmpty);
  });

  // testLsp('produces refactorings for file rename', (tester) async {
  //   const filePath = 'lib/ide/editor/editor.dart';
  //   final newPath = '${path.dirname(filePath)}/editor_renamed.dart';

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
  //   expect(res!['changes'], isNotNull);
  //   expect((res['changes'] as Map<String, dynamic>).keys, isNotEmpty);
  // });
}
