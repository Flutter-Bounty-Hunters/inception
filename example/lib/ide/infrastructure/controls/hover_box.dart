import 'package:flutter/material.dart';

/// A widget that changes its decoration when hovered.
class HoverBox extends StatefulWidget {
  const HoverBox({
    super.key,
    required this.baseDecoration,
    required this.hoverColor,
    required this.child,
  });

  final BoxDecoration baseDecoration;
  final Color hoverColor;
  final Widget child;

  @override
  State<HoverBox> createState() => _HoverBoxState();
}

class _HoverBoxState extends State<HoverBox> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovering = true;
      }),
      onExit: (_) => setState(() {
        _isHovering = false;
      }),
      child: DecoratedBox(
        decoration: widget.baseDecoration.copyWith(
          color: _isHovering ? widget.hoverColor : Colors.transparent,
        ),
        child: widget.child,
      ),
    );
  }
}
