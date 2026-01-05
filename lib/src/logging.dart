import 'package:logging/logging.dart';

export 'package:logging/logging.dart' show Level;

abstract class InceptionLog {
  static final ux = Logger("inception.ux");
  static final gestures = Logger("inception.ux.gestures");
  static final input = Logger("inception.ux.input");

  static final _activeLoggers = <Logger>{};

  /// Send log output from all loggers, at or above the given [level], to the terminal.
  static void initAllLogs([Level level = Level.INFO]) {
    initLoggers({Logger.root}, level);
  }

  /// Send output from the given [loggers], at or above the given [level], to the terminal.
  static void initLoggers(Set<Logger> loggers, [Level level = Level.INFO]) {
    hierarchicalLoggingEnabled = true;

    for (final logger in loggers) {
      if (!_activeLoggers.contains(logger)) {
        print('Initializing logger: ${logger.name}');
        logger
          ..level = level
          ..onRecord.listen(_printLog);

        _activeLoggers.add(logger);
      } else {
        // The logger is already active. Adjust the log level as desired.
        logger.level = level;
      }
    }
  }

  /// Returns `true` if the given [logger] is currently logging, or
  /// `false` otherwise.
  ///
  /// Generally, developers should call loggers, regardless of whether
  /// a given logger is active. However, sometimes you may want to log
  /// information that's costly to compute. In such a case, you can
  /// choose to compute the expensive information only if the given
  /// logger will actually log the information.
  static bool isLogActive(Logger logger) {
    return _activeLoggers.contains(logger);
  }

  /// Stop the given [loggers] from sending any output to the terminal.
  static void deactivateLoggers(Set<Logger> loggers) {
    for (final logger in loggers) {
      if (_activeLoggers.contains(logger)) {
        print('Deactivating logger: ${logger.name}');
        logger.clearListeners();

        _activeLoggers.remove(logger);
      }
    }
  }

  static void _printLog(LogRecord record) {
    print(
      '(${record.time.second}.${record.time.millisecond.toString().padLeft(3, '0')}) ${record.loggerName} > ${record.level.name}: ${record.message}',
    );
  }

  const InceptionLog._();
}
