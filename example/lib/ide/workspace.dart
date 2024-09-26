import 'dart:io';

import 'package:example/lsp_exploration/lsp/lsp_client.dart';

/// A context that applies to a single IDE window.
///
/// A workspace provides access to details that bind the various
/// operations of the IDE. For example, a workspace includes the
/// path of the open directory, the Dart LSP client for the given
/// session, etc.
class Workspace {
  Workspace(this.directory) : lspClient = LspClient();

  final Directory directory;

  final LspClient lspClient;
}
