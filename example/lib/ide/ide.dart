import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:example/ide/infrastructure/controls/toolbar_buttons.dart';
import 'package:example/ide/lsp/lsp_panel.dart';
import 'package:example/ide/workspace.dart';
import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:example/lsp_exploration/lsp/messages/common_types.dart';
import 'package:example/lsp_exploration/lsp/messages/did_open_text_document.dart';
import 'package:example/lsp_exploration/lsp/messages/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:path/path.dart' as path;
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

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
  final _currentFile = ValueNotifier<File?>(null);

  final _textKey = GlobalKey();

  Timer? _hoverTimer;

  /// Shows/hides the overlay that displays information about the hovered text.
  final _hoverOverlayController = OverlayPortalController();

  /// The document to display in the hover overlay.
  final _hoverPopoverDocument = ValueNotifier<Document>(MutableDocument());

  /// The rect of the word that is currently being hovered.
  final _hoveredFocalPoint = ValueNotifier<Rect?>(null);

  /// Link to display a popover near to the focal point.
  final _hoverLink = LeaderLink();

  int? _latestHoveredTextOffset;

  Highlighter? _highlighter;

  double _fontSize = 24;

  final _focusNode = FocusNode();

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

    _initializeSyntaxHighlighting();
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeSyntaxHighlighting() async {
    await Highlighter.initialize(['dart', 'yaml']);

    var theme = await HighlighterTheme.loadDarkTheme();

    _highlighter = Highlighter(
      language: 'dart',
      theme: theme,
    );
  }

  Future<void> _hoverAtTextOffset(int offset) async {
    final text = _fileContent.value;

    if (_shouldAbortCurrentHoverRequest(offset)) {
      return;
    }

    final (line, character) = _getLineAndCharacterForOffset(text, offset);

    final filePath = _currentFile.value!.isAbsolute //
        ? _currentFile.value!.path
        : path.absolute(_currentFile.value!.path);

    final res = await widget.workspace.lspClient.hover(
      HoverParams(
        textDocument: TextDocumentIdentifier(
          uri: "file://$filePath",
        ),
        position: Position(
          line: line,
          character: character,
        ),
      ),
    );

    if (res == null) {
      return;
    }

    if (_shouldAbortCurrentHoverRequest(offset)) {
      return;
    }

    // TODO: see if we can declare contents as string in the Hover class.
    final context = res.contents as String;

    _hoverPopoverDocument.value = deserializeMarkdownToDocument(
      context,
      encodeHtml: true,
    );

    if (context.isEmpty) {
      if (_hoverOverlayController.isShowing) {
        _hoverOverlayController.hide();
      }
      return;
    }

    if (!_hoverOverlayController.isShowing) {
      _hoverOverlayController.show();
    }
  }

  (int line, int character) _getLineAndCharacterForOffset(String text, int offset) {
    if (text.isEmpty) {
      return (0, 0);
    }

    int lineNumber = 0;
    int charNumberInLine = 0;

    int currentOffset = 0;

    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final lineLength = lines[i].length;

      if (currentOffset + lineLength >= offset) {
        charNumberInLine = offset - currentOffset;
        lineNumber = i;
        break;
      }

      currentOffset += lineLength + 1;
    }

    return (lineNumber, charNumberInLine);
  }

  void _onHover(PointerHoverEvent event) {
    if (widget.workspace.lspClient.status != LspClientStatus.initialized) {
      return;
    }

    final openedFile = _currentFile.value;
    if (openedFile == null) {
      _hoverOverlayController.hide();
      return;
    }

    if (_fileContent.value.isEmpty) {
      _hoverOverlayController.hide();
      return;
    }

    final renderParagraph = _textKey.currentContext?.findRenderObject() as RenderParagraph?;
    if (renderParagraph == null) {
      _hoverOverlayController.hide();
      return;
    }

    final localPosition = renderParagraph.globalToLocal(event.position);
    final textPosition = renderParagraph.getPositionForOffset(localPosition);
    if (textPosition.offset < 0) {
      _hoverOverlayController.hide();
      return;
    }

    final wordRange = renderParagraph.getWordBoundary(textPosition);
    final boxes = renderParagraph.getBoxesForSelection(
      TextSelection(
        baseOffset: wordRange.start,
        extentOffset: wordRange.end,
      ),
      boxHeightStyle: BoxHeightStyle.max,
      boxWidthStyle: BoxWidthStyle.max,
    );

    if (boxes.isNotEmpty) {
      final newFocalPoint = boxes.first.toRect();
      if (newFocalPoint != _hoveredFocalPoint.value) {
        // We are now hovering another word. Hide the overlay, it will be shown again after
        // querying the new hover popover text.
        _hoverOverlayController.hide();
      }

      _hoveredFocalPoint.value = newFocalPoint;
    }

    _latestHoveredTextOffset = textPosition.offset;

    _hoverTimer?.cancel();
    _hoverTimer = Timer(
      const Duration(milliseconds: 500),
      () => _hoverAtTextOffset(textPosition.offset),
    );
  }

  bool _shouldAbortCurrentHoverRequest(int hoveredTextOffset) {
    if (!mounted) {
      return true;
    }

    if (_currentFile.value == null) {
      // There isn't any opened file to hover on.
      return true;
    }

    if (hoveredTextOffset != _latestHoveredTextOffset) {
      // The user hovered another position while the hover request was happening. Ignore the results,
      // because a new request will happen.
      return true;
    }

    return false;
  }

  int _computeFontIncrement() {
    return switch (_fontSize) {
      <= 24 => 1,
      <= 48 => 2,
      <= 96 => 3,
      _ => 4,
    };
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
    return Actions(
      actions: {
        IncreaseFontSizeIntent: CallbackAction<IncreaseFontSizeIntent>(
          onInvoke: (intent) => setState(() {
            _fontSize += _computeFontIncrement();
          }),
        ),
        DecreaseFontSizeIntent: CallbackAction<DecreaseFontSizeIntent>(
          onInvoke: (intent) => setState(() {
            _fontSize = max(_fontSize - _computeFontIncrement(), 8);
          }),
        ),
      },
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.equal): const IncreaseFontSizeIntent(),
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.minus): const DecreaseFontSizeIntent(),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ValueListenableBuilder(
                valueListenable: _fileContent,
                builder: (context, value, child) {
                  if (_highlighter == null) {
                    return const SizedBox();
                  }

                  final highlightedCode = _highlighter!.highlight(_fileContent.value);

                  return MouseRegion(
                    cursor: SystemMouseCursors.text,
                    onHover: _onHover,
                    onExit: (event) => _hoverOverlayController.hide(),
                    child: OverlayPortal(
                      controller: _hoverOverlayController,
                      overlayChildBuilder: (context) => _buildHoverOverlay(),
                      child: Stack(
                        children: [
                          ValueListenableBuilder(
                            valueListenable: _hoveredFocalPoint,
                            builder: (context, value, child) {
                              if (value == null) {
                                return const SizedBox();
                              }

                              return Positioned(
                                top: _hoveredFocalPoint.value!.top,
                                left: _hoveredFocalPoint.value!.left,
                                child: Leader(
                                  link: _hoverLink,
                                  child: SizedBox(
                                    width: _hoveredFocalPoint.value!.width,
                                    height: _hoveredFocalPoint.value!.height,
                                  ),
                                ),
                              );
                            },
                          ),
                          Text.rich(
                            highlightedCode,
                            key: _textKey,
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightPaneContent() {
    return LspPanel(workspace: widget.workspace);
  }

  Widget _buildHoverOverlay() {
    return Follower.withOffset(
      link: _hoverLink,
      leaderAnchor: Alignment.topCenter,
      followerAnchor: Alignment.bottomCenter,
      offset: const Offset(0, -20),
      child: Container(
        height: 300,
        width: 500,
        decoration: BoxDecoration(
          color: panelHighColor,
          border: Border.all(color: Colors.white),
        ),
        child: CustomScrollView(
          slivers: [
            ValueListenableBuilder(
              valueListenable: _hoverPopoverDocument,
              builder: (context, document, child) {
                return SuperReader(
                  document: document,
                  stylesheet: defaultStylesheet.copyWith(addRulesAfter: [..._darkModeStyles]),
                );
              },
            ),
          ],
        ),
      ),
    );
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
    final name = entity.uri.pathSegments.reversed.where((segment) => segment.trim().isNotEmpty).firstOrNull;
    if (name == null) {
      return "";
    }
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

// Makes text light, for use during dark mode styling.
final _darkModeStyles = [
  StyleRule(
    BlockSelector.all,
    (doc, docNode) {
      return {
        Styles.textStyle: const TextStyle(
          fontSize: 18,
          fontFamily: 'Courier New',
          color: Colors.white,
        ),
      };
    },
  ),
];

class IncreaseFontSizeIntent extends Intent {
  const IncreaseFontSizeIntent();
}

class DecreaseFontSizeIntent extends Intent {
  const DecreaseFontSizeIntent();
}
