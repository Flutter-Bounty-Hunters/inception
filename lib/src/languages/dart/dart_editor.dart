import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:inception/src/document/code_document.dart';
import 'package:inception/src/editor/code_editor.dart';
import 'package:inception/src/languages/dart/dart_code_editor_presenter.dart';
import 'package:inception/src/languages/dart/dart_lexer.dart';
import 'package:inception/src/languages/dart/dart_syntax_highlighter.dart';
import 'package:inception/src/languages/dart/dart_theme_pineapple.dart';

/// A simplistic editor, which implements the fundamentals of a Dart code editor,
/// which is useful for demos and for testing purposes.
class DartEditor extends StatefulWidget {
  const DartEditor({
    super.key,
    this.initialCode = "",
    this.debugOnImeChange,
  });

  final String initialCode;

  final void Function(TextEditingValue? newValue)? debugOnImeChange;

  @override
  State<DartEditor> createState() => _DartEditorState();
}

class _DartEditorState extends State<DartEditor> {
  late final CodeEditorPresenter _presenter;

  @override
  void initState() {
    super.initState();

    _presenter = DartCodeEditorPresenter(
      CodeDocument(DartLexer(), widget.initialCode),
      DartSyntaxHighlighter(
        pineappleDartTheme,
        _baseEditorTextStyle,
      ),
    );
  }

  @override
  void dispose() {
    _presenter.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodeEditor(
      presenter: _presenter,
      style: CodeEditorStyle(
        gutterColor: _editorTheme.gutterBackground,
        gutterBorderColor: _editorTheme.gutterBorder,
        lineBackgroundColor: _editorTheme.background,
        indentLineColor: _editorTheme.indentLineColor,
        // FIXME: I'm pretty sure this style should come from the theme, perhaps combined
        // with _baseTextStyle to inherit the desired size and height.
        baseTextStyle: TextStyle(
          color: _editorTheme.foreground,
          fontSize: 14,
          fontFamily: "SourceCodePro",
          height: _baseEditorTextStyle.height,
        ),
      ),
      debugOnImeChange: widget.debugOnImeChange,
    );
  }
}

const _editorTheme = _EditorTheme(
  paneColor: Color(0xFF222222),
  paneDividerColor: Color(0xFF111111),
  indentLineColor: Color(0xFF2A3F44),

  // ─────────────────────────────────────────────
  // Editor / UI
  // ─────────────────────────────────────────────
  background: Color(0xFF1B2A2F), // deep ocean night
  foreground: Color(0xFFECE7D5), // warm sand text
  caret: Color(0xFFFFE066), // pineapple yellow

  selection: Color(0xFF2F6F7A), // ocean teal
  inactiveSelection: Color(0xFF2A3F44),

  lineHighlight: Color(0xFF22383E),

  gutterBackground: Color(0xFF18262B),
  gutterBorder: Color(0xFF2E4A50),
  gutterForeground: Color(0xFF6FAFB7),

  bracketHighlight: Color(0xFFFFE066), // pineapple accent
  invisibleCharacters: Color(0xFF4F7D85),
);

// TODO: This was copied from Kalua - if this is generally accurate, export this from Inception
class _EditorTheme {
  const _EditorTheme({
    required this.paneColor,
    required this.paneDividerColor,
    required this.background,
    required this.indentLineColor,
    required this.foreground,
    required this.caret,
    required this.selection,
    required this.inactiveSelection,
    required this.lineHighlight,
    required this.gutterBackground,
    required this.gutterBorder,
    required this.gutterForeground,
    required this.bracketHighlight,
    required this.invisibleCharacters,
  });

  // ─────────────────────────────────────────────
  // Editor / UI colors
  // ─────────────────────────────────────────────

  final Color paneColor;

  final Color paneDividerColor;

  /// Main editor background
  final Color background;

  /// The color of the vertical lines that are displayed in the editor for every
  /// tab of distance that code sits from the gutter.
  final Color indentLineColor;

  /// Default foreground text color
  final Color foreground;

  /// Caret / cursor color
  final Color caret;

  /// Selection background
  final Color selection;

  /// Inactive selection background
  final Color inactiveSelection;

  /// Line highlight (current line)
  final Color lineHighlight;

  /// Gutter background
  final Color gutterBackground;

  final Color gutterBorder;

  /// Gutter foreground (line numbers)
  final Color gutterForeground;

  /// Bracket pair highlight
  final Color bracketHighlight;

  /// Invisible characters (whitespace markers)
  final Color invisibleCharacters;
}

const _baseEditorTextStyle = TextStyle(
  fontFamily: "SourceCodePro",
  fontSize: 14,
  height: 1.4,
);
