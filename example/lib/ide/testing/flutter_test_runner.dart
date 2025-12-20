import 'dart:convert';
import 'dart:io';

import 'package:example/ide/testing/flutter_test_notifications.dart';

/// Invokes the `flutter test` command and listens for test notifications.
class FlutterTestRunner {
  FlutterTestRunner({
    required this.workingDirectory,
    this.flutterExecutable = 'flutter',
    this.customToolArguments = const [],
    this.onNotification,
  });

  /// The working directory where the tests are run.
  ///
  /// Usually the root of the project.
  final String workingDirectory;

  /// The executable for the Flutter tool.
  final String flutterExecutable;

  /// Custom arguments to pass to the [flutterExecutable].
  ///
  /// For example, when running the tests with FVM, you can pass the `flutter` command
  /// as `fvm` and the custom arguments as `['flutter']`.
  final List<String> customToolArguments;

  /// A callback that is called when a test notification is received.
  final TestNotificationListener? onNotification;

  /// A buffer to store the incoming data until we can parse it.
  String _buffer = '';

  /// Runs the `flutter test` command with the given [filter].
  Future<void> runTests(TestRunnerFilter filter) async {
    _buffer = '';

    final arguments = _generateArguments(filter);

    await _runProcess(
      executable: flutterExecutable,
      arguments: arguments,
      onStdOut: _onData,
      workingDirectory: workingDirectory,
      description: 'Flutter test',
      throwOnError: false,
    );
  }

  List<String> _generateArguments(TestRunnerFilter filter) {
    final arguments = <String>[...customToolArguments];

    arguments.add('test');

    if (filter.updateGoldens) {
      arguments.add('--update-goldens');
    }

    if (filter.name != null) {
      arguments.add('--name');
      arguments.add(filter.name!);
    }

    if (filter.plainName != null) {
      arguments.add('--plain-name');
      arguments.add(filter.plainName!);
    }

    if (filter.fileNameOrDirectory != null) {
      arguments.add(filter.fileNameOrDirectory!);
    }

    if (filter.concurrency != null) {
      arguments.add('--concurrency');
      arguments.add(filter.concurrency.toString());
    }

    arguments
      ..add('--reporter')
      ..add('json');

    return arguments;
  }

  /// Handles the stdout data from the process.
  void _onData(List<int> event) {
    final data = String.fromCharCodes(event);
    _buffer += data;

    while (_tryParse()) {
      // Keep trying to parse until we either finish parsing the message
      // or we reach the end of the data buffer.
    }
  }

  bool _tryParse() {
    final newLineIndex = _buffer.indexOf('\n');

    if (newLineIndex < 0) {
      // We need a full line to parse the message.
      return false;
    }

    final message = _buffer.substring(0, newLineIndex);
    _buffer = _buffer.substring(newLineIndex + 1);

    if (message.isEmpty) {
      return false;
    }

    if (!message.startsWith('{') || !message.endsWith('}')) {
      // This is not a JSON message. Ignore it.
      return false;
    }

    // Don't bother parsing if there isn't a listener.
    if (onNotification != null) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final notification = _parseNotification(data);
      if (notification != null) {
        onNotification!(notification);
      }
    }

    return true;
  }

  FlutterTestNotification? _parseNotification(Map<String, dynamic> data) {
    final type = data['type'] as String;

    return switch (type) {
      'start' => FlutterTestRunStartNotification.fromJson(data),
      'suite' => FlutterTestSuiteNotification.fromJson(data),
      'testStart' => FlutterTestStartNotification.fromJson(data),
      'testDone' => FlutterTestDoneNotification.fromJson(data),
      'group' => FlutterTestGroupNotification.fromJson(data),
      'error' => FlutterTestErrorNotification.fromJson(data),
      'done' => FlutterTestRunDoneNotification.fromJson(data),
      _ => null,
    };
  }

  /// Runs [executable] with the given [arguments].
  ///
  /// [executable] could be an absolute path or it could be resolved from the PATH.
  ///
  /// The [arguments] must contain any modifiers, like `-`, `--` or `/`.
  ///
  /// Use [workingDirectory] to set the working directory for the process.
  ///
  /// The child process stdout and stderr are written to the current process stdout.
  ///
  /// If [throwOnError] is `true`, throws an exception if the process exits with a non-zero exit code.
  ///
  /// If [throwOnError] is `false`, the function returns the exit code.
  Future<int> _runProcess({
    required String executable,
    required List<String> arguments,
    required String description,
    void Function(List<int> event)? onStdOut,
    String? workingDirectory,
    bool throwOnError = true,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );

    final subscription = process.stdout.listen(onStdOut);
    try {
      await stderr.addStream(process.stderr);

      final exitCode = await process.exitCode;

      if (exitCode != 0 && throwOnError) {
        throw Exception('$description failed');
      }

      return exitCode;
    } finally {
      subscription.cancel();
    }
  }
}

/// A filter to run tests with specific parameters.
class TestRunnerFilter {
  TestRunnerFilter({
    this.fileNameOrDirectory,
    this.name,
    this.plainName,
    this.tags,
    this.updateGoldens = false,
    this.concurrency,
  });

  final String? fileNameOrDirectory;
  final String? name;
  final String? plainName;
  final String? tags;
  final bool updateGoldens;
  final int? concurrency;
}

/// A callback that is called when a test notification is received.
typedef TestNotificationListener = void Function(FlutterTestNotification notification);
