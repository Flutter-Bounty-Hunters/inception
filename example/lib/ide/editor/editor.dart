import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:example/ide/infrastructure/keyboard_shortcuts.dart';
import 'package:example/ide/theme.dart';
import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:example/lsp_exploration/lsp/messages/common_types.dart';
import 'package:example/lsp_exploration/lsp/messages/go_to_definition.dart';
import 'package:example/lsp_exploration/lsp/messages/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  double _fontSize = 18;

  final _focusNode = FocusNode();

  final _fileContent = ValueNotifier<String>("");

  @override
  void initState() {
    super.initState();

    if (widget.sourceFile != null) {
      _fileContent.value = widget.sourceFile!.readAsStringSync();
    }
    _initializeSyntaxHighlighting();
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

  Future<void> _hoverAtTextOffset(int offset) async {
    final sourceFile = widget.sourceFile;
    if (sourceFile == null) {
      return;
    }

    final text = _fileContent.value;

    if (_shouldAbortCurrentHoverRequest(offset)) {
      return;
    }

    final (line, character) = _getLineAndCharacterForOffset(text, offset);

    final filePath = sourceFile.isAbsolute //
        ? sourceFile.path
        : path.absolute(sourceFile.path);

    final res = await widget.lspClient.hover(
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

    if (widget.sourceFile == null) {
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

  Future<void> _onTapUp(TapUpDetails details) async {
    final sourceFile = widget.sourceFile;
    if (sourceFile == null) {
      return;
    }
    final renderParagraph = _textKey.currentContext?.findRenderObject() as RenderParagraph?;
    if (renderParagraph == null) {
      return;
    }

    final localPosition = renderParagraph.globalToLocal(details.globalPosition);
    final textPosition = renderParagraph.getPositionForOffset(localPosition);
    if (textPosition.offset < 0) {
      return;
    }

    //final wordRange = renderParagraph.getWordBoundary(textPosition);
    final text = _fileContent.value;
    final (line, character) = _getLineAndCharacterForOffset(text, textPosition.offset);

    final filePath = sourceFile.isAbsolute //
        ? sourceFile.path
        : path.absolute(sourceFile.path);

    final res = await widget.lspClient.goToDefinition(DefinitionsParams(
      textDocument: TextDocumentIdentifier(
        uri: "file://$filePath",
      ),
      position: Position(
        line: line,
        character: character,
      ),
    ));
    if (res == null || res.isEmpty) {
      return;
    }

    widget.onGoToDefinition?.call(res.first.uri, res.first.range);
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

                  //final highlightedCode = _highlighter!.highlight(_fileContent.value);

                  return MouseRegion(
                    cursor: SystemMouseCursors.text,
                    //onHover: _onHover,
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
                          _buildCodeArea(),
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

  Widget _buildCodeArea() {
    return _buildLines(_fileContent.value);
// GestureDetector(
//                             onTapUp: _onTapUp,
//                             child: Text.rich(
//                               highlightedCode,
//                               key: _textKey,
//                               style: TextStyle(
//                                 fontFamily: 'Courier New',
//                                 fontSize: _fontSize,
//                                 height: 1.5,
//                               ),
//                             ),
//                           ),
  }

  Widget _buildLines(String codeSnippet) {
    final codeLines = codeSnippet.split("\n");
    final newlineMatcher = RegExp(r'\n');
    final newlineOffsets = newlineMatcher.allMatches(codeSnippet).map((match) => match.start).toList();
    print("Newline offset: $newlineOffsets");

    final highlightedText = _highlighter!.highlight(codeSnippet);

    // Move through every styled span and break the spans apart by line.
    final styledLines = <TextSpan>[];
    final spanStack = <TextSpan>[highlightedText];

    TextSpan currentLine = TextSpan(
      text: "",
      children: [],
    );
    styledLines.add(currentLine);
    int currentOffset = 0;

    final debugBuffer = StringBuffer();

    while (spanStack.isNotEmpty) {
      final span = spanStack.removeAt(0);

      if (span.children != null) {
        spanStack.insertAll(0, span.children!.whereType<TextSpan>());
      }

      if (span.text == null) {
        continue;
      }

      // print("Span: '${span.text}' - start offset: $currentOffset");

      span.computeToPlainText(debugBuffer);
      debugBuffer.writeln();

      final endOfSpan = currentOffset + span.text!.length;

      if (newlineOffsets.isEmpty || endOfSpan <= newlineOffsets.first) {
        // All the content in this span belongs to the current line. Append it.
        currentLine.children!.add(span);
        print(
            "Appending text: '${span.text!}' - global offset: $currentOffset -> ${currentOffset + span.text!.length}");
        currentOffset += span.text!.length;
        continue;
      }

      while (newlineOffsets.isNotEmpty && endOfSpan > newlineOffsets.first) {
        // The next newline appears somewhere in this span.
        final nextNewline = newlineOffsets.removeAt(0);
        print("Processing newline at $nextNewline - end of text span: $endOfSpan");

        if (nextNewline - currentOffset > 0) {
          // Copy the styled text from the current offset to the next newline.
          print("Appending text: '${span.text!}' - global offset: $currentOffset -> ${nextNewline - 1}");

          // Copy the text in this span before the newline.
          currentLine.children!.add(
            TextSpan(
              text: span.text!.substring(0, nextNewline - currentOffset),
              style: span.style?.copyWith(fontSize: _fontSize),
            ),
          );
        }

        final buffer = StringBuffer();
        currentLine.computeToPlainText(buffer);
        print("Committing line: '${buffer.toString()}'");

        // Create a new line to append to.
        currentLine = TextSpan(text: "", children: []);
        styledLines.add(currentLine);

        if (endOfSpan > nextNewline + 1 && endOfSpan < newlineOffsets.first) {
          print(
              "Copy after newline - newline offset: $nextNewline, current offset: $currentOffset, end of span: $endOfSpan, span length: ${span.text!.length}, next newline: ${newlineOffsets.first}");
          print("Text after newline: '${span.text!.substring((nextNewline - currentOffset) + 1)}'");
          // Copy the text in this span after the newline.
          currentLine.children!.add(
            TextSpan(
              text: span.text!.substring((nextNewline - currentOffset) + 1),
              style: span.style?.copyWith(fontSize: _fontSize),
            ),
          );

          // Move the current offset to the character after the text we just copied.
          currentOffset = endOfSpan;
        } else {
          // Move the current offset to the character after the newline we just processed.
          currentOffset = nextNewline + 1;
        }
      }
    }

    print("Displaying ${styledLines.length} styled lines");
    for (final span in styledLines) {
      final buffer = StringBuffer();
      span.computeToPlainText(buffer);
      print("Line: '${buffer.toString()}'");
    }

    print("");
    print("");
    print("All non-null spans:");
    print(debugBuffer);

    return Column(
      children: [
        for (int i = 0; i < styledLines.length; i += 1) //
          // _buildLine(i, codeLines[i]),
          _buildLine(i, styledLines[i]),
      ],
    );
  }

  Widget _buildLine(int index, TextSpan content) {
    final buffer = StringBuffer();
    content.computeToPlainText(buffer);
    final contentText = buffer.toString();

    final leadingSpaceMatcher = RegExp(r'\s+');
    final leadingSpaceMatch = leadingSpaceMatcher.matchAsPrefix(contentText);
    int tabCount = 0;
    if (leadingSpaceMatch != null) {
      // -1 because the very first indentation line is the same as the divider between lines and code.
      tabCount = (leadingSpaceMatch.end ~/ 2) - 1;
    }
    // print("Line $index - tab: $tabCount - '$content'");

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 100 + 8),
            for (int i = 0; i < tabCount; i += 1) //
              const DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: _lineColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  "  ",
                  style: _baseCodeStyle,
                ),
              ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.only(right: 64),
                child: Text(
                  "${index + 1}",
                  textAlign: TextAlign.right,
                  style: _baseCodeStyle.copyWith(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                content,
                style: _baseCodeStyle,
              ),
            ),
          ],
        ),
      ],
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
              color: Colors.black.withOpacity(0.5),
            ),
            BoxShadow(
              offset: const Offset(0, 12),
              blurRadius: 16,
              color: Colors.black.withOpacity(0.5),
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
}

const _baseCodeStyle = TextStyle(
  color: Colors.white,
  fontFamily: "SourceCodePro",
  fontSize: 24,
  fontWeight: FontWeight.w900,
);

const _lineColor = Color(0xFF333333);
const _background = Color(0xFF222222);
