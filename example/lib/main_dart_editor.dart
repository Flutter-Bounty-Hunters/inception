import 'package:flutter/material.dart';
import 'package:inception/inception.dart';
import 'package:inception/language_dart.dart';

void main() {
  InceptionLog.initLoggers({
    InceptionLog.input,
  }, Level.ALL);

  runApp(const _DartEditorApp());
}

class _DartEditorApp extends StatefulWidget {
  const _DartEditorApp();

  @override
  State<_DartEditorApp> createState() => _DartEditorAppState();
}

class _DartEditorAppState extends State<_DartEditorApp> {
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
            const Expanded(
              child: DartEditor(),
            ),
          ],
        ),
      ),
    );
  }
}
