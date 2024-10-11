import 'dart:io';

import 'package:example/ide/editor/editor.dart';
import 'package:example/ide/file_explorer/file_explorer.dart';
import 'package:example/ide/infrastructure/controls/toolbar_buttons.dart';
import 'package:example/ide/lsp/lsp_panel.dart';
import 'package:example/ide/theme.dart';
import 'package:example/ide/workspace.dart';
import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:example/lsp_exploration/lsp/messages/common_types.dart';
import 'package:example/lsp_exploration/lsp/messages/did_open_text_document.dart';
import 'package:example/lsp_exploration/lsp/messages/initialize.dart';
import 'package:flutter/material.dart';

class IDE extends StatefulWidget {
  const IDE({
    super.key,
    required this.workspace,
  });

  final Workspace workspace;

  @override
  State<IDE> createState() => _IDEState();
}

class _IDEState extends State<IDE> {
  bool _showLeftPane = true;
  bool _showRightPane = false;

  @override
  void initState() {
    super.initState();
    _initLspClient();
  }

  Future<void> _initLspClient() async {
    await widget.workspace.lspClient.start();

    await widget.workspace.lspClient.initialize(
      InitializeParams(
        rootUri: 'file://${widget.workspace.directory.absolute.path}',
        capabilities: LspClientCapabilities(),
      ),
    );

    await widget.workspace.lspClient.initialized();
  }

  Future<void> _restartLspClient() async {
    widget.workspace.lspClient.stop();

    await _initLspClient();
  }

  Future<void> _stopLspClient() async {
    widget.workspace.lspClient.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: panelHighColor,
      body: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
        ),
        child: IconTheme(
          data: const IconThemeData(
            color: Colors.white,
          ),
          child: Center(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Row(
                    children: [
                      const LeftBar(),
                      Expanded(
                        child: ContentArea(
                          workspace: widget.workspace,
                          showLeftPane: _showLeftPane,
                          showRightPane: _showRightPane,
                        ),
                      ),
                      const RightBar(),
                    ],
                  ),
                ),
                BottomBar(
                  lspClient: widget.workspace.lspClient,
                  onLspRestartPressed: _restartLspClient,
                  onLspStopPressed: _stopLspClient,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: dividerColor),
        ),
      ),
    );
  }
}

class LeftBar extends StatelessWidget {
  const LeftBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: dividerColor),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          TriStateIconButton(
            icon: Icons.folder_open,
            iconColor: Colors.white,
            iconSize: 20,
            onPressed: () {},
          ),
          TriStateIconButton(
            icon: Icons.commit,
            iconColor: Colors.white,
            iconSize: 20,
            onPressed: () {},
          ),
          TriStateIconButton(
            icon: Icons.merge,
            iconColor: Colors.white,
            iconSize: 20,
            onPressed: () {},
          ),
          TriStateIconButton(
            icon: Icons.more_horiz,
            iconColor: Colors.white,
            iconSize: 20,
            onPressed: () {},
          ),
          const Spacer(),
          TriStateIconButton(
            icon: Icons.play_arrow_outlined,
            iconColor: Colors.white,
            iconSize: 20,
            onPressed: () {},
          ),
          TriStateIconButton(
            icon: Icons.error_outline,
            iconColor: Colors.white,
            iconSize: 20,
            onPressed: () {},
          ),
          TriStateIconButton(
            icon: Icons.terminal,
            iconColor: Colors.white,
            iconSize: 20,
            onPressed: () {},
          ),
          TriStateIconButton(
            icon: Icons.merge,
            iconColor: Colors.white,
            iconSize: 20,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class RightBar extends StatelessWidget {
  const RightBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: dividerColor),
        ),
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.lspClient,
    required this.onLspRestartPressed,
    required this.onLspStopPressed,
  });

  final LspClient lspClient;
  final VoidCallback onLspRestartPressed;
  final VoidCallback onLspStopPressed;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style.copyWith(
            color: Colors.white.withOpacity(0.4),
          ),
      child: Container(
        height: 30,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: dividerColor),
          ),
        ),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text("android_studio > lib > main.dart"),
            ),
            _buildLspControls(),
            const Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("119:22"),
                  SizedBox(width: 16),
                  Text("LF"),
                  SizedBox(width: 16),
                  Text("UTF-8"),
                  SizedBox(width: 16),
                  Icon(Icons.warning_amber, size: 14),
                  SizedBox(width: 16),
                  Text("2 spaces"),
                  SizedBox(width: 16),
                  Icon(Icons.lock_open_sharp, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLspControls() {
    return ListenableBuilder(
      listenable: lspClient,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("LSP: $_lspClientStatus"),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onLspRestartPressed,
              child: const Icon(
                Icons.refresh,
                size: 14,
                color: Colors.lightBlueAccent,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onLspStopPressed,
              child: const Icon(
                Icons.stop,
                size: 14,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  String get _lspClientStatus {
    switch (lspClient.status) {
      case LspClientStatus.notRunning:
        return "Not Running";
      case LspClientStatus.starting:
        return "Starting";
      case LspClientStatus.started:
        return "Started";
      case LspClientStatus.initializing:
        return "Initializing";
      case LspClientStatus.initialized:
        return "Initialized";
    }
  }
}

class ContentArea extends StatefulWidget {
  const ContentArea({
    super.key,
    required this.workspace,
    required this.showLeftPane,
    required this.showRightPane,
  });

  final Workspace workspace;

  final bool showLeftPane;
  final bool showRightPane;

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  double _desiredLeftPaneWidth = 350;

  double _desiredRightPaneWidth = 250;

  final _fileContent = ValueNotifier<String>("");
  final _currentFile = ValueNotifier<File?>(null);

  void _onGoToDefinition(String uri, Range range) {
    _currentFile.value = File.fromUri(Uri.parse(uri));
  }

  // When sufficient space:
  //  1. Take up all desired space for left pane and right pane (e.g., project explorer, device manager).
  //  2. Take up remaining space with tabs + code editor.
  //
  // When insufficient space:
  //  1. Take up minimum width for tabs + code editor.
  //  2. Split remaining space proportionally between the left/right pane
  //     based on their desired pixel width.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (widget.showLeftPane)
          Container(
            width: _desiredLeftPaneWidth,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: dividerColor),
              ),
            ),
            child: FileExplorer(
              directory: widget.workspace.directory,
              onFileOpenRequested: (file) {
                _fileContent.value = file.readAsStringSync();
                _currentFile.value = file;

                String languageId = "dart";
                if (file.path.endsWith(".md")) {
                  languageId = "markdown";
                } else if (file.path.endsWith(".yaml")) {
                  languageId = "yaml";
                }

                widget.workspace.lspClient.didOpenTextDocument(
                  DidOpenTextDocumentParams(
                    textDocument: TextDocumentItem(
                      uri: "file://${file.path}",
                      languageId: languageId,
                      version: 1,
                      text: file.readAsStringSync(),
                    ),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: panelLowColor,
            child: ValueListenableBuilder(
              valueListenable: _currentFile,
              builder: (context, child, value) {
                return IdeEditor(
                  lspClient: widget.workspace.lspClient,
                  sourceFile: _currentFile.value,
                  onGoToDefinition: _onGoToDefinition,
                );
              },
            ),
          ),
        ),
        if (widget.showRightPane)
          Container(
            width: _desiredRightPaneWidth,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: dividerColor),
              ),
            ),
            child: const SizedBox(),
          ),
      ],
    );
  }
}
