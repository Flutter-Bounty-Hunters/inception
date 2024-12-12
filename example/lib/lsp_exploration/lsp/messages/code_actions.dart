import 'package:example/ide/problems_panel/diagnostics.dart';
import 'package:example/lsp_exploration/lsp/messages/common_types.dart';

class CodeActionsParams {
  CodeActionsParams({
    required this.textDocument,
    required this.range,
    this.context = const CodeActionContext(),
  });

  final TextDocumentIdentifier textDocument;
  final Range range;
  final CodeActionContext context;

  Map<String, dynamic> toJson() {
    return {
      'textDocument': textDocument.toJson(),
      'range': range.toJson(),
      'context': context.toJson(),
    };
  }
}

class CodeActionContext {
  const CodeActionContext({
    this.diagnostics = const [],
    this.only,
    this.triggerKind = CodeActionTriggerKind.invoked,
  });

  final List<Diagnostic> diagnostics;
  final int triggerKind;
  final List<String>? only;

  Map<String, dynamic> toJson() {
    return {
      'diagnostics': diagnostics.map((d) => d.toJson()).toList(),
      if (only != null) 'only': only,
      'triggerKind': triggerKind,
    };
  }
}

class CodeActionKind {
  static const String quickFix = 'quickfix';
  static const String refactor = 'refactor';
  static const String refactorExtract = 'refactor.extract';
  static const String refactorInline = 'refactor.inline';
  static const String refactorRewrite = 'refactor.rewrite';
  static const String source = 'source';
  static const String sourceOrganizeImports = 'source.organizeImports';
  static const String sourceFixAll = 'source.fixAll';
}

class CodeActionTriggerKind {
  static const int invoked = 1;
  static const int automatic = 2;
}

class LspCodeAction {
  LspCodeAction({
    required this.command,
    required this.title,
    required this.kind,
    this.edit,
  });

  final LspCommand command;
  final String title;
  final String kind;
  final LspEdit? edit;

  factory LspCodeAction.fromJson(Map<String, dynamic> json) {
    return LspCodeAction(
      command: LspCommand.fromJson(json['command']),
      title: json['title'],
      kind: json['kind'],
      edit: json['edit'] != null ? LspEdit.fromJson(json['edit']) : null,
    );
  }
}

class LspCommand {
  LspCommand({
    required this.command,
    required this.arguments,
  });

  final String command;
  final List<dynamic> arguments;

  factory LspCommand.fromJson(Map<String, dynamic> json) {
    return LspCommand(
      command: json['command'],
      arguments: json['arguments'],
    );
  }
}

class LspEdit {
  List<LspDocumentChange>? documentChanges;

  LspEdit({this.documentChanges = const []});

  factory LspEdit.fromJson(Map<String, dynamic> json) {
    return LspEdit(
      documentChanges: (json['documentChanges'] as List?)?.map((doc) => LspDocumentChange.fromJson(doc)).toList(),
    );
  }
}

class LspDocumentChange {
  LspDocumentChange({
    this.edits = const [],
    this.textDocument,
  });

  List<LspEditDetail>? edits;
  TextDocument? textDocument;

  factory LspDocumentChange.fromJson(Map<String, dynamic> json) {
    return LspDocumentChange(
      edits: (json['edits'] as List?)?.map((edit) => LspEditDetail.fromJson(edit)).toList(),
      textDocument: json['textDocument'] != null ? TextDocument.fromJson(json['textDocument']) : null,
    );
  }
}

class LspEditDetail {
  LspEditDetail({
    required this.newText,
    required this.range,
    this.insertTextFormat,
  });

  String newText;
  Range range;
  int? insertTextFormat;

  factory LspEditDetail.fromJson(Map<String, dynamic> json) {
    return LspEditDetail(
      newText: json['newText'],
      range: Range.fromJson(json['range']!),
      insertTextFormat: json['insertTextFormat'],
    );
  }
}

class TextDocument {
  TextDocument({
    required this.uri,
    this.version,
  });

  String uri;
  int? version;

  factory TextDocument.fromJson(Map<String, dynamic> json) {
    return TextDocument(
      uri: json['uri'],
      version: json['version'],
    );
  }
}
