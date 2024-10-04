import 'package:example/ide/workspace.dart';
import 'package:example/lsp_exploration/lsp/lsp_client.dart';
import 'package:example/lsp_exploration/lsp/messages/initialize.dart';
import 'package:flutter/material.dart';

/// A panel that monitors a Dart LSP connection and provides
/// associated controls.
class LspPanel extends StatefulWidget {
  const LspPanel({
    super.key,
    required this.workspace,
  });

  final Workspace workspace;

  @override
  State<LspPanel> createState() => _LspPanelState();
}

class _LspPanelState extends State<LspPanel> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.workspace.lspClient,
      builder: (context, child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "LANGUAGE SERVER PROTOCOL",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _lspClientStatus,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 48),
                _buildControlButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _lspClientStatus {
    switch (widget.workspace.lspClient.status) {
      case LspClientStatus.notRunning:
        return "Not Running";
      case LspClientStatus.starting:
        return "Starting";
      case LspClientStatus.started:
        return "Started";
      case LspClientStatus.initializing:
        return "Initializing";
      case LspClientStatus.initialized:
        return "Initialized";
    }
  }

  Widget _buildControlButton() {
    final lspStatus = widget.workspace.lspClient.status;

    late final String label;
    VoidCallback? onPressed;
    switch (lspStatus) {
      case LspClientStatus.notRunning:
        label = "Start Process";
        onPressed = () {
          widget.workspace.lspClient.start();
        };
      case LspClientStatus.starting:
        label = "Start Process";
      case LspClientStatus.started:
        label = "Initialize";
        onPressed = () async {
          await widget.workspace.lspClient.initialize(
            InitializeParams(
              rootUri: 'file://${widget.workspace.directory.absolute.path}',
              capabilities: LspClientCapabilities(
                  // experimental: {
                  //   'supportsDartTextDocumentContentProvider': true,
                  // },
                  ),
            ),
          );

          await widget.workspace.lspClient.initialized();
        };
      case LspClientStatus.initializing:
        label = "Initialize";
      case LspClientStatus.initialized:
        label = "Stop";
        onPressed = () {
          widget.workspace.lspClient.stop();
        };
    }

    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
