import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: _Screen(),
    ),
  );
}

class _Screen extends StatefulWidget {
  const _Screen({super.key});

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
