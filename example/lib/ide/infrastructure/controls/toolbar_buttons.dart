import 'package:flutter/material.dart';

class VerticalIconButtonToolbar extends StatelessWidget {
  const VerticalIconButtonToolbar({
    super.key,
    this.width = 40,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    this.iconSize = 18,
    this.iconColor = const Color(0xFFCCCCCC),
    this.iconSpacing = 12,
    this.background = const Color(0xFF202224),
    required this.icons,
    required this.onIconButtonPressed,
  });

  final double width;
  final EdgeInsets padding;
  final double iconSize;
  final Color iconColor;
  final double iconSpacing;
  final Color background;

  final List<IconData> icons;
  final OnIconButtonPressed onIconButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: background,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          for (int i = 0; i < icons.length; i += 1) ...[
            TriStateIconButton(
              icon: icons[i],
              iconSize: iconSize,
              iconColor: iconColor,
              onPressed: () {
                onIconButtonPressed(i);
              },
            ),
            if (i < icons.length - 1) //
              SizedBox(height: iconSpacing)
          ],
        ],
      ),
    );
  }
}

class TriStateIconButton extends StatefulWidget {
  const TriStateIconButton({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.onPressed,
  });

  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  State<TriStateIconButton> createState() => _TriStateIconButtonState();
}

class _TriStateIconButtonState extends State<TriStateIconButton> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: MouseRegion(
        cursor: WidgetStateMouseCursor.clickable,
        child: _HoverBox(
          baseDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          hoverColor: Colors.white.withOpacity(0.05),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverBox extends StatefulWidget {
  const _HoverBox({
    required this.baseDecoration,
    required this.hoverColor,
    required this.child,
  });

  final BoxDecoration baseDecoration;
  final Color hoverColor;
  final Widget child;

  @override
  State<_HoverBox> createState() => _HoverBoxState();
}

class _HoverBoxState extends State<_HoverBox> {
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

typedef OnIconButtonPressed = void Function(int index);

class VerticalTextButtonToolbar extends StatelessWidget {
  const VerticalTextButtonToolbar({
    super.key,
    this.width = 24,
    this.iconSize = 14,
    required this.textStyle,
    this.background = const Color(0xFF202224),
  });

  final double width;
  final double iconSize;
  final TextStyle textStyle;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
