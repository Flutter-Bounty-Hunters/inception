import 'package:flutter/widgets.dart';

extension RenderBoxMappings on RenderBox {
  /// Returns a [Rect] whose position and size is calculated by taking the given [localRect]
  /// within this [RenderBox]'s coordinate space, and projecting it into the [ancestor]
  /// coordinate space, or the global coordinate space if [ancestor] is `null`.
  ///
  /// No checks or adjustments are done to handle the possibility of rotation or skewing.
  /// Therefore, it is generally assumed that this method will only be called with axis-aligned
  /// render objects.
  Rect localRectToGlobal(
    Rect localRect, {
    RenderObject? ancestor,
  }) {
    final globalTopLeft = localToGlobal(localRect.topLeft, ancestor: ancestor);
    final globalBottomRight = localToGlobal(localRect.bottomRight, ancestor: ancestor);
    return Rect.fromPoints(globalTopLeft, globalBottomRight);
  }
}
