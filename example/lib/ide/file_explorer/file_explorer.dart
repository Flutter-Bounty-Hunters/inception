import 'dart:io';
import 'dart:math';

import 'package:example/ide/ide.dart';
import 'package:example/ide/infrastructure/user_settings.dart';
import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:path/path.dart' as path;

import '../../lsp_exploration/lsp/messages/rename_files_params.dart';

// TODO:
//  - switch from single, double tap recognizers to multi-tap to get rid of selection delay
//  - make background a rounded rectangle to match AS
//  - find better icons

// Annoyances:
// - The TreeView is typed to content, rather than typed to the node type, so you can't
//   use a subclass of TreeViewNode.
// - I think the gesture detector in the tree view is on top of its content - I'm noticing
//   that our tap detector on the chevron widget is still triggering the gesture recognizer
//   for the tree view, even though I set the chevron hit test to opaque. This results in
//   a delay running the single tap callback for the chevron icon, and also causes that list
//   item to be selected just because the user tapped on the chevron.
// - Expansion and collapse animations seem to be equal timing no matter the size of the
//   subtree that's being expanded. This results in a sudden appearance for large subtrees.
// - There's no padding property on the TreeView. To add padding at the top and bottom, we have
//   to create an ugly clip boundary because we're forced to add the padding around the TreeView
//   instead of inside it.

/// An expandable/collapsible tree view of a file system under a given [directory].
class FileExplorer extends StatefulWidget {
  const FileExplorer({
    super.key,
    required this.directory,
    required this.onFileOpenRequested,
    required this.lspClient,
  });

  final Directory directory;
  final LspClient lspClient;

  final void Function(File) onFileOpenRequested;

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  @visibleForTesting
  final TreeViewController treeController = TreeViewController();

  @visibleForTesting
  final ScrollController verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  late final List<FileSystemEntityTreeViewNode> _tree;
  FileSystemEntityTreeViewNode? _selectedNode;

  final FocusNode _treeRowFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _tree = _createTreeFromDirectory(widget.directory);
  }

  List<FileSystemEntityTreeViewNode> _createTreeFromDirectory(Directory directory) {
    final tree = <FileSystemEntityTreeViewNode>[];
    _doRecursiveCreateTreeFromDirectory(tree, directory);
    return tree;
  }

  void _doRecursiveCreateTreeFromDirectory(List<FileSystemEntityTreeViewNode> tree, Directory directory) {
    final childEntities = directory.listSync().toList();
    childEntities.sort((FileSystemEntity a, FileSystemEntity b) {
      if (a is Directory && b is! Directory) {
        return -1;
      }
      if (b is Directory && a is! Directory) {
        return 1;
      }

      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });

    for (final entity in childEntities) {
      List<FileSystemEntityTreeViewNode>? children;
      if (entity is Directory) {
        children = [];
        _doRecursiveCreateTreeFromDirectory(children, entity);
      }

      tree.add(
        FileSystemEntityTreeViewNode(
          entity,
          children: children,
        ),
      );
    }
  }

  Future<void> _renameFile(BuildContext context, String currentFilePath) async {
    final String? newFileName = await showDialog<String>(
        context: context,
        builder: (context) {
          return const RenameFileDialog();
        });

    if (newFileName == null) {
      return;
    }

    final newFilePath = path.join(path.dirname(currentFilePath), "$newFileName${path.extension(currentFilePath)}");

    final params = RenameFilesParams(
      files: [
        FileRename(
          oldUri: "file://$currentFilePath",
          newUri: "file://$newFilePath",
          // TODO: Create a object to serialize the file path as understood by the LSP. Eg. file://$root/example/lib/ide/idea.dart
        ),
      ],
    );

    await widget.lspClient.willRenameFiles(params);

    // TODO: modify names, apply changes.

    await widget.lspClient.didRenameFiles(params);
  }

  static const _rowHeight = 28.0;

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: const IconThemeData(
        color: Colors.white,
      ),
      child: ScrollConfiguration(
        // Clamp scrolling because bouncy overscroll looks weird in the file explorer.
        behavior: _ClampedScrolling(),
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          child: Scrollbar(
            controller: verticalController,
            thumbVisibility: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: TreeView<FileSystemEntity>(
                controller: treeController,
                verticalDetails: ScrollableDetails.vertical(
                  controller: verticalController,
                ),
                horizontalDetails: ScrollableDetails.horizontal(
                  controller: _horizontalController,
                ),
                // No internal indentation, the custom treeNodeBuilder applies its
                // own indentation to decorate in the indented space.
                indentation: TreeViewIndentationType.none,
                tree: _tree,
                onNodeToggle: (TreeViewNode<FileSystemEntity> node) {
                  setState(() {
                    _selectedNode = node;
                  });
                },
                treeNodeBuilder: _treeNodeBuilder,
                treeRowBuilder: (FileSystemEntityTreeViewNode node) {
                  if (_selectedNode == node) {
                    return TreeRow(
                      extent: const FixedTreeRowExtent(
                        _rowHeight,
                      ),
                      recognizerFactories: _getTapRecognizer(node),
                      backgroundDecoration: TreeRowDecoration(
                        // color: Colors.amber[100],
                        color: Colors.white.withOpacity(0.1),
                      ),
                    );
                  }
                  return TreeRow(
                    extent: const FixedTreeRowExtent(
                      _rowHeight,
                    ),
                    recognizerFactories: _getTapRecognizer(node),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _treeNodeBuilder(
    BuildContext context,
    FileSystemEntityTreeViewNode node,
    AnimationStyle toggleAnimationStyle,
  ) {
    final bool isParentNode = node.children.isNotEmpty;

    // TRY THIS: TreeView.toggleNodeWith can be wrapped around any Widget (even
    // the whole row) to trigger parent nodes to toggle opened and closed.
    // Currently, the toggle is triggered in _getTapRecognizer below using the
    // TreeViewController.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Custom indentation
        SizedBox(width: 24.0 * node.depth! + 8.0),
        // Leading icon for parent nodes
        SizedBox(
          width: 24,
          child: isParentNode
              ? //
              GestureDetector(
                  onTap: () {
                    node.isExpanded //
                        ? treeController.collapseNode(node)
                        : treeController.expandNode(node);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Transform.rotate(
                    angle: node.isExpanded ? pi / 2 : 0,
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: IconTheme.of(context).color!.withOpacity(0.25),
                    ),
                  ),
                )
              : null,
        ),
        // Spacer
        const SizedBox(width: 4.0),
        // Content
        Center(
          child: KeyboardListener(
            focusNode: _treeRowFocusNode,
            onKeyEvent: (value) {
              if (value.logicalKey == LogicalKeyboardKey.enter) {
                if (node.isFile) {
                  _renameFile(context, _selectedNode!.asFile.path);
                }
              }
            },
            child: Row(
              children: [
                _getIconForNode(node),
                const SizedBox(width: 8),
                Text(
                  node.title,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _getIconForNode(FileSystemEntityTreeViewNode node) {
    if (node.isFile && node.title.endsWith(".dart")) {
      return Image.asset(
        "assets/images/icons/dart_logo.png",
        width: 14,
      );
    }

    if (node.isFile && node.title.endsWith(".md")) {
      return Image.asset(
        "assets/images/icons/markdown_logo.png",
        width: 14,
      );
    }

    return Icon(
      node.children.isNotEmpty ? Icons.folder_open : Icons.format_align_left,
      size: 14,
    );
  }

  Map<Type, GestureRecognizerFactory> _getTapRecognizer(
    FileSystemEntityTreeViewNode node,
  ) {
    return <Type, GestureRecognizerFactory>{
      TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(),
        (TapGestureRecognizer t) => t.onTap = () {
          // Open document.
          setState(() {
            _selectedNode = node;
            _treeRowFocusNode.requestFocus();
          });

          if (node.isFile) {
            // Open document.
            widget.onFileOpenRequested(node.asFile);
          }
        },
      ),
      DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
        () => DoubleTapGestureRecognizer(),
        (DoubleTapGestureRecognizer t) => t.onDoubleTap = () {
          if (node.isDirectory) {
            setState(() {
              // Toggle directory.
              treeController.toggleNode(node);
            });
            return;
          }

          // Select the node.
          setState(() {
            _selectedNode = node;
          });

          // Open document.
          widget.onFileOpenRequested(node.asFile);
        },
      ),
    };
  }
}

typedef FileSystemEntityTreeViewNode = TreeViewNode<FileSystemEntity>;

extension on FileSystemEntityTreeViewNode {
  String get title {
    final name = content.uri.pathSegments.reversed.where((segment) => segment.trim().isNotEmpty).firstOrNull;
    if (name == null) {
      return "";
    }

    if (isDirectory) {
      return "$name/";
    }

    return name;
  }

  bool get isDirectory => content is Directory;

  Directory get asDirectory => content as Directory;

  bool get hasChildren => asDirectory.listSync().isNotEmpty;

  bool get isFile => content is File;

  File get asFile => content as File;
}

class _ClampedScrolling extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
