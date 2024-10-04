import 'dart:io';

import 'package:example/ide/infrastructure/controls/toolbar_buttons.dart';
import 'package:example/ide/lsp/lsp_panel.dart';
import 'package:example/ide/workspace.dart';
import 'package:example/lsp_exploration/lsp/messages/did_open_text_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';

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
  bool _showRightPane = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: panelHighColor,
      body: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
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
              const BottomBar(),
            ],
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
  const BottomBar({super.key});

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
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("android_studio > lib > main.dart"),
            Spacer(),
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
    );
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
  double _desiredLeftPaneWidth = 450;

  double _desiredRightPaneWidth = 250;

  late final TreeController<EntityNode> _treeController;

  final _fileContent = ValueNotifier<String>("");

  @override
  void initState() {
    super.initState();
    final workspaceFiles = FileTree(EntityNode(
      widget.workspace.directory,
    ));

    _treeController = TreeController(
      roots: [
        workspaceFiles.root,
      ],
      defaultExpansionState: false,
      childrenProvider: (EntityNode node) => node.children,
    );
    _treeController.setExpansionState(workspaceFiles.root, true);
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
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: panelLowColor,
            child: _buildFileContent(),
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
            child: _buildRightPaneContent(),
          ),
      ],
    );
  }

  Widget _buildLeftPaneContent() {
    return AnimatedTreeView<EntityNode>(
      padding: const EdgeInsets.all(24),
      treeController: _treeController,
      nodeBuilder: (BuildContext context, TreeEntry<EntityNode> entry) {
        return InkWell(
          onTap: () {
            if (entry.node.isDirectory) {
              _treeController.toggleExpansion(entry.node);
              return;
            }

            final file = entry.node.entity as File;
            _fileContent.value = file.readAsStringSync();

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
          child: TreeIndentation(
            entry: entry,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(entry.node.title),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ValueListenableBuilder(
          valueListenable: _fileContent,
          builder: (context, value, child) {
            return Text(
              _fileContent.value,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Courier New',
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRightPaneContent() {
    return LspPanel(workspace: widget.workspace);
  }
}

class FileTree {
  final EntityNode root;

  FileTree(this.root) {
    root.buildChildren();
  }
}

class EntityNode {
  EntityNode(this.entity);

  final FileSystemEntity entity;

  bool get isDirectory => entity is Directory;

  String get title {
    final name = entity.uri.pathSegments.reversed.firstWhere((segment) => segment.trim().isNotEmpty);

    if (entity is Directory) {
      return "$name/";
    }

    return name;
  }

  List<EntityNode>? _children;
  Iterable<EntityNode> get children => _children ?? const [];

  void buildChildren() {
    if (entity is Directory) {
      final childEntities = (entity as Directory).listSync().map((entity) => EntityNode(entity)).toList();
      childEntities.sort((EntityNode a, EntityNode b) {
        if (a.entity is Directory && b.entity is! Directory) {
          return -1;
        }
        if (b.entity is Directory && a.entity is! Directory) {
          return 1;
        }

        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      _children = childEntities;

      for (final child in _children!) {
        child.buildChildren();
      }
    } else {
      _children = const [];
    }
  }

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EntityNode && runtimeType == other.runtimeType && entity == other.entity;

  @override
  int get hashCode => entity.hashCode;
}

const panelHighColor = Color(0xFF292D30);
const panelLowColor = Color(0xFF1C2022);
const dividerColor = Color(0xFF1C2022);
