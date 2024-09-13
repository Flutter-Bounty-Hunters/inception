class InitializeParams {
  InitializeParams({
    this.processId,
    this.clientInfo,
    required this.rootUri,
    this.workspaceFolders = const [],
    required this.capabilities,
    this.locale,
  });

  /// The process Id of the parent process that started the server. Is `null` if
  /// the process has not been started by another process. If the parent
  /// process is not alive then the server should exit (see exit notification)
  /// its process.
  final int? processId;

  final ClientInfo? clientInfo;

  /// The locale the client is currently showing the user interface
  /// in. This is not necessarily the locale of the operating
  /// system.
  ///
  /// Uses IETF language tags as the value's syntax
  /// (See [IETF language tag](https://en.wikipedia.org/wiki/IETF_language_tag))
  ///
  /// Since version 3.16.0.
  final String? locale;

  /// The root uri of the workspace. Is `null` if no
  /// folder is open.
  ///
  /// @deprecated in favor of `workspaceFolders`.
  ///
  /// Although this field is deprecated, it is required by the Dart LSP.
  final String rootUri;

  /// The capabilities provided by the client (editor or tool).
  final LspClientCapabilities capabilities;

  /// The workspace folders configured in the client when the server starts.
  ///
  /// This property is only available if the client supports workspace folders.
  /// It can be `null` if the client supports workspace folders but none are
  /// configured.
  ///
  /// Since version 3.6.0.
  final List<WorkspaceFolder> workspaceFolders;

  Map<String, dynamic> toJson() {
    return {
      'processId': processId,
      'clientInfo': clientInfo?.toJson(),
      'rootUri': rootUri,
      'capabilities': capabilities.toJson(),
      'locale': locale,
      'workspaceFolders': workspaceFolders.map((e) => e.toJson()).toList(),
    };
  }
}

class ClientInfo {
  ClientInfo({
    required this.name,
    this.version,
  });

  final String name;
  final String? version;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
    };
  }
}

class WorkspaceFolder {
  WorkspaceFolder({
    required this.name,
    required this.uri,
  });

  /// The name of the workspace folder. Used to refer to this workspace folder
  /// in the user interface.
  final String name;

  /// The associated URI for this workspace folder.
  final String uri;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uri': uri,
    };
  }
}

class LspClientCapabilities {
  Map<String, dynamic> toJson() => {};
}

class InitializeResult {
  InitializeResult({
    required this.capabilities,
    this.serverInfo,
  });

  final Map<String, dynamic> capabilities;
  final LspServerInfo? serverInfo;

  factory InitializeResult.fromJson(Map<String, dynamic> json) {
    return InitializeResult(
      capabilities: json['capabilities'] as Map<String, dynamic>,
      serverInfo: json['serverInfo'] == null
          ? null
          : LspServerInfo(
              name: json['serverInfo']['name'] as String,
              version: json['serverInfo']['version'] as String?,
            ),
    );
  }
}

class LspServerInfo {
  LspServerInfo({
    required this.name,
    this.version,
  });

  final String name;
  final String? version;
}
