import 'dart:io';

import 'package:path/path.dart' as path;

/// A node in the test tree.
///
/// Tests are organized in a tree structure. Each test file is represented by a [TestSuite] node,
/// which may contain [TestGroup]s and [TestItem]s nodes.
///
/// For example, consider the following test file:
///
/// ```dart
/// void main() {
///  group('group 1', () {
///    group('subgroup 1', () {
///      test('test 1', () {});
///      test('test 2', () {});
///    });
///  });
///
///  test('another test', () {});
/// });
/// ```
///
/// The corresponding test tree would look like this:
///
/// ```
/// (suite) -> my_test.dart
/// | (group) -> group 1
/// | | (group) -> subgroup 1
/// | | | (test) -> test 1
/// | | | (test) -> test 2
/// | (test) -> another test
/// ```
sealed class TestNode {
  TestNode({
    required this.name,
    required this.fullName,
    List<TestNode>? children,
    TestNode? parent,
    this.isGoldenTest = false,
  }) : children = children ?? <TestNode>[] {
    _parent = parent;
    for (var child in this.children) {
      child._parent = this;
    }
  }

  /// The name of the test.
  final String name;

  /// The full name of the test, including the names of all the parent groups.
  final String fullName;

  /// The children of this node.
  final List<TestNode> children;

  /// Whether this test is a golden test.
  final bool isGoldenTest;

  /// The parent of this node.
  TestNode? get parent => _parent;
  TestNode? _parent;
}

/// A test suite in a test tree.
///
/// A test suite is a node in the test tree that represents a test file.
class TestSuite extends TestNode {
  TestSuite({
    required this.fileUri,
    required List<TestNode> nodes,
    bool isGoldenTestFolder = false,
  }) : super(
          name: 'suite',
          fullName: fileUri,
          children: nodes,
          isGoldenTest: isGoldenTestFolder,
        );

  /// The URI of the test file.
  final String fileUri;
}

/// A group of tests in a test tree.
///
/// Each `group` method call generates a [TestGroup] node in the test tree.
class TestGroup extends TestNode {
  TestGroup({
    required super.name,
    required super.fullName,
    required super.children,
    super.parent,
  });
}

/// A test in a test tree.
///
/// Each `test`, `testWidgets` or `testGoldens`  method call generates a [TestItem]
/// node in the test tree.
class TestItem extends TestNode {
  TestItem({
    required super.name,
    required super.fullName,
    super.parent,
    super.isGoldenTest = false,
  });
}

/// Prints a test suite to the console.
void debugPrintTestSuite(TestSuite suite) {
  // ignore: avoid_print
  print(testSuiteToDebugString(suite));
}

/// Generates a readable string representation of a test suite.
///
/// This is useful for debugging purposes.
String testSuiteToDebugString(TestSuite suite) {
  final buffer = StringBuffer();

  buffer.writeln('(suite) ${path.basename(File.fromUri(Uri.parse(suite.fileUri)).path)}');

  _printTestNode(buffer, suite.children, 1);

  return buffer.toString();
}

void _printTestNode(StringBuffer buffer, List<TestNode> nodes, int indent) {
  for (var node in nodes) {
    final description = node is TestGroup ? '(group)' : '(test)';
    buffer.writeln('${'| ' * indent}$description ${node.name}');
    _printTestNode(buffer, node.children, indent + 1);
  }
}
