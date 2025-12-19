import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inception/inception.dart';
import 'package:super_editor/super_editor.dart';

/// A popover that displays a list, and responds to key presses to navigate
/// and select an item from the list.
class PopoverList extends StatefulWidget {
  const PopoverList({
    super.key,
    required this.editorFocusNode,
    required this.listItems,
    required this.onListItemSelected,
    required this.onCancelRequested,
  });

  /// [FocusNode] attached to the editor, which is expected to be an ancestor
  /// of this widget.
  final FocusNode editorFocusNode;

  /// The items displayed in this popover list.
  final List<PopoverListItem> listItems;

  /// Callback that's executed when the user selects a highlighted list item,
  /// e.g., by pressing ENTER.
  final void Function(Object id) onListItemSelected;

  /// Callback that's executed when the user indicates the desire to cancel
  /// interaction, e.g., by pressing ESCAPE.
  final VoidCallback onCancelRequested;

  @override
  State<PopoverList> createState() => _PopoverListState();
}

class _PopoverListState extends State<PopoverList> {
  late final FocusNode _focusNode;

  final _listKey = GlobalKey<ScrollableState>();
  late final ScrollController _scrollController;
  int _selectedValueIndex = 0;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Wait until next frame to request focus, so that the parent relationship
      // can be established between our focus node and the editor focus node.
      _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(PopoverList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.listItems.length != oldWidget.listItems.length) {
      // Make sure that the user's selection index remains in bound, even when
      // the list items are switched out.
      _selectedValueIndex = min(_selectedValueIndex, widget.listItems.length - 1);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final reservedKeys = {
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.numpadEnter,
      LogicalKeyboardKey.escape,
    };

    final key = event.logicalKey;
    if (!reservedKeys.contains(key)) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      // Only handle up events, so we don't run our behavior twice
      // for the same key press.
      return KeyEventResult.handled;
    }

    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        if (_selectedValueIndex > 0) {
          setState(() {
            // TODO: auto-scroll to new position
            _selectedValueIndex -= 1;
          });
        }
      case LogicalKeyboardKey.arrowDown:
        if (_selectedValueIndex < widget.listItems.length - 1) {
          setState(() {
            // TODO: auto-scroll to new position
            _selectedValueIndex += 1;
          });
        }
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        widget.onListItemSelected(widget.listItems[_selectedValueIndex].id);
      case LogicalKeyboardKey.escape:
        widget.onCancelRequested();
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return SuperEditorPopover(
      popoverFocusNode: _focusNode,
      editorFocusNode: widget.editorFocusNode,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        onTap: () => !_focusNode.hasPrimaryFocus ? _focusNode.requestFocus() : null,
        child: ListenableBuilder(
          listenable: _focusNode,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: popoverBackgroundColor,
                border: Border.all(color: popoverBorderColor),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    offset: Offset.zero,
                    blurRadius: 3,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  BoxShadow(
                    offset: const Offset(0, 12),
                    blurRadius: 16,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
              child: _buildContent(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return widget.listItems.isNotEmpty //
        ? _buildList()
        : _buildEmptyDisplay();
  }

  Widget _buildList() {
    return SingleChildScrollView(
      key: _listKey,
      controller: _scrollController,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            for (int i = 0; i < widget.listItems.length; i += 1) ...[
              ColoredBox(
                color: i == _selectedValueIndex && _focusNode.hasPrimaryFocus
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.listItems[i].icon != null) widget.listItems[i].icon!,
                      const SizedBox(width: 8),
                      Text(
                        widget.listItems[i].label,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDisplay() {
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          "NO ACTIONS",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class PopoverListItem {
  const PopoverListItem({
    required this.id,
    required this.label,
    this.icon,
  });

  final Object id;
  final String label;
  final Icon? icon;
}
