import 'dart:io';

import 'package:example/ide/editor/editor.dart';
import 'package:example/ide/file_explorer/file_explorer.dart';
import 'package:example/ide/infrastructure/controls/toolbar_buttons.dart';
import 'package:example/ide/infrastructure/user_settings.dart';
import 'package:example/ide/problems_panel/problems_panel.dart';
import 'package:example/ide/testing/test_panel.dart';
import 'package:example/ide/theme.dart';
import 'package:example/ide/workspace.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inception/inception.dart';

import 'package:path/path.dart' as path;

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
  // ignore: prefer_final_fields
  bool _showLeftPane = true;
  bool _isAnalyzing = false;
  LeftPaneContent _leftPaneContent = LeftPaneContent.fileExplorer;

  String? currentFile;

  @override
  void initState() {
    super.initState();
    _initLspClient();
  }

  @override
  void dispose() {
    widget.workspace.lspClient.removeNotificationListener(_lspNotificationListener);

    super.dispose();
  }

  Future<void> _initLspClient() async {
    await widget.workspace.lspClient.start();

    widget.workspace.lspClient.addNotificationListener(_lspNotificationListener);

    await widget.workspace.lspClient.initialize(
      InitializeParams(
          processId: pid,
          rootUri: 'file://${widget.workspace.directory.absolute.path}',
          capabilities: LspClientCapabilities(),
          initializationOptions: {
            'outline': true,
          }),
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

  void _lspNotificationListener(LspNotification notification) {
    final method = notification.method;

    if (method != r"$/analyzerStatus") {
      return;
    }

    setState(() {
      _isAnalyzing = notification.params["isAnalyzing"] as bool;
    });
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
                      LeftBar(
                        onFileExplorerPressed: () => setState(() {
                          _leftPaneContent = LeftPaneContent.fileExplorer;
                        }),
                        onTestsPressed: () => setState(() {
                          _leftPaneContent = LeftPaneContent.tests;
                        }),
                      ),
                      Expanded(
                        child: ContentArea(
                          workspace: widget.workspace,
                          showLeftPane: _showLeftPane,
                          leftPaneContent: _leftPaneContent,
                          showRightPane: true,
                          onFileOpen: (value) {
                            setState(() {
                              currentFile = value;
                            });
                          },
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
                  isAnalyzing: _isAnalyzing,
                  currentFilePath: currentFile,
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
  const LeftBar({
    super.key,
    required this.onFileExplorerPressed,
    required this.onTestsPressed,
  });

  final VoidCallback onFileExplorerPressed;
  final VoidCallback onTestsPressed;

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
            onPressed: onFileExplorerPressed,
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
            icon: Icons.science_outlined,
            iconColor: Colors.white,
            iconSize: 20,
            onPressed: onTestsPressed,
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
    required this.isAnalyzing,
    this.currentFilePath,
  });

  final LspClient lspClient;
  final VoidCallback onLspRestartPressed;
  final VoidCallback onLspStopPressed;
  final bool isAnalyzing;
  final String? currentFilePath;

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
            const SizedBox(width: 8),
            // This is here to experiment with the LspClient
            const Icon(
              Icons.science_outlined,
              size: 14,
              color: Colors.lightBlueAccent,
            ),
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
            const SizedBox(width: 10),
            Text(isAnalyzing ? "Analyzing..." : "LSP Analyzed"),
            const SizedBox(width: 8),
            if (isAnalyzing)
              const AspectRatio(
                aspectRatio: 1.0,
                child: CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 8,
                ),
              )
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

class RenameFileDialog extends StatefulWidget {
  const RenameFileDialog({
    super.key,
  });

  @override
  State<RenameFileDialog> createState() => _RenameFileDialogState();
}

class _RenameFileDialogState extends State<RenameFileDialog> {
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("Rename file"),
      children: [
        TextField(
          controller: textEditingController,
          decoration: const InputDecoration(
            labelText: "New file name",
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(textEditingController.text);
              },
              child: const Text("Rename"),
            ),
          ],
        ),
      ],
    );
  }
}

class ContentArea extends StatefulWidget {
  const ContentArea({
    super.key,
    required this.workspace,
    required this.showLeftPane,
    this.leftPaneContent = LeftPaneContent.fileExplorer,
    required this.showRightPane,
    required this.onFileOpen,
  });

  final Workspace workspace;

  final bool showLeftPane;
  final LeftPaneContent leftPaneContent;
  final bool showRightPane;
  final Function(String documentUrl) onFileOpen;

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  // ignore: prefer_final_fields
  double _desiredLeftPaneWidth = 350;

  // ignore: prefer_final_fields
  double _desiredBottomPaneHeight = 200;

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
            child: _buildLeftPaneContent(),
          ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: _currentFile,
            builder: (context, child, value) {
              return Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: panelLowColor,
                      child: IdeEditor(
                        lspClient: widget.workspace.lspClient,
                        sourceFile: _currentFile.value,
                        onGoToDefinition: _onGoToDefinition,
                      ),
                    ),
                  ),
                  Container(
                    height: _desiredBottomPaneHeight,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: dividerColor),
                      ),
                    ),
                    child: ProblemsPanel(
                      lspClient: widget.workspace.lspClient,
                      sourceFile: _currentFile.value,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPaneContent() {
    return switch (widget.leftPaneContent) {
      LeftPaneContent.fileExplorer => _buildFileExplorer(),
      LeftPaneContent.tests => _buildTestPanel(),
    };
  }

  Widget _buildFileExplorer() {
    return FileExplorer(
      lspClient: widget.workspace.lspClient,
      directory: widget.workspace.directory,
      onFileOpenRequested: (file) async {
        _fileContent.value = file.readAsStringSync();
        _currentFile.value = file;

        String languageId = "dart";
        if (file.path.endsWith(".md")) {
          languageId = "markdown";
        } else if (file.path.endsWith(".yaml")) {
          languageId = "yaml";
        }

        await widget.workspace.lspClient.didOpenTextDocument(
          DidOpenTextDocumentParams(
            textDocument: TextDocumentItem(
              uri: "file://${file.absolute.path}",
              languageId: languageId,
              version: 1,
              text: file.readAsStringSync(),
            ),
          ),
        );

        widget.onFileOpen(_currentFile.value!.path);
      },
    );
  }

  Widget _buildTestPanel() {
    return TestPanel(
      workspace: widget.workspace,
    );
  }
}

enum LeftPaneContent {
  fileExplorer,
  tests,
}
