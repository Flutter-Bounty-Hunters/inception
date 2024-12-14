import 'package:flutter/widgets.dart';

class IncreaseFontSizeIntent extends Intent {
  const IncreaseFontSizeIntent();
}

class DecreaseFontSizeIntent extends Intent {
  const DecreaseFontSizeIntent();
}

/// An [Intent] that represents the user desire to open the
/// code actions popover.
class CodeActionsIntent extends Intent {
  const CodeActionsIntent();
}
