import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Provides the IDE functionallity, like opening and editing files.
///
/// Holds the list of open editors and the active editor.
class IdeController {
  /// The list of open editors and the active editor index.
  ///
  /// An editor is a view that allows the user to edit a file.
  ///
  /// It's separated from the [openFiles] so we can implement, in the future,
  /// multiple editors for the same file. For example, open two editors side by side.
  ValueListenable<IdeEditors> get editorData => _editorData;
  final ValueNotifier<IdeEditors> _editorData = ValueNotifier(IdeEditors(openEditors: []));

  /// The files that have at least one editor open.
  Set<IdeFile> get openFiles => _openFiles;
  final Set<IdeFile> _openFiles = {};

  /// Maps the file URI to the opened editors for that file.
  final _fileUriToOpenedEditors = <String, List<IdeFileEditor>>{};

  /// Maps the file URI to the opened file.
  final _fileUriToIdeFile = <String, IdeFile>{};

  /// Opens the file with the given URI at the active editor.
  ///
  /// If there is no active editor, opens a new editor.
  ///
  /// If the file is already open in another editor, shows the existing editor.
  Future<void> openFileAtActiveEditor(String fileUri) async {
    if (showExistingEditorForFile(fileUri)) {
      // The file is already open in another editor. Fizzle.
      return;
    }

    await _loadFile(fileUri);

    final activeEditorIndex = _editorData.value.activeEditorIndex;
    if (activeEditorIndex != null) {
      // There is an open editor. Close it.
      closeEditorAtIndex(activeEditorIndex);
    }

    await _openFile(fileUri, activeEditorIndex ?? 0);
  }

  /// Opens the file with the given URI at a new editor.
  ///
  /// If the file is already open in another editor, shows the existing editor.
  Future<void> openFileAtNewTab(String fileUri) async {
    if (showExistingEditorForFile(fileUri)) {
      return;
    }

    await _loadFile(fileUri);

    await _openFile(fileUri, _editorData.value.openEditors.length);
  }

  /// Shows the existing editor for the file with the given URI, if any.
  ///
  /// Returns `true` if there is an existing editor for the file and `false` otherwise.
  bool showExistingEditorForFile(String fileUri) {
    final editorList = _fileUriToOpenedEditors[fileUri];
    if (editorList == null || editorList.isEmpty) {
      return false;
    }

    // Show the existing editor.
    final editor = editorList.first;
    final editorIndex = _editorData.value.openEditors.indexOf(editor);
    _editorData.value = IdeEditors(
      openEditors: _editorData.value.openEditors,
      activeEditorIndex: editorIndex,
    );

    return true;
  }

  /// Closes the editor at the given index.
  ///
  /// If the editor is the active editor, updates the active editor with the following rules:
  ///
  /// - If there are no other open editors, sets the active editor to `null`.
  /// - If there is an editor after the closed editor, makes it the active editor.
  /// - If there is an editor before the closed editor, makes it the active editor.
  void closeEditorAtIndex(int index) {
    final editor = _editorData.value.openEditors[index];
    final fileUri = editor.fileUri;
    final isActiveEditor = _editorData.value.activeEditorIndex == index;

    // Updates the editor list.
    final newList = _editorData.value.openEditors.where((e) => e != editor).toList();
    int? newActiveEditorIndex;
    if (isActiveEditor) {
      // Updates the active editor.
      if (newList.isEmpty) {
        newActiveEditorIndex = null;
      } else if (index < newList.length) {
        newActiveEditorIndex = index;
      } else {
        newActiveEditorIndex = index - 1;
      }
    }

    _editorData.value = IdeEditors(
      openEditors: UnmodifiableListView(newList),
      activeEditorIndex: newActiveEditorIndex,
    );

    // Remove the editor from the list of open editors for the file.
    final openEditorForFile = _fileUriToOpenedEditors[fileUri]!;
    openEditorForFile.remove(editor);

    if (openEditorForFile.isEmpty) {
      // The file is not opened in any editor. Remove it from the list of open files.
      _openFiles.remove(_fileUriToIdeFile[editor.fileUri]);
      _fileUriToIdeFile.remove(editor.fileUri);
    }
  }

  /// Returns the file with the given URI, if it's opened in the IDE.
  IdeFile? getFile(String fileUri) {
    return _fileUriToIdeFile[fileUri];
  }

  /// Opens an editor for the file with the given URI at the given editor index, and
  /// makes it the active editor.
  ///
  /// If the index is greater than the number of open editors, opens a new editor at
  /// the end of the editor list.
  Future<void> _openFile(String fileUri, int editorIndex) async {
    final editor = IdeFileEditor(fileUri: fileUri);

    // Add the editor to the list of open editors for the file.
    if (!_fileUriToOpenedEditors.containsKey(fileUri)) {
      _fileUriToOpenedEditors[fileUri] = [];
    }
    _fileUriToOpenedEditors[fileUri]!.add(editor);

    // Update the editor list.
    final newFileList = [..._editorData.value.openEditors];
    if (editorIndex >= newFileList.length) {
      newFileList.add(editor);
    } else {
      newFileList[editorIndex] = editor;
    }
    _editorData.value = IdeEditors(
      openEditors: UnmodifiableListView(newFileList),
      // Make the new editor the active editor.
      activeEditorIndex: editorIndex,
    );
  }

  /// Loads the file with the given URI into memory.
  ///
  /// If the file is already in memory, does nothing.
  Future<IdeFile> _loadFile(String fileUri) async {
    IdeFile? ideFile = _fileUriToIdeFile[fileUri];
    if (ideFile != null) {
      // The file is already in memory, return the existing file.
      return ideFile;
    }

    // The file isn't opened anywhere.
    final file = File.fromUri(Uri.parse(fileUri));
    final content = await file.readAsString();

    ideFile = IdeFile(fileUri, content);

    _openFiles.add(ideFile);
    _fileUriToIdeFile[fileUri] = ideFile;

    return ideFile;
  }
}

/// The editors opened in the IDE and the active editor index.
class IdeEditors {
  IdeEditors({
    required this.openEditors,
    this.activeEditorIndex,
  });

  final List<IdeFileEditor> openEditors;
  final int? activeEditorIndex;
}

/// A file opened in the IDE.
class IdeFile {
  IdeFile(
    this.uri,
    this.content,
  );

  /// The URI of the file.
  final String uri;

  /// The content of the file.
  final String content;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || //
        other is IdeFile && runtimeType == other.runtimeType && uri == other.uri;
  }

  @override
  int get hashCode => uri.hashCode;
}

/// An editor opened in the IDE.
class IdeFileEditor {
  IdeFileEditor({
    required this.fileUri,
  });

  final String fileUri;
}
