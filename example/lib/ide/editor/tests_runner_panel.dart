import 'package:flutter/material.dart';

class TestsRunnerPanel extends StatelessWidget {
  const TestsRunnerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests Runner Panel'),
      ),
      body: const Center(
        child: Text('Tests Runner Panel'),
      ),
    );
  }
}
