import 'dart:io';

import 'package:example/ide/ide.dart';
import 'package:example/ide/workspace.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: _Screen(),
    ),
  );
}

class _Screen extends StatefulWidget {
  const _Screen();

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  final _workspace = Workspace(
    // Currently, the workspace directory is pulled from a variable defined by
    // the run command so that different developers can open up directories on
    // their respective machines.
    Directory(const String.fromEnvironment("CONTENT_DIRECTORY")),
  );

  @override
  Widget build(BuildContext context) {
    final path = const String.fromEnvironment("CONTENT_DIRECTORY");
    print('path: $path');
    return IDE(
      workspace: _workspace,
    );
  }
}
