import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:super_editor/super_editor.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:example/ide/infrastructure/controls/hover_box.dart';
import 'package:example/ide/infrastructure/controls/toolbar_buttons.dart';
import 'package:example/ide/testing/flutter_test_notifications.dart';
import 'package:example/ide/testing/flutter_test_runner.dart';
import 'package:example/ide/testing/test_discoverer.dart';
import 'package:example/ide/testing/test_node.dart';
import 'package:example/ide/theme.dart';
import 'package:example/ide/workspace.dart';

/// A panel that displays the a tree of tests and allows the user to run tests.
///
/// The panel is divided into three sections:
/// - The top section contains the filter field and buttons to run all tests or update the golden files.
/// - The middle section contains the tree of tests.
/// - The bottom section contains the tabs to switch between regular tests and golden tests.
///
/// When hovering over a test, a button is displayed to run the test. For golden tests,
/// another button is displayed to update the golden for the given test.
class TestPanel extends StatefulWidget {
  const TestPanel({
    super.key,
    required this.workspace,
  });

  final Workspace workspace;

  @override
  State<TestPanel> createState() => _TestPanelState();
}

class _TestPanelState extends State<TestPanel> {
  static const _rowHeight = 28.0;

  /// Controls which type of tests should be displayed.
  _TestPanelKind _panelKind = _TestPanelKind.regularTests;

  final AttributedTextEditingController _filterController = AttributedTextEditingController();
  final FocusNode _filterFocusNode = FocusNode();

  /// The last filter applied to the UI.
  String _lastFilter = '';

  /// The tree of tests that is displayed in the UI.
  List<_TestNodeViewModelTreeViewNode> _tree = [];

  /// Maps the full name of a test or group to the tree node that displays it.
  final Map<String, _TestNodeViewModelTreeViewNode> _testFullNameToTreeNode = {};

  final TreeViewController _treeController = TreeViewController();
  final ScrollController _verticalController = ScrollController();
  _TestNodeViewModelTreeViewNode? _hoveredNode;

  /// Discovers the tests in the workspace.
  late final LspTestDiscoverer _testDiscoverer;

  /// Whether the tests are still being discovered.
  bool _isDiscovering = true;

  /// All the test suites discovered in the workspace.
  List<TestSuite> _allTestSuites = [];

  /// The test suites that are currently being displayed.
  List<_TestViewModel> get _currentTestSuites => _panelKind == _TestPanelKind.regularTests //
      ? _regularTestSuites
      : _goldenTestSuites;

  /// The test suites that are regular tests, e.g., dart tests or widget tests.
  final List<_TestViewModel> _regularTestSuites = [];

  /// The test suites that are golden tests.
  final List<_TestViewModel> _goldenTestSuites = [];

  /// Runs the tests and provides the notifications for the status of each test.
  late final FlutterTestRunner runner;

  /// Maps the file path of a test suite to the index of the suite in [_allTestSuites].
  final Map<String, int> _filePathToSuiteIndex = {};

  /// Maps the file path of a test suite to the tests and groups in the suite.
  final Map<String, List<_TestViewModel>> _filePathToTestsAndGroups = {};

  /// Maps the full name of a test or group to the view model.
  ///
  /// The full name is the name of the test or group and all its parent groups.
  final Map<String, _TestViewModel> _fullNameToTestsAndGroups = {};

  /// Maps the ID of a test reported by the test runner to the view model.
  ///
  /// The test runner generates a sequential ID to identify each test. We use this ID to
  /// update the status of the test in the UI.
  final Map<int, _TestViewModel> _runnerTestIdToTestViewModel = {};

  /// Maps the ID of a group reported by the test runner to the group notification.
  final Map<int, FlutterTestGroupNotification> _runnerGroupIdToGroupNotification = {};

  /// Whether or not a test is currently running.
  bool _hasTestRunning = false;

  @override
  void initState() {
    super.initState();
    _testDiscoverer = LspTestDiscoverer(
      lspClient: widget.workspace.lspClient,
    );
    runner = FlutterTestRunner(
      workingDirectory: widget.workspace.directory.path,
      onNotification: _onTestNotification,
    );
    _filterController.addListener(_onFilterChanged);

    _discoverTests();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _filterFocusNode.dispose();
    super.dispose();
  }

  /// Finds all tests in the project and populates the test tree.
  Future<void> _discoverTests() async {
    final tests = await _testDiscoverer.discoverTests();

    if (!mounted) {
      return;
    }

    setState(() {
      _isDiscovering = false;
      _allTestSuites = tests;
      _createViewModelFromTest(_allTestSuites);
      _tree = _createTreeFromViewModels(_currentTestSuites);
    });
  }

  /// Creates the view models for each item from [testSuites].
  List<_TestViewModel> _createViewModelFromTest(List<TestSuite> testSuites) {
    final viewModels = <_TestViewModel>[];

    for (final suite in testSuites) {
      final filePath = File.fromUri(Uri.parse(suite.fileUri)).path;

      final testsAndGroups = <_TestViewModel>[];
      final suiteViewModel = _addToViewModel(viewModels, suite, testsAndGroups, null);

      _filePathToTestsAndGroups[filePath] = testsAndGroups;

      if (suite.isGoldenTest) {
        _goldenTestSuites.add(suiteViewModel);
      } else {
        _regularTestSuites.add(suiteViewModel);
      }
    }

    return viewModels;
  }

  /// Adds the [testNode] and its children to the [tests].
  _TestViewModel _addToViewModel(
    List<_TestViewModel> tests,
    TestNode testNode,
    List<_TestViewModel> allSuiteTestsAndGroups,
    _TestViewModel? parent,
  ) {
    final viewModel = _testNodeToViewModel(testNode);

    if (parent != null) {
      viewModel._parent = parent;
    }

    if (testNode is! TestSuite) {
      allSuiteTestsAndGroups.add(viewModel);
      _fullNameToTestsAndGroups[viewModel.fullName] = viewModel;
    }

    tests.add(viewModel);

    for (final child in testNode.children) {
      _addToViewModel(viewModel.children, child, allSuiteTestsAndGroups, viewModel);
    }

    return viewModel;
  }

  /// Creates the data structure used by the tree view from the view models.
  ///
  /// Optionally filters the view models using [filter].
  List<_TestNodeViewModelTreeViewNode> _createTreeFromViewModels(
    List<_TestViewModel> viewModels, [
    bool Function(_TestViewModel)? filter,
  ]) {
    final tree = <_TestNodeViewModelTreeViewNode>[];

    for (int i = 0; i < viewModels.length; i++) {
      final viewModel = viewModels[i];

      final testsAndGroups = <_TestViewModel>[];
      _addToTree(tree, viewModel, testsAndGroups, filter);

      _filePathToSuiteIndex[viewModel.filePath] = i;
      _filePathToTestsAndGroups[viewModel.filePath] = testsAndGroups;
    }

    return tree;
  }

  /// Adds the [viewModel] and its children to the [tree].
  ///
  /// Optionally filters the view models using [filter].
  void _addToTree(
    List<_TestNodeViewModelTreeViewNode> tree,
    _TestViewModel viewModel,
    List<_TestViewModel> allSuiteTestsAndGroups,
    bool Function(_TestViewModel)? filter,
  ) {
    if (viewModel.type == _TestNodeType.suite) {
      allSuiteTestsAndGroups.add(viewModel);
      _fullNameToTestsAndGroups[viewModel.fullName] = viewModel;
    }

    // We need to gather the children before creating the node. Otherwise, we cannot
    // create the node as expanded.
    final children = <_TestNodeViewModelTreeViewNode>[];
    for (final child in viewModel.children) {
      _addToTree(children, child, allSuiteTestsAndGroups, filter);
    }

    final treeNode = _TestNodeViewModelTreeViewNode(
      viewModel,
      children: children,
      expanded: true,
    );

    if (filter == null || filter(viewModel)) {
      tree.add(treeNode);
    }

    _testFullNameToTreeNode[viewModel.fullName] = treeNode;
  }

  /// Converts a [TestNode] to a [_TestViewModel].
  _TestViewModel _testNodeToViewModel(TestNode node) {
    final viewModel = _TestViewModel(
      name: node.name,
      fullName: node.fullName,
      displayName: node is TestSuite //
          ? path.basename(File.fromUri(Uri.parse(node.fileUri)).path)
          : node.name,
      filePath: node is TestSuite ? File.fromUri(Uri.parse(node.fileUri)).path : '',
      type: switch (node) {
        TestSuite() => _TestNodeType.suite,
        TestItem() => _TestNodeType.test,
        TestGroup() => _TestNodeType.group,
      },
    );

    return viewModel;
  }

  void _onFilterChanged() {
    final filter = _filterController.text.toPlainText();

    // Don't update the tree if the filter hasn't changed.
    //
    // This prevents re-rendering when the search field lose focus and has its selection cleared.
    if (filter == _lastFilter) {
      return;
    }

    _lastFilter = filter;

    setState(() {
      // Updates the tree with the new filter.
      _tree = _createTreeFromViewModels(
        _currentTestSuites,
        (viewModel) => _viewModelMatchesFilter(viewModel, filter),
      );
    });
  }

  /// Returns whether or not the given [viewModel] matches the [filter].
  bool _viewModelMatchesFilter(_TestViewModel viewModel, String filter) {
    if (filter.isEmpty) {
      return true;
    }

    // TODO: Implement the filter logic to handle exclusions and tags.
    if (viewModel.fullName.contains(filter)) {
      return true;
    }

    // Consider the parent to match the filter if any of its children match the filter.
    return viewModel.children.any((e) => _viewModelMatchesFilter(e, filter));
  }

  /// Runs all tests in the tree.
  ///
  /// If the regular tests are being displayed, only the regular tests are run.
  ///
  /// If the golden tests are being displayed, only the golden tests are run.
  ///
  /// If [updateGoldens] is `true`, the golden files are re-generated.
  Future<void> _runAllTests({
    bool updateGoldens = false,
  }) async {
    /// Marks all tests as running.
    setState(() {
      for (final viewModel in _currentTestSuites) {
        _traverseViewModelTree(viewModel, (viewModel) {
          viewModel.status = _TestStatus.running;
          viewModel.totalTests = 0;
          viewModel.passedTests = 0;
        });
      }
    });

    final topMostDirectory = _findRootDirectory(_currentTestSuites);
    await _runTests(
      TestRunnerFilter(
        fileNameOrDirectory: topMostDirectory,
        updateGoldens: updateGoldens,
      ),
    );
  }

  /// Runs each test in the tree for the given [node].
  ///
  /// - If [node] is a test, only that test is run.
  /// - If [node] is a group, all tests in the group are run.
  /// - If [node] is a suite, all tests in the suite are run.
  Future<void> _runTestsForNode(_TestNodeViewModelTreeViewNode node) async {
    final viewModel = node.content;

    _traverseViewModelTree(
      viewModel,
      (viewModel) {
        viewModel.status = _TestStatus.running;
        viewModel.totalTests = 0;
        viewModel.passedTests = 0;
      },
    );

    _traverseParentViewModelTree(
      viewModel,
      (viewModel) {
        viewModel.status = _TestStatus.running;
        viewModel.totalTests = 0;
        viewModel.passedTests = 0;
      },
    );

    final filter = viewModel.type == _TestNodeType.suite //
        ? TestRunnerFilter(fileNameOrDirectory: viewModel.filePath)
        : TestRunnerFilter(
            fileNameOrDirectory: _findFileNameFromTest(viewModel),
            plainName: viewModel.fullName,
          );

    await _runTests(filter);
  }

  /// Run the tests that match the given [filter].
  ///
  /// Does nothing if a test is already running.
  Future<void> _runTests(TestRunnerFilter filter) async {
    if (_hasTestRunning) {
      // Don't run multiple tests simultaneously.
      return;
    }

    // Reset the mappings because the test IDs will be different.
    _runnerTestIdToTestViewModel.clear();
    _runnerGroupIdToGroupNotification.clear();

    try {
      _hasTestRunning = true;

      await runner.runTests(filter);
    } finally {
      setState(() {
        // If somehow the tests are not completed, reset the status.
        for (final suite in _currentTestSuites) {
          _traverseViewModelTree(suite, (viewModel) {
            if (viewModel.status == _TestStatus.running) {
              viewModel.status = _TestStatus.none;
            }
          });
        }
        _hasTestRunning = false;
      });
    }
  }

  String? _findRootDirectory(List<_TestViewModel> viewModels) {
    String? rootDirectory;
    for (final viewModel in viewModels) {
      if (rootDirectory == null || !path.isWithin(rootDirectory, viewModel.filePath)) {
        rootDirectory = path.dirname(viewModel.filePath);
      }
    }

    return rootDirectory;
  }

  String? _findFileNameFromTest(_TestViewModel viewModel) {
    if (viewModel.type == _TestNodeType.suite) {
      return viewModel.filePath;
    }

    if (viewModel.parent == null) {
      return null;
    }

    return _findFileNameFromTest(viewModel.parent!);
  }

  /// Handles the test notifications from the test runner.
  ///
  /// The notifications are used to update the status of the tests in the UI.
  void _onTestNotification(FlutterTestNotification notification) {
    switch (notification) {
      case FlutterTestStartNotification():
        _handleTestStartNotification(notification);
        break;
      case FlutterTestErrorNotification():
        _handleTestErrorNotification(notification);
        break;
      case FlutterTestDoneNotification():
        _handleTestDoneNotification(notification);
        break;
      case FlutterTestGroupNotification():
        _handleTestGroupNotification(notification);
        break;
      default:
        break;
    }
  }

  /// Handles a test group being reported by the test runner.
  void _handleTestGroupNotification(FlutterTestGroupNotification notification) {
    _runnerGroupIdToGroupNotification[notification.id] = notification;
  }

  /// Handles the start of a test being reported by the test runner.
  void _handleTestStartNotification(FlutterTestStartNotification notification) {
    if (notification.name.startsWith('loading')) {
      // This notification means the dart tester is loading the test file.
      return;
    }

    final test = _findTest(notification.name) ?? _maybeCreateViewModelForCustomTestGroup(notification);
    if (test == null) {
      return;
    }

    _runnerTestIdToTestViewModel[notification.id] = test;

    setState(() {
      test.status = _TestStatus.running;
    });
  }

  /// Handles an error being reported by the test runner.
  void _handleTestErrorNotification(FlutterTestErrorNotification notification) {
    final testViewModel = _runnerTestIdToTestViewModel[notification.testID];
    if (testViewModel == null) {
      // We don't know about this test. Fizzle.
      return;
    }

    setState(() {
      testViewModel.errorMessage = notification.error;
      testViewModel.stackTrace = notification.stackTrace;
    });
  }

  /// Handles the end of a test being reported by the test runner.
  ///
  /// This is fired even when the test fails.
  void _handleTestDoneNotification(FlutterTestDoneNotification notification) {
    final testViewModel = _runnerTestIdToTestViewModel[notification.testID];
    if (testViewModel == null) {
      // We don't know about this test. Fizzle.
      return;
    }

    setState(() {
      testViewModel.status = switch (notification.result) {
        'success' => _TestStatus.success,
        'error' => _TestStatus.failure,
        'failure' => _TestStatus.failure,
        _ => _TestStatus.none,
      };

      // Computes the number of tests that passed and failed for all the tests.
      final rootNode = _findRootTest(testViewModel);
      if (rootNode != null) {
        _computeGroupStatus(rootNode);
      }
    });
  }

  /// Computes the number of total tests, tests that passed and failed and if there is any test in progress
  /// for the given [viewModel].
  (int passed, int failed, int totalTests, bool running) _computeGroupStatus(_TestViewModel viewModel) {
    int passed = 0;
    int failed = 0;
    int totalTests = 0;

    if (viewModel.children.isEmpty) {
      // This is a test, not a group.
      totalTests = 1;
      passed = viewModel.status == _TestStatus.success ? 1 : 0;
      failed = viewModel.status == _TestStatus.failure ? 1 : 0;

      viewModel.totalTests = totalTests;
      viewModel.failedTests = failed;
      viewModel.passedTests = passed;

      return (passed, failed, totalTests, viewModel.status == _TestStatus.running);
    }

    // This is a group or suite.

    bool hasTestInProgress = false;
    for (final child in viewModel.children) {
      final (childPassed, childFailed, childTotal, running) = _computeGroupStatus(child);
      passed += childPassed;
      failed += childFailed;
      totalTests += childTotal;

      if (running) {
        hasTestInProgress = true;
      }
    }

    viewModel.totalTests = totalTests;
    viewModel.passedTests = passed;

    if (hasTestInProgress) {
      viewModel.status = _TestStatus.running;
    } else if (failed > 0) {
      viewModel.status = _TestStatus.failure;
    } else if (passed > 0) {
      viewModel.status = _TestStatus.success;
    } else {
      viewModel.status = _TestStatus.none;
    }

    return (viewModel.passedTests, viewModel.failedTests, viewModel.totalTests, hasTestInProgress);
  }

  /// Finds the root view model for the given [viewModel].
  ///
  /// Usually the root view model is the suite view model.
  _TestViewModel? _findRootTest(_TestViewModel viewModel) {
    _TestViewModel? currentViewModel = viewModel;
    _TestViewModel? parent;

    while (currentViewModel?.parent != null) {
      parent = currentViewModel?.parent;

      currentViewModel = parent;
    }

    return parent;
  }

  /// Finds the test view model for the test with the given [fullName].
  _TestViewModel? _findTest(String fullName) {
    final test = _fullNameToTestsAndGroups[fullName];
    if (test != null) {
      return test;
    }

    return null;
  }

  /// If the test reported in the [notification] is a test ran by a custom test group method,
  /// creates a view model for the test.
  ///
  /// That are methods in the flutter_test_runner package that run multiple test variants for a single test.
  /// For example, `testWidgetsOnDesktop` runs the same test for macOS, Windows and Linux. When discovering
  /// the tests, only the group is reported, not the individual tests. Then, when the tests are run, the individual
  /// tests are reported. This method creates the view model for the individual tests.
  _TestViewModel? _maybeCreateViewModelForCustomTestGroup(FlutterTestStartNotification notification) {
    if (notification.groupIDs.isEmpty) {
      // This isn't a test ran by a custom test group method.
      return null;
    }

    // The group ids starts from the innermost group and go outwards, so the custom group method
    // must be the first.
    final group = _runnerGroupIdToGroupNotification[notification.groupIDs.first];
    if (group == null) {
      // We don't know about this group. Fizzle.
      return null;
    }

    if (group.name.isNotEmpty) {
      // The groups that are ran by custom test group methods don't have a name. Since this group
      // has a name, it's not a custom test group method.
      return null;
    }

    // The group of this test seems to be a custom test group method. The custom test groups that we support
    // add a suffix to the test name. For example:
    //
    // `testWidgetsOnDesktop('my test', (tester) { ... });`
    //
    // The custom test group will generate the following tests:
    // - `my test (on macOS)`
    // - `my test (on Windows)`
    // - `my test (on Linux)`
    //
    // We try to remove the suffix to find the group view model that has the "base name" (my test).
    String testName = notification.name;
    while (true) {
      final testWithoutSuffix = _removeTestSuffix(testName);
      if (testWithoutSuffix == testName) {
        // There isn't a suffix to remove. Fizzle.
        break;
      }

      final groupViewModel = _fullNameToTestsAndGroups[testWithoutSuffix];
      if (groupViewModel == null) {
        // We couldn't find the group view model. Try to continue remove other suffixes, if any.
        continue;
      }

      // We found the test group view model. Create the test view model.
      final suffix = testName.substring(testWithoutSuffix.length).trim();
      final newViewModel = _TestViewModel(
        name: suffix,
        fullName: notification.name,
        displayName: suffix,
        type: _TestNodeType.test,
        parent: groupViewModel,
      );
      groupViewModel.children.add(newViewModel);
      _fullNameToTestsAndGroups[notification.name] = newViewModel;

      // Add a new node to the test tree view.
      final treeNode = _testFullNameToTreeNode[groupViewModel.fullName];
      if (treeNode != null) {
        treeNode.children.add(TreeViewNode(newViewModel));
      }

      return newViewModel;
    }

    // We couldn't find the group view model.
    return null;
  }

  /// Removes the suffix delimited by parenthesis from the [testName].
  ///
  /// For example, for `my test (on macOS)` this method returns `my test`.
  String _removeTestSuffix(String testName) {
    if (!testName.endsWith(')')) {
      // If the test name doesn't end with a parenthesis, it means there isn't a suffix that we support.
      return testName;
    }

    final lastOpenParenthesisIndex = testName.lastIndexOf('(');
    if (lastOpenParenthesisIndex < 0) {
      return testName;
    }

    return testName.substring(0, lastOpenParenthesisIndex).trim();
  }

  /// Traverse the view model tree and apply the [action] to each view model.
  void _traverseViewModelTree(_TestViewModel viewModel, void Function(_TestViewModel viewModel) action) {
    action(viewModel);

    for (final chilViewModel in viewModel.children) {
      action(chilViewModel);
      _traverseViewModelTree(chilViewModel, action);
    }
  }

  /// Traverse the parent view model tree and apply the [action] to each view model.
  void _traverseParentViewModelTree(_TestViewModel viewModel, void Function(_TestViewModel viewModel) action) {
    _TestViewModel? parent = viewModel.parent;
    while (parent != null) {
      action(parent);
      parent = parent.parent;
    }
  }

  void _onChangeTab(int tabIndex) {
    if (_hasTestRunning) {
      // Preserve the current tab while tests are
      return;
    }

    setState(() {
      _panelKind = tabIndex == 0 ? _TestPanelKind.regularTests : _TestPanelKind.goldenTests;
      _tree = _createTreeFromViewModels(_currentTestSuites);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDiscovering) {
      return _buildProgressIndicator();
    }

    return Column(
      children: [
        _buildTopSection(),
        Expanded(
          child: _buildTestTreeView(),
        ),
        const Divider(color: dividerColor),
        _buildBottomSection(),
      ],
    );
  }

  /// Builds the progress indicator to be displayed while we're still discovering the tests.
  Widget _buildProgressIndicator() {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 8),
          Text('Discovering tests...'),
        ],
      ),
    );
  }

  /// Displays buttons to run all tests and update goldens and a filter field to filter the tests.
  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('TESTING', style: TextStyle(fontSize: 14)),
              const Spacer(),
              SizedBox(
                width: 30,
                child: TriStateIconButton(
                  icon: Icons.play_arrow,
                  iconSize: 24,
                  iconColor: Colors.white,
                  tooltip: 'Run all tests',
                  onPressed: _runAllTests,
                ),
              ),
              if (_panelKind == _TestPanelKind.goldenTests) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: TriStateIconButton(
                    icon: Icons.image_outlined,
                    iconSize: 24,
                    iconColor: Colors.white,
                    tooltip: 'Update goldens',
                    onPressed: () => _runAllTests(updateGoldens: true),
                  ),
                ),
              ]
            ],
          ),
          _buildFilterField(),
        ],
      ),
    );
  }

  Widget _buildFilterField() {
    return TapRegion(
      groupId: 'test_filter',
      onTapOutside: (event) => FocusScope.of(context).unfocus(),
      child: SuperDesktopTextField(
        textController: _filterController,
        tapRegionGroupId: 'test_filter',
        decorationBuilder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: panelLowColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        ),
        padding: const EdgeInsets.all(8.0),
        hintBuilder: (context) => Text(
          'Filter (e.g, text, !exclude)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        hintBehavior: HintBehavior.displayHintUntilTextEntered,
        caretStyle: CaretStyle(color: Colors.white.withValues(alpha: 0.5)),
        textStyleBuilder: (attributions) => const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  /// Displays all suites, groups and tests in a tree view.
  Widget _buildTestTreeView() {
    return IconTheme(
      data: const IconThemeData(
        color: Colors.white,
      ),
      child: Scrollbar(
        controller: _verticalController,
        thumbVisibility: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LayoutBuilder(builder: (context, constraints) {
            return TreeView<_TestViewModel>(
              controller: _treeController,
              verticalDetails: ScrollableDetails.vertical(
                controller: _verticalController,
              ),
              horizontalDetails: const ScrollableDetails.horizontal(
                physics: NeverScrollableScrollPhysics(),
              ),
              // No internal indentation, the custom treeNodeBuilder applies its
              // own indentation to decorate in the indented space.
              indentation: TreeViewIndentationType.none,
              tree: _tree,
              onNodeToggle: (_TestNodeViewModelTreeViewNode node) {},
              treeNodeBuilder: (context, node, animationStyle) =>
                  _treeNodeBuilder(context, node, animationStyle, constraints.maxWidth),
              treeRowBuilder: _treeRowBuilder,
            );
          }),
        ),
      ),
    );
  }

  TreeRow _treeRowBuilder(_TestNodeViewModelTreeViewNode node) {
    return TreeRow(
      extent: const FixedTreeRowExtent(
        _rowHeight,
      ),
      cursor: SystemMouseCursors.click,
      onEnter: (event) => {
        setState(() {
          _hoveredNode = node;
        }),
      },
      onExit: (event) => {
        setState(() {
          _hoveredNode = null;
        })
      },
    );
  }

  Widget _treeNodeBuilder(
    BuildContext context,
    _TestNodeViewModelTreeViewNode node,
    AnimationStyle toggleAnimationStyle,
    double maxWidth,
  ) {
    final viewModel = node.content;

    final isParentNode =
        viewModel.type == _TestNodeType.suite || viewModel.type == _TestNodeType.group && viewModel.children.isNotEmpty;

    return SizedBox(
      width: maxWidth,
      child: HoverBox(
        baseDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: GestureDetector(
          onTap: () {
            node.isExpanded //
                ? _treeController.collapseNode(node)
                : _treeController.expandNode(node);
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  // Custom indentation
                  SizedBox(width: 8.0 * node.depth! + 8.0),
                  // Leading icon for parent nodes
                  SizedBox(
                    width: 12,
                    child: isParentNode
                        ? //
                        GestureDetector(
                            onTap: () {
                              node.isExpanded //
                                  ? _treeController.collapseNode(node)
                                  : _treeController.expandNode(node);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Transform.rotate(
                              //alignment: Alignment.topCenter,
                              angle: node.isExpanded ? pi / 2 : 0,
                              child: Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: IconTheme.of(context).color!.withValues(alpha: 0.25),
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Spacer
                  const SizedBox(width: 8),
                  // Content
                  Flexible(
                    child: Row(
                      children: [
                        _getIconForNode(node),
                        const SizedBox(width: 8),
                        Flexible(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            text: TextSpan(
                              text: viewModel.displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              children: [
                                if (viewModel.children.isNotEmpty && viewModel.totalTests > 0) //
                                  TextSpan(
                                    text: ' ${viewModel.passedTests}/${viewModel.totalTests} passed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_hoveredNode == node) ...[
                Positioned(
                  right: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 30,
                        child: TriStateIconButton(
                          icon: Icons.play_arrow,
                          iconSize: 24,
                          iconColor: Colors.white,
                          onPressed: () => _runTestsForNode(node),
                        ),
                      ),
                      if (_panelKind == _TestPanelKind.goldenTests) ...[
                        SizedBox(
                          width: 30,
                          child: TriStateIconButton(
                            icon: Icons.image_outlined,
                            iconSize: 24,
                            iconColor: Colors.white,
                            onPressed: () => _runTestsForNode(node),
                          ),
                        )
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the bottom section with tabs to switch between regular tests and golden tests.
  Widget _buildBottomSection() {
    return BottomNavigationBar(
      showSelectedLabels: false,
      showUnselectedLabels: false,
      backgroundColor: panelHighColor,
      elevation: 0,
      selectedItemColor: Colors.white.withValues(alpha: 0.5),
      onTap: _onChangeTab,
      currentIndex: _panelKind == _TestPanelKind.regularTests ? 0 : 1,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.science_outlined),
          label: 'Regular Tests',
          tooltip: 'Regular Tests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.image),
          label: 'Golden Tests',
          tooltip: 'Golden Tests',
        ),
      ],
    );
  }

  Widget _getIconForNode(_TestNodeViewModelTreeViewNode node) {
    final viewModel = node.content;

    return switch (viewModel.status) {
      _TestStatus.none => Icon(
          Icons.circle_outlined,
          size: 12,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      _TestStatus.running => const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(),
        ),
      _TestStatus.success => const Icon(
          Icons.check_circle,
          size: 12,
          color: Colors.green,
        ),
      _TestStatus.failure => const Icon(
          Icons.error,
          size: 12,
          color: Colors.red,
        ),
      _TestStatus.skipped => const Icon(
          Icons.circle,
          size: 12,
          color: Colors.yellow,
        ),
    };
  }
}

typedef _TestNodeViewModelTreeViewNode = TreeViewNode<_TestViewModel>;

/// Holds all the data necessary to render a suite, group or test in the UI.
class _TestViewModel {
  _TestViewModel({
    required this.name,
    required this.fullName,
    required this.displayName,
    required this.type,
    this.filePath = '',
    List<_TestViewModel>? children,
    _TestViewModel? parent,
  })  : children = children ?? <_TestViewModel>[],
        _parent = parent,
        status = _TestStatus.none,
        errorMessage = '',
        stackTrace = '',
        totalTests = 0,
        passedTests = 0,
        failedTests = 0;

  /// The name of the test, group or suite.
  final String name;

  /// The full name of the test, group or suite.
  ///
  /// The full name is the name of the test or group and all its parent groups. For example, if we have
  /// the following test hierarchy:
  ///
  /// ```
  /// group('group 1', () {
  ///   group('subgroup 1', () {
  ///     test('test 1', () {
  ///     });
  ///   });
  /// });
  /// ```
  ///
  /// The full name of `test 1` is `group 1 subgroup 1 test 1`.
  final String fullName;

  /// The display name of the test, group or suite, as it should be displayed on the treeview.
  final String displayName;

  final _TestNodeType type;

  /// The file path of the test suite.
  final String filePath;

  /// The status of the test.
  _TestStatus status;

  /// The error message if the test failed.
  String errorMessage;

  /// The stack trace if the test failed.
  String stackTrace;

  /// The total number of tests in the group or suite.
  int totalTests;

  /// The number of tests that passed in the group or suite.
  int passedTests;

  /// The number of tests that failed in the group or suite.
  int failedTests;

  /// The parent of the test or group.
  _TestViewModel? get parent => _parent;
  _TestViewModel? _parent;

  /// The children of the group or suite.
  final List<_TestViewModel> children;
}

enum _TestNodeType {
  /// A test suite, i.e., a file that contains tests.
  suite,

  /// A test group.
  group,

  /// A single test.
  test,
}

enum _TestStatus {
  /// The test never ran or we don't have any information about it.
  none,

  /// The test is currently running.
  running,

  /// The test passed.
  success,

  /// The test failed.
  failure,

  /// The test was skipped.
  skipped,
}

enum _TestPanelKind {
  regularTests,
  goldenTests,
}
