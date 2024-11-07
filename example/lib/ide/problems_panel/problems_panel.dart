import 'dart:io';

import 'package:example/ide/problems_panel/diagnostics.dart';
import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:flutter/material.dart';

class ProblemsPanel extends StatefulWidget {
  const ProblemsPanel({
    super.key,
    required this.lspClient,
    this.sourceFile,
  });

  final LspClient lspClient;
  final File? sourceFile;

  @override
  State<ProblemsPanel> createState() => _ProblemsPanelState();
}

class _ProblemsPanelState extends State<ProblemsPanel> {
  List<Diagnostic>? _diagnostics;
  String? _uri;

  @override
  void initState() {
    super.initState();
    widget.lspClient.addNotificationListener(_onLspNotification);
  }

  @override
  void didUpdateWidget(ProblemsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lspClient != oldWidget.lspClient) {
      oldWidget.lspClient.removeNotificationListener(_onLspNotification);
      widget.lspClient.addNotificationListener(_onLspNotification);
    }
  }

  @override
  void dispose() {
    widget.lspClient.removeNotificationListener(_onLspNotification);
    super.dispose();
  }

  void _onLspNotification(LspNotification notification) {
    if (notification.method != 'textDocument/publishDiagnostics') {
      return;
    }
    setState(() {
      _uri = notification.params['uri'] as String?;
      final diagnosticsList = notification.params['diagnostics'] as List;
      _diagnostics = diagnosticsList.map((d) => Diagnostic.fromJson(d)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_diagnostics == null) {
      return const SizedBox();
    }

    // The LspClient will send problem notifications for all types of files.
    // We only want to display them for the currently selected file.
    if (_uri == null || widget.sourceFile == null) {
      return const SizedBox();
    }
    final sameFile = _uri!.endsWith(widget.sourceFile!.path);
    if (!sameFile) {
      return const SizedBox();
    }

    return ListView.builder(
      itemCount: _diagnostics!.length,
      itemBuilder: (context, index) {
        final diagnostic = _diagnostics![index];
        return ListTile(
          title: Text(
            diagnostic.message,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            _subtitle(diagnostic),
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        );
      },
    );
  }

  String _subtitle(Diagnostic diagnostic) {
    return 'Line: ${diagnostic.range.start.line}, Severity: ${diagnostic.severity}';
  }
}
