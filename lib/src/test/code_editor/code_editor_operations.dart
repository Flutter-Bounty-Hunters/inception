import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor_test.dart';

class CodeEditorOperationList {
  const CodeEditorOperationList(this._operations);

  final List<CodeEditorOperation> _operations;

  Future<void> run(WidgetTester tester) async {
    for (final operation in _operations) {
      await operation.run(tester);
    }
  }
}

class TypeTextOperation implements CodeEditorOperation {
  const TypeTextOperation(this._text);

  final String _text;

  @override
  Future<void> run(WidgetTester tester) async {
    for (final character in _text.characters) {
      await tester.typeImeText(character);
    }
  }
}

class PressKeysOperation implements CodeEditorOperation {
  const PressKeysOperation.shift(this._key)
      : _pressShift = true,
        _pressMeta = false,
        _pressAltOption = false;

  const PressKeysOperation.cmd(this._key)
      : _pressMeta = true,
        _pressShift = false,
        _pressAltOption = false;

  const PressKeysOperation.alt(this._key)
      : _pressAltOption = true,
        _pressShift = false,
        _pressMeta = false;

  const PressKeysOperation(
    this._key, {
    bool pressShift = false,
    bool pressMeta = false,
    bool pressAltOption = false,
  })  : _pressShift = pressShift,
        _pressMeta = pressMeta,
        _pressAltOption = pressAltOption;

  final LogicalKeyboardKey _key;
  final bool _pressShift;
  final bool _pressMeta;
  final bool _pressAltOption;

  @override
  Future<void> run(WidgetTester tester) async {
    // Press down the modifier key(s).
    if (_pressShift) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    }
    if (_pressMeta) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    }
    if (_pressAltOption) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
    }

    // Press and release the primary key.
    await tester.sendKeyEvent(_key);

    // Release the modifier key(s).
    if (_pressShift) {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    }
    if (_pressMeta) {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    }
    if (_pressAltOption) {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
    }
  }
}

abstract class CodeEditorOperation {
  Future<void> run(WidgetTester tester);
}
