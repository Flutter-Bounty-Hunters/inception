import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';

/// A widget that adds a border around its [child].
///
/// If [color] isn't provided, this widget checks the platform brightness and then
/// paints a black border in light mode, and a white border in dark mode.
class BorderBox extends StatelessWidget {
  const BorderBox({
    super.key,
    this.color,
    this.width = 1,
    this.isEnabled = true,
    required this.child,
  });

  final Color? color;
  final double width;
  final bool isEnabled;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: isEnabled
            ? Border.all(
                width: width,
                color: color ??
                    switch (MediaQuery.platformBrightnessOf(context)) {
                      Brightness.dark => Colors.white,
                      Brightness.light => Colors.black,
                    },
              )
            : null,
      ),
      child: child,
    );
  }
}
