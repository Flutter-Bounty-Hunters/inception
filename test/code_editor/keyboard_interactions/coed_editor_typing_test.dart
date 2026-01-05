import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:inception/inception.dart';
import 'package:inception/language_dart.dart';
import 'package:inception/src/test/code_editor/code_editor_operations.dart';

void main() {
  group("Code Editor > editing >", () {
    testWidgetsOnMac("types a hello world document", (tester) async {
      await _pumpScaffold(tester);
      await tester.tap(find.byType(CodeEditor));

      await _writeHelloWorldApp.run(tester);

      expect(CodeEditorInspector.findContent(), _helloWorldApp);

      // Expire pending timers.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgetsOnMac("can delete entire hello world document", (tester) async {
      await _pumpScaffold(tester, code: _helloWorldApp);

      // Place caret at start of document.
      await tester.clickOnCodePosition(0, 0, affinity: TextAffinity.upstream);

      // Ensure we're starting with full "hello, world" document.
      expect(CodeEditorInspector.findContent(), _helloWorldApp);

      // Delete every character, one by one.
      for (int i = 0; i < _helloWorldApp.length; i += 1) {
        await tester.pressDelete();
      }

      // Ensure we deleted everything.
      expect(CodeEditorInspector.findContent(), "");

      // Expire pending timers.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgetsOnMac("can backspace entire hello world document", (tester) async {
      await _pumpScaffold(tester, code: _helloWorldApp);

      // Place caret at end of the document.
      await tester.tap(find.byType(CodeEditor));

      // Ensure we're starting with full "hello, world" document.
      expect(CodeEditorInspector.findContent(), _helloWorldApp);

      // Delete every character, one by one.
      for (int i = 0; i < _helloWorldApp.length; i += 1) {
        await tester.pressBackspace();
      }

      // Ensure we deleted everything.
      expect(CodeEditorInspector.findContent(), "");

      // Expire pending timers.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgetsOnMac("can select all and delete hello world document", (tester) async {
      await _pumpScaffold(tester, code: _helloWorldApp);

      // Give focus to the editor.
      await tester.tap(find.byType(CodeEditor));

      // Ensure we're starting with full "hello, world" document.
      expect(CodeEditorInspector.findContent(), _helloWorldApp);

      // Select all.
      await tester.pressCmdA();

      // Delete the selection.
      await tester.pressBackspace();

      // Ensure we deleted everything.
      expect(CodeEditorInspector.findContent(), "");

      // Expire pending timers.
      await tester.pump(const Duration(seconds: 5));
    });
  });
}

const _writeHelloWorldApp = CodeEditorOperationList([
  TypeTextOperation("void main() {"),
  PressKeysOperation(LogicalKeyboardKey.enter),
  TypeTextOperation("  print('Hello, World!');"),
  PressKeysOperation(LogicalKeyboardKey.enter),
  TypeTextOperation("}"),
]);

const _helloWorldApp = '''
void main() {
  print('Hello, World!');
}''';

Future<void> _pumpScaffold(
  WidgetTester tester, {
  String code = "",
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DartEditor(
          initialCode: code,
        ),
      ),
    ),
  );
}
