import 'dart:io';

import 'package:inception/inception.dart';

/// A context that applies to a single IDE window.
///
/// A workspace provides access to details that bind the various
/// operations of the IDE. For example, a workspace includes the
/// path of the open directory, the Dart LSP client for the given
/// session, etc.
class Workspace {
  Workspace(this.directory)
      : lspClient = LspClient(
          executable: 'ls',
          // params: [
          //   'language-server', //
          //   '--client-id', 'inception.plugin', //
          //   '--client-version', '0.1'
          // ],
        );

  final Directory directory;

  final LspClient lspClient;
}
