import 'dart:io';
import 'dart:ui';

import 'package:example/ide/ide.dart';
import 'package:example/ide/infrastructure/user_settings.dart';
import 'package:example/ide/workspace.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      home: const _Screen(),
    ),
  );
}

enum SetupState {
  start,
  noValidDirectory,
  showIde,
}

class _Screen extends StatefulWidget {
  const _Screen();

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  late final Workspace _workspace;

  final setupNotifier = ValueNotifier(SetupState.start);

  @override
  void initState() {
    super.initState();
    _setupWorkspace();
  }

  Future<void> _setupWorkspace() async {
    final settings = UserSettings();
    await settings.init();
    var path = settings.contentDirectory;
    print('PATH: $path');
    path ??= await FilePicker.platform.getDirectoryPath();
    if (path == null) {
      setupNotifier.value = SetupState.noValidDirectory;
      return;
    }
    settings.setContentDirectory(path);
    _workspace = Workspace(
      Directory(path),
    );
    setupNotifier.value = SetupState.showIde;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SetupState>(
      valueListenable: setupNotifier,
      builder: (context, setupState, child) {
        switch (setupState) {
          case SetupState.start:
            return const Placeholder();
          case SetupState.noValidDirectory:
            return const Center(
              child: Text("No valid directory selected"),
            );
          case SetupState.showIde:
            return IDE(
              workspace: _workspace,
            );
        }
      },
    );
  }
}
