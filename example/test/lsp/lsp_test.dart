import 'package:flutter_test/flutter_test.dart';
import 'package:inception/inception.dart';

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
}
