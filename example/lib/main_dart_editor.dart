import 'package:flutter/material.dart';
import 'package:inception/inception.dart';
import 'package:inception/language_dart.dart';
import 'package:super_text_layout/super_text_layout.dart';

void main() {
  InceptionLog.initLoggers({
    InceptionLog.input,
  }, Level.OFF);

  runApp(const _DartEditorApp());
}

class _DartEditorApp extends StatefulWidget {
  const _DartEditorApp();

  @override
  State<_DartEditorApp> createState() => _DartEditorAppState();
}

class _DartEditorAppState extends State<_DartEditorApp> {
  TextEditingValue? _codeEditorImeValue;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        body: Column(
          children: [
            Container(
              height: 56,
              color: const Color(0xFF222222),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildEditor(),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _buildDebugBar(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return DartEditor(
      initialCode: _helloWorldApp,
      debugOnImeChange: (newImeValue) => setState(() {
        _codeEditorImeValue = newImeValue;
      }),
    );
  }

  Widget _buildDebugBar() {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: "SourceCodePro",
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text(
              "IME >|",
              style: TextStyle(
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SuperTextWithSelection.single(
                richText: TextSpan(
                  text: _codeEditorImeValue?.text ?? "",
                  style: const TextStyle(
                    fontFamily: "SourceCodePro",
                    letterSpacing: 1,
                  ),
                ),
                userSelection: _codeEditorImeValue?.selection.isValid == true
                    ? UserSelection(
                        selection: _codeEditorImeValue!.selection,
                        caretStyle: const CaretStyle(color: Colors.yellow),
                        highlightStyle: const SelectionHighlightStyle(
                          color: Color(0xFF444400),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _helloWorldApp = '''
void main() {
  print("Hello, world!");
}''';
