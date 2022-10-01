const codeString = '''/// Information provided to a [BitmapPainter] so that the painter can paint a single
/// frame.
class BitmapPaintingContext implements MyInterface1, MyInterface2 {
  BitmapPaintingContext({
    required this.canvas,
    required this.size,
    required this.elapsedTime,
    required this.timeSinceLastFrame,
  });

  /// The canvas to paint with.
  final BitmapCanvas canvas;

  /// The size of the canvas.
  final Size size;

  /// The total time that the owning [BitmapPaint] has been painting frames.
  ///
  /// This time is reset whenever a [BitmapPaint] pauses rendering.
  final Duration elapsedTime;

  /// The delta-time since the last frame was painted.
  final Duration timeSinceLastFrame;
}''';

const codeString2 = '''class BitmapPainter {
  const BitmapPainter.fromCallback(this._paint);

  final Future<void> Function(BitmapPaintingContext)? _paint;

  Future<void> paint(BitmapPaintingContext paintingContext) async {
    if (_paint == null) {
      return;
    }

    await _paint!(paintingContext);
  }
}''';

const codeString3 = '''/// The playback mode for a [BitmapPaint] widget.
enum PlaybackMode {
  /// Renders only a single frame.
  singleFrame,

  /// Continuously renders frames.
  continuous,
}''';

const codeString4 = '''void initAllLogs(logging.Level level) {
  initLoggers(level, {logging.Logger.root});
}

void initLoggers(logging.Level level, Set<logging.Logger> loggers) {
  logging.hierarchicalLoggingEnabled = true;

  for (final logger in loggers) {
    if (!_activeLoggers.contains(logger)) {
      print('Initializing logger: ');
      logger
        ..level = level
        ..onRecord.listen(printLog);

      _activeLoggers.add(logger);
    }
  }
}''';
