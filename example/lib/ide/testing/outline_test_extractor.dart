import 'dart:collection';

import 'package:example/ide/testing/test_node.dart';
import 'package:example/lsp_exploration/lsp/messages/outline.dart';

/// Extracts tests from a Dart Outline.
///
/// The Outline is a tree representation of the structure of a Dart file, like an AST.
class OutlineTestExtractor {
  /// Extracts tests from the given [outline].
  Future<TestSuite> extractTests(Outline outline, String fileUri, bool isGoldenTestFolder) async {
    final visitor = _TestExtractorOutlineVisitor();
    visitor.visitOutline(outline);

    return TestSuite(
      fileUri: fileUri,
      nodes: visitor.testsAndGroups,
      isGoldenTestFolder: isGoldenTestFolder,
    );
  }
}

/// Visitor that extracts tests from an Outline.
class _TestExtractorOutlineVisitor extends OutlineVisitor {
  List<TestNode> get testsAndGroups => UnmodifiableListView(_testsAndGroups);
  List<TestNode> _testsAndGroups = [];

  List<TestNode> _groupsBeingVisited = [];

  @override
  void visitOutline(Outline outline) {
    _groupsBeingVisited = [];
    _testsAndGroups = [];
    super.visitOutline(outline);
  }

  @override
  void visitUnitTestGroup(Outline outline) {
    final parent = _groupsBeingVisited.lastOrNull;

    final name = _extractTestName(outline.element.name);
    final fullName = parent != null //
        ? '${parent.fullName} $name'
        : name;

    final groupNode = TestGroup(
      name: name,
      fullName: fullName,
      parent: parent,
      children: [],
    );

    // Store the group so it can be retrieved when visiting a test or subgroup.
    _groupsBeingVisited.add(groupNode);

    if (parent == null) {
      // This is a top-level group.
      _testsAndGroups.add(groupNode);
    } else {
      // This is a subgroup.
      parent.children.add(groupNode);
    }

    // Visit the children of this group.
    super.visitUnitTestGroup(outline);

    // We are done with this group, remove it from the list.
    _groupsBeingVisited.removeLast();
  }

  @override
  void visitUnitTestTest(Outline outline) {
    final parent = _groupsBeingVisited.lastOrNull;

    final name = _extractTestName(outline.element.name);
    final fullName = parent != null //
        ? '${parent.fullName} $name'
        : name;

    final testNode = TestItem(
      name: name,
      fullName: fullName,
      parent: parent,
      isGoldenTest: _isGoldenTest(outline.element.name),
    );

    if (parent == null) {
      // This is a top-level test.
      _testsAndGroups.add(testNode);
    } else {
      // This is a test in a group.
      parent.children.add(testNode);
    }
  }

  String _extractTestName(String name) {
    String testName = name;

    final openParenthesisIndex = name.indexOf('(');
    final closeParenthesisIndex = name.indexOf(')');

    testName = name.substring(openParenthesisIndex + 1, closeParenthesisIndex);

    if (testName.startsWith('"')) {
      testName = testName.substring(1);
    }

    if (testName.endsWith('"')) {
      testName = testName.substring(0, testName.length - 1);
    }

    return testName;
  }

  bool _isGoldenTest(String name) {
    return name.startsWith('testGoldens');
  }
}
