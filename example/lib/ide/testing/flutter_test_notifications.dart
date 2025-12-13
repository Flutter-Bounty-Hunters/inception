/// A notification reported by the `flutter test` command.
///
/// The `flutter test` command reports various events during the execution of tests,
/// such as the start and end of a test run, the start and end of a test, etc.
sealed class FlutterTestNotification {}

/// A notification that the `flutter test` command has started running tests.
class FlutterTestRunStartNotification extends FlutterTestNotification {
  final String protocolVersion;
  final String? runnerVersion;
  final int pid;
  final String type;
  final int time;

  FlutterTestRunStartNotification({
    required this.protocolVersion,
    this.runnerVersion,
    required this.pid,
    required this.type,
    required this.time,
  });

  factory FlutterTestRunStartNotification.fromJson(Map<String, dynamic> json) {
    return FlutterTestRunStartNotification(
      protocolVersion: json['protocolVersion'] as String,
      runnerVersion: json['runnerVersion'] as String?,
      pid: json['pid'] as int,
      type: json['type'] as String,
      time: json['time'] as int,
    );
  }
}

/// A notification that the `flutter test` command has finished running tests.
class FlutterTestRunDoneNotification extends FlutterTestNotification {
  final bool success;
  final String type;
  final int time;

  FlutterTestRunDoneNotification({
    required this.success,
    required this.type,
    required this.time,
  });

  factory FlutterTestRunDoneNotification.fromJson(Map<String, dynamic> json) {
    return FlutterTestRunDoneNotification(
      success: json['success'] as bool,
      type: json['type'] as String,
      time: json['time'] as int,
    );
  }
}

/// A notification that the `flutter test` command discovered a test suite.
class FlutterTestSuiteNotification extends FlutterTestNotification {
  final int id;
  final String platform;
  final String path;
  final String type;
  final int time;

  FlutterTestSuiteNotification({
    required this.id,
    required this.platform,
    required this.path,
    required this.type,
    required this.time,
  });

  factory FlutterTestSuiteNotification.fromJson(Map<String, dynamic> json) {
    return FlutterTestSuiteNotification(
      id: json['suite']['id'] as int,
      platform: json['suite']['platform'] as String,
      path: json['suite']['path'] as String,
      type: json['type'] as String,
      time: json['time'] as int,
    );
  }
}

/// A notification that the `flutter test` command has started running a test.
class FlutterTestStartNotification extends FlutterTestNotification {
  final int id;
  final String name;
  final int suiteID;
  final List<int> groupIDs;
  final bool skip;
  final String? skipReason;
  final int? line;
  final int? column;
  final String? url;
  final String type;
  final int time;

  FlutterTestStartNotification({
    required this.id,
    required this.name,
    required this.suiteID,
    required this.groupIDs,
    required this.skip,
    this.skipReason,
    this.line,
    this.column,
    this.url,
    required this.type,
    required this.time,
  });

  factory FlutterTestStartNotification.fromJson(Map<String, dynamic> json) {
    return FlutterTestStartNotification(
      id: json['test']['id'] as int,
      name: json['test']['name'] as String,
      suiteID: json['test']['suiteID'] as int,
      groupIDs: List<int>.from(json['test']['groupIDs'] as List),
      skip: json['test']['metadata']['skip'] as bool,
      skipReason: json['test']['metadata']['skipReason'] as String?,
      line: json['test']['line'] as int?,
      column: json['test']['column'] as int?,
      url: json['test']['url'] as String?,
      type: json['type'] as String,
      time: json['time'] as int,
    );
  }
}

/// A notification that the `flutter test` command has finished running a test.
class FlutterTestDoneNotification extends FlutterTestNotification {
  final int testID;
  final String result;
  final bool skipped;
  final bool hidden;
  final String type;
  final int time;

  FlutterTestDoneNotification({
    required this.testID,
    required this.result,
    required this.skipped,
    required this.hidden,
    required this.type,
    required this.time,
  });

  factory FlutterTestDoneNotification.fromJson(Map<String, dynamic> json) {
    return FlutterTestDoneNotification(
      testID: json['testID'] as int,
      result: json['result'] as String,
      skipped: json['skipped'] as bool,
      hidden: json['hidden'] as bool,
      type: json['type'] as String,
      time: json['time'] as int,
    );
  }
}

/// A notification that the `flutter test` command has discovered a test group.
class FlutterTestGroupNotification extends FlutterTestNotification {
  final int id;
  final int suiteID;
  final int? parentID;
  final String name;
  final bool skip;
  final String? skipReason;
  final int? line;
  final int? column;
  final String? url;
  final int testCount;
  final String type;
  final int time;

  FlutterTestGroupNotification({
    required this.id,
    required this.suiteID,
    this.parentID,
    required this.name,
    required this.skip,
    this.skipReason,
    this.line,
    this.column,
    this.url,
    required this.testCount,
    required this.type,
    required this.time,
  });

  factory FlutterTestGroupNotification.fromJson(Map<String, dynamic> json) {
    return FlutterTestGroupNotification(
      id: json['group']['id'] as int,
      suiteID: json['group']['suiteID'] as int,
      parentID: json['group']['parentID'] as int?,
      name: json['group']['name'] as String,
      skip: json['group']['metadata']['skip'] as bool,
      skipReason: json['group']['metadata']['skipReason'] as String?,
      line: json['group']['line'] as int?,
      column: json['group']['column'] as int?,
      url: json['group']['url'] as String?,
      testCount: json['group']['testCount'] as int,
      type: json['type'] as String,
      time: json['time'] as int,
    );
  }
}

/// A notification that an error occurred during the execution of a test.
class FlutterTestErrorNotification extends FlutterTestNotification {
  final int testID;
  final String error;
  final String stackTrace;
  final bool isFailure;
  final String type;
  final int time;

  FlutterTestErrorNotification({
    required this.testID,
    required this.error,
    required this.stackTrace,
    required this.isFailure,
    required this.type,
    required this.time,
  });

  factory FlutterTestErrorNotification.fromJson(Map<String, dynamic> json) {
    return FlutterTestErrorNotification(
      testID: json['testID'] as int,
      error: json['error'] as String,
      stackTrace: json['stackTrace'] as String,
      isFailure: json['isFailure'] as bool,
      type: json['type'] as String,
      time: json['time'] as int,
    );
  }
}
