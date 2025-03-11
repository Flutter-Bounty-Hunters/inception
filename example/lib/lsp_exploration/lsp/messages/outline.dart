import 'package:example/lsp_exploration/lsp/messages/common_types.dart';

/// A notification sent from the server to the client to provide outline information.
///
/// The outline is a tree structure of the code elements in a file.
///
/// The notification is sent from the server to the client when the file is opened.
class OutlineNotification {
  OutlineNotification({
    required this.uri,
    required this.outline,
  });

  /// The URI of the file for which the outline is being provided.
  final String uri;

  /// The outline information.
  final Outline outline;

  factory OutlineNotification.fromJson(Map<String, dynamic> json) {
    return OutlineNotification(
      uri: json['uri'],
      outline: Outline.fromJson(json['outline']),
    );
  }
}

/// An outline of a file.
///
/// The outline is a tree structure of the code elements in a file.
class Outline {
  Outline({
    required this.element,
    required this.range,
    required this.codeRange,
    required this.children,
  });

  final OutlineElement element;
  final Range range;
  final Range codeRange;
  final List<Outline> children;

  factory Outline.fromJson(Map<String, dynamic> json) {
    return Outline(
      element: OutlineElement.fromJson(json['element']),
      range: Range.fromJson(json['range']),
      codeRange: Range.fromJson(json['codeRange']),
      children: json['children'] != null
          ? (json['children'] as List<dynamic>).map((child) => Outline.fromJson(child)).toList()
          : [],
    );
  }
}

class OutlineElement {
  OutlineElement({
    required this.name,
    required this.range,
    required this.kind,
    required this.parameters,
    required this.typeParameters,
    required this.returnType,
  });

  final String name;
  final Range range;
  final String kind;
  final String? parameters;
  final String? typeParameters;
  final String? returnType;

  factory OutlineElement.fromJson(Map<String, dynamic> json) {
    return OutlineElement(
      name: json['name'],
      range: Range.fromJson(json['range']),
      kind: json['kind'],
      parameters: json['parameters'],
      typeParameters: json['typeParameters'],
      returnType: json['returnType'],
    );
  }
}

/// A visitor for an outline tree.
///
/// This visitor provides a way to visit each node in the outline tree.
///
/// To use this visitor, subclass it and override the methods for the nodes you are interested in. Call
/// [visitOutline] with the root outline node to start visiting the tree.
class OutlineVisitor {
  void visitOutline(Outline outline) {
    _visitNode(outline);
  }

  void visitClass(Outline outline) {
    _visitChildren(outline);
  }

  void visitCompilationUnit(Outline outline) {
    _visitChildren(outline);
  }

  void visitClassTypeAlias(Outline outline) {
    _visitChildren(outline);
  }

  void visitConstructor(Outline outline) {
    _visitChildren(outline);
  }

  void visitConstructorInvocation(Outline outline) {
    _visitChildren(outline);
  }

  void visitEnum(Outline outline) {
    _visitChildren(outline);
  }

  void visitEnumConstant(Outline outline) {
    _visitChildren(outline);
  }

  void visitExtension(Outline outline) {
    _visitChildren(outline);
  }

  void visitField(Outline outline) {
    _visitChildren(outline);
  }

  void visitFile(Outline outline) {
    _visitChildren(outline);
  }

  void visitFunction(Outline outline) {
    _visitChildren(outline);
  }

  void visitFunctionInvocation(Outline outline) {
    _visitChildren(outline);
  }

  void visitFunctionTypeAlias(Outline outline) {
    _visitChildren(outline);
  }

  void visitGetter(Outline outline) {
    _visitChildren(outline);
  }

  void visitLabel(Outline outline) {
    _visitChildren(outline);
  }

  void visitLibrary(Outline outline) {
    _visitChildren(outline);
  }

  void visitLocalVariable(Outline outline) {
    _visitChildren(outline);
  }

  void visitMethod(Outline outline) {
    _visitChildren(outline);
  }

  void visitMixin(Outline outline) {
    _visitChildren(outline);
  }

  void visitParameter(Outline outline) {
    _visitChildren(outline);
  }

  void visitPrefix(Outline outline) {
    _visitChildren(outline);
  }

  void visitSetter(Outline outline) {
    _visitChildren(outline);
  }

  void visitTopLevelVariable(Outline outline) {
    _visitChildren(outline);
  }

  void visitTypeParameter(Outline outline) {
    _visitChildren(outline);
  }

  void visitUnitTestGroup(Outline outline) {
    _visitChildren(outline);
  }

  void visitUnitTestTest(Outline outline) {
    _visitChildren(outline);
  }

  void visitUnknown(Outline outline) {
    _visitChildren(outline);
  }

  void _visitChildren(Outline outline) {
    if (outline.children.isEmpty) {
      return;
    }

    for (final child in outline.children) {
      _visitNode(child);
    }
  }

  void _visitNode(Outline outline) {
    switch (outline.element.kind) {
      case "CLASS":
        visitClass(outline);
        break;
      case "CLASS_TYPE_ALIAS":
        visitClassTypeAlias(outline);
        break;
      case "COMPILATION_UNIT":
        visitCompilationUnit(outline);
        break;
      case "CONSTRUCTOR":
        visitConstructor(outline);
        break;
      case "CONSTRUCTOR_INVOCATION":
        visitConstructorInvocation(outline);
        break;
      case "ENUM":
        visitEnum(outline);
        break;
      case "ENUM_CONSTANT":
        visitEnumConstant(outline);
        break;
      case "EXTENSION":
        visitExtension(outline);
        break;
      case "FIELD":
        visitField(outline);
        break;
      case "FILE":
        visitFile(outline);
        break;
      case "FUNCTION":
        visitFunction(outline);
        break;
      case "FUNCTION_INVOCATION":
        visitFunctionInvocation(outline);
        break;
      case "FUNCTION_TYPE_ALIAS":
        visitFunctionTypeAlias(outline);
        break;
      case "GETTER":
        visitGetter(outline);
        break;
      case "LABEL":
        visitLabel(outline);
        break;
      case "LIBRARY":
        visitLibrary(outline);
        break;
      case "LOCAL_VARIABLE":
        visitLocalVariable(outline);
        break;
      case "METHOD":
        visitMethod(outline);
        break;
      case "MIXIN":
        visitMixin(outline);
        break;
      case "PARAMETER":
        visitParameter(outline);
        break;
      case "PREFIX":
        visitPrefix(outline);
        break;
      case "SETTER":
        visitSetter(outline);
        break;
      case "TOP_LEVEL_VARIABLE":
        visitTopLevelVariable(outline);
        break;
      case "TYPE_PARAMETER":
        visitTypeParameter(outline);
        break;
      case "UNIT_TEST_GROUP":
        visitUnitTestGroup(outline);
        break;
      case "UNIT_TEST_TEST":
        visitUnitTestTest(outline);
        break;
      case "UNKNOWN":
        visitUnknown(outline);
        break;
    }
  }
}
