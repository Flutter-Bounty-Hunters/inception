import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:example/ide/editor/code_layout.dart';
import 'package:example/ide/editor/syntax_highlighting.dart';
import 'package:example/ide/infrastructure/keyboard_shortcuts.dart';
import 'package:example/ide/infrastructure/popover_list.dart';
import 'package:example/ide/theme.dart';
import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:example/lsp_exploration/lsp/messages/code_actions.dart';
import 'package:example/lsp_exploration/lsp/messages/common_types.dart';
import 'package:example/lsp_exploration/lsp/messages/go_to_definition.dart';
import 'package:example/lsp_exploration/lsp/messages/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:path/path.dart' as path;
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

class IdeEditor extends StatefulWidget {
  const IdeEditor({
    super.key,
    required this.lspClient,
    required this.sourceFile,
    this.onGoToDefinition,
  });

  final LspClient lspClient;
  final File? sourceFile;
  final void Function(String uri, Range range)? onGoToDefinition;

  @override
  State<IdeEditor> createState() => _IdeEditorState();
}

class _IdeEditorState extends State<IdeEditor> {
  final _linesKey = GlobalKey();
  late FollowerBoundary _screenBoundary;

  Timer? _hoverTimer;

  /// Shows/hides the overlay that displays information about the hovered text.
  final _hoverOverlayController = OverlayPortalController();

  /// The document to display in the hover overlay.
  final _hoverPopoverDocument = ValueNotifier<Document>(MutableDocument());

  /// The rect of the word that is currently being hovered.
  final _hoveredFocalPoint = ValueNotifier<Rect?>(null);

  /// Link to display a popover near to the focal point.
  final _hoverLink = LeaderLink();

  final _actionsOverlayController = OverlayPortalController();
  final _actionsFocalPoint = ValueNotifier<Rect?>(null);
  final _actionsLink = LeaderLink();
  final _availableCodeActions = ValueNotifier<List<LspCodeAction>?>(null);

  CodePosition? _latestHoveredCodePosition;

  Highlighter? _highlighter;

  double _fontSize = 18;

  final _focusNode = FocusNode();

  final _fileContent = ValueNotifier<String>("");

  var _styledLines = <TextSpan>[];

  Position? _currentSelectedPosition;

  @override
  void initState() {
    super.initState();

    if (widget.sourceFile != null) {
      _fileContent.value = widget.sourceFile!.readAsStringSync();
    }
    _initializeSyntaxHighlighting();

    _fileContent.addListener(_onFileContentChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _screenBoundary = ScreenFollowerBoundary(
      screenSize: MediaQuery.sizeOf(context),
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
  }

  @override
  void didUpdateWidget(IdeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.sourceFile != oldWidget.sourceFile) {
      _fileContent.value = widget.sourceFile!.readAsStringSync();
    }
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _fileContent.dispose();
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

  void _onFileContentChange() {
    _highlightSyntax();
  }

  void _highlightSyntax() {
    setState(() {
      _styledLines = highlightSyntaxByLine(_highlighter!, _fileContent.value);

      print("Displaying ${_styledLines.length} styled lines");
      for (final span in _styledLines) {
        final buffer = StringBuffer();
        span.computeToPlainText(buffer);
        print("Line: '${buffer.toString()}'");
      }
    });
  }

  Future<void> _hoverAtCodePosition(CodePosition position) async {
    if (widget.lspClient.status != LspClientStatus.initialized) {
      return;
    }

    if (_actionsOverlayController.isShowing) {
      // Don't show a hover if the actions overlay is showing.
      return;
    }

    final sourceFile = widget.sourceFile;
    if (sourceFile == null) {
      return;
    }

    if (_shouldAbortCurrentHoverRequest(position)) {
      return;
    }

    final filePath = sourceFile.isAbsolute //
        ? sourceFile.path
        : path.absolute(sourceFile.path);

    final res = await widget.lspClient.hover(
      HoverParams(
        textDocument: TextDocumentIdentifier(
          uri: "file://$filePath",
        ),
        position: Position(
          line: position.line,
          character: position.characterOffset,
        ),
      ),
    );

    if (res == null) {
      return;
    }

    if (_shouldAbortCurrentHoverRequest(position)) {
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

  void _onHover(PointerHoverEvent event) {
    if (widget.lspClient.status != LspClientStatus.initialized) {
      return;
    }

    final openedFile = widget.sourceFile;
    if (openedFile == null) {
      _hoverOverlayController.hide();
      return;
    }

    if (_fileContent.value.isEmpty) {
      _hoverOverlayController.hide();
      return;
    }

    final globalOffset = (context.findRenderObject() as RenderBox).localToGlobal(event.localPosition);
    final codeLines = _linesKey.asCodeLines;
    final hoverPosition = codeLines.findCodePositionNearestGlobalOffset(globalOffset);

    final hoverWordRange = codeLines.findWordBoundaryAtGlobalOffset(globalOffset);
    if (hoverWordRange == null) {
      return;
    }
    final boxes = codeLines.getSelectionBoxesForCodeRange(hoverWordRange);
    if (boxes.isNotEmpty) {
      final newFocalPoint = boxes.first.toRect();
      if (newFocalPoint != _hoveredFocalPoint.value) {
        // We are now hovering another word. Hide the overlay, it will be shown again after
        // querying the new hover popover text.
        _hoverOverlayController.hide();
      }

      _hoveredFocalPoint.value = newFocalPoint;
    }

    _latestHoveredCodePosition = hoverPosition;

    _hoverTimer?.cancel();
    _hoverTimer = Timer(
      const Duration(milliseconds: 500),
      () => _hoverAtCodePosition(hoverPosition),
    );
  }

  bool _shouldAbortCurrentHoverRequest(CodePosition hoveredCodePosition) {
    if (!mounted) {
      return true;
    }

    if (widget.sourceFile == null) {
      // There isn't any opened file to hover on.
      return true;
    }

    if (hoveredCodePosition != _latestHoveredCodePosition) {
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

  Future<void> _onTapUp(TapUpDetails details) async {
    if (_actionsOverlayController.isShowing) {
      _actionsOverlayController.hide();
    }

    if (_hoverOverlayController.isShowing) {
      _hoverOverlayController.hide();
    }

    final sourceFile = widget.sourceFile;
    if (sourceFile == null) {
      return;
    }

    final codeLines = _linesKey.asCodeLines;
    final codePosition = codeLines.findCodePositionNearestGlobalOffset(details.globalPosition);

    _currentSelectedPosition = Position(
      line: codePosition.line,
      character: codePosition.characterOffset,
    );

    final range = codeLines.findWordBoundaryAtGlobalOffset(details.globalPosition);
    if (range == null) {
      return;
    }

    final boxes = codeLines.getSelectionBoxesForCodeRange(range);
    if (boxes.isEmpty) {
      return;
    }

    _actionsFocalPoint.value = boxes.first.toRect();

    // TODO: re-enable this checking if CMD is pressed.
    //
    // final res = await widget.lspClient.goToDefinition(DefinitionsParams(
    //   textDocument: TextDocumentIdentifier(
    //     uri: "file://$filePath",
    //   ),
    //   position: Position(
    //     line: codePosition.line,
    //     character: codePosition.characterOffset,
    //   ),
    // ));
    // if (res == null || res.isEmpty) {
    //   return;
    // }

    // widget.onGoToDefinition?.call(res.first.uri, res.first.range);
  }

  Future<void> _codeActions(CodeActionsIntent intent) async {
    if (_hoverOverlayController.isShowing) {
      _hoverOverlayController.hide();
    }

    final sourceFile = widget.sourceFile;
    if (sourceFile == null) {
      return;
    }

    final position = _currentSelectedPosition;
    if (position == null) {
      return;
    }

    final filePath = sourceFile.isAbsolute //
        ? sourceFile.path
        : path.absolute(sourceFile.path);

    final res = await widget.lspClient.codeAction(
      CodeActionsParams(
        textDocument: TextDocumentIdentifier(uri: 'file://$filePath'),
        range: Range(start: position, end: position),
        context: const CodeActionContext(
          triggerKind: CodeActionTriggerKind.invoked,
          // We don't want actions like "Organize Imports" or "Fix All"
          // to be displayed at the middle of the code.
          only: [
            CodeActionKind.quickFix,
            CodeActionKind.refactor,
          ],
        ),
      ),
    );

    _availableCodeActions.value = res;

    if (res == null || res.isEmpty) {
      return;
    }

    _actionsOverlayController.show();
  }

  @override
  Widget build(BuildContext context) {
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
        CodeActionsIntent: CallbackAction<CodeActionsIntent>(onInvoke: _codeActions),
      },
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.equal): const IncreaseFontSizeIntent(),
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.minus): const DecreaseFontSizeIntent(),
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.period): const CodeActionsIntent(),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: MouseRegion(
            onHover: _onHover,
            onExit: (event) => _hoverOverlayController.hide(),
            child: OverlayPortal(
              controller: _hoverOverlayController,
              overlayChildBuilder: (context) => _buildHoverOverlay(),
              child: OverlayPortal(
                controller: _actionsOverlayController,
                overlayChildBuilder: (context) => _buildCodeActionsPopover(),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTapUp: _onTapUp,
                        child: CodeLines(
                          key: _linesKey,
                          codeLines: _styledLines,
                          indentLineColor: indentLineColor,
                          baseTextStyle: _baseCodeStyle,
                        ),
                      ),
                    ),
                    _buildCursorHoverLeader(),
                    _buildCodeActionsLeader(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCursorHoverLeader() {
    return ValueListenableBuilder(
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
    );
  }

  Widget _buildHoverOverlay() {
    return Follower.withOffset(
      link: _hoverLink,
      leaderAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, -20),
      boundary: ScreenFollowerBoundary(
        screenSize: MediaQuery.sizeOf(context),
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      ),
      child: Container(
        height: 200,
        width: 500,
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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: ValueListenableBuilder(
                valueListenable: _hoverPopoverDocument,
                builder: (context, document, child) {
                  return SuperReader(
                    document: document,
                    stylesheet: defaultStylesheet.copyWith(
                      addRulesAfter: [
                        ...darkModeStyles,
                        StyleRule(
                          BlockSelector.all,
                          (doc, docNode) {
                            return {
                              Styles.maxWidth: double.infinity,
                              Styles.padding: const CascadingPadding.symmetric(horizontal: 0),
                              Styles.textStyle: const TextStyle(
                                fontSize: 16,
                                height: 1.2,
                              ),
                            };
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeActionsLeader() {
    return ValueListenableBuilder(
      valueListenable: _actionsFocalPoint,
      builder: (context, value, child) {
        if (value == null) {
          return const SizedBox();
        }

        return Positioned(
          top: _actionsFocalPoint.value!.top,
          left: _actionsFocalPoint.value!.left,
          child: Leader(
            link: _actionsLink,
            child: SizedBox(
              width: _actionsFocalPoint.value!.width,
              height: _actionsFocalPoint.value!.height,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCodeActionsPopover() {
    final actions = _availableCodeActions.value;
    if (actions == null || actions.isEmpty) {
      return const SizedBox();
    }

    return FollowerFadeOutBeyondBoundary(
      link: _actionsLink,
      boundary: _screenBoundary,
      child: Follower.withOffset(
        link: _actionsLink,
        leaderAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, -20),
        boundary: _screenBoundary,
        child: PopoverList(
          editorFocusNode: _focusNode,
          onListItemSelected: (_) => _actionsOverlayController.hide(),
          onCancelRequested: () => _actionsOverlayController.hide(),
          listItems: actions
              .map(
                (action) => PopoverListItem(
                  id: action.command,
                  label: action.title,
                  icon: _buildIconForCodeAction(action),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Icon _buildIconForCodeAction(LspCodeAction action) {
    return switch (action.kind) {
      CodeActionKind.refactorExtract => const Icon(
          Icons.build_outlined,
          size: 14,
        ),
      _ => const Icon(
          Icons.lightbulb,
          color: Colors.yellow,
          size: 14,
        )
    };
  }
}

const _baseCodeStyle = TextStyle(
  color: Colors.white,
  fontFamily: "SourceCodePro",
  fontSize: 16,
  fontWeight: FontWeight.w900,
);
