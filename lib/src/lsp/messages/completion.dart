import 'package:inception/src/lsp/messages/common_types.dart';

class CompletionParams {
  CompletionParams({
    required this.textDocument,
    required this.position,
    required this.context,
  });

  final TextDocumentIdentifier textDocument;
  final Position position;
  final CompletionContext context;

  Map<String, dynamic> toJson() {
    return {
      'textDocument': textDocument.toJson(),
      'position': position.toJson(),
      'context': context.toJson(),
    };
  }
}

class CompletionContext {
  CompletionContext({
    required this.triggerKind,
    this.triggerCharacter,
  });

  final int triggerKind;
  final String? triggerCharacter;

  Map<String, dynamic> toJson() {
    return {
      'triggerKind': triggerKind,
      'triggerCharacter': triggerCharacter,
    };
  }
}

class CompletionTriggerKind {
  static const int invoked = 1;
  static const int triggerCharacter = 2;
  static const int triggerForIncompleteCompletions = 3;
}

class CompletionItem {
  CompletionItem({
    required this.label,
    this.kind,
    this.detail,
    this.documentation,
    this.insertText,
    this.insertTextFormat,
  });

  final String label;

  final int? kind;
  final String? detail;
  final String? documentation;
  final String? insertText;
  final int? insertTextFormat;

  CompletionItem.fromJson(Map<String, dynamic> json)
      : label = json['label'],
        kind = json['kind'],
        detail = json['detail'],
        documentation = json['documentation'],
        insertText = json['insertText'],
        insertTextFormat = json['insertTextFormat'];

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (kind != null) 'kind': kind,
      if (detail != null) 'detail': detail,
      if (documentation != null) 'documentation': documentation,
      if (insertText != null) 'insertText': insertText,
      if (insertTextFormat != null) 'insertTextFormat': insertTextFormat,
    };
  }
}
