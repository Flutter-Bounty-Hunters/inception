class RenameFilesParams {
  RenameFilesParams({
    required this.files,
  });
  final List<FileRename> files;

  Map<String, dynamic> toJson() => {
        'files': files
            .map((e) => {
                  'oldUri': e.oldUri,
                  'newUri': e.newUri,
                })
            .toList(),
      };
}

class FileRename {
  FileRename({required this.oldUri, required this.newUri});

  final String oldUri;
  final String newUri;
}
