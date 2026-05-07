part of 'provider_compat.dart';

mixin OpenAIProviderFilesMixin implements FileManagementCapability {
  OpenAIFiles get _files;

  @override
  Future<FileObject> uploadFile(FileUploadRequest request) async {
    return _files.uploadFile(request);
  }

  @override
  Future<FileListResponse> listFiles([FileListQuery? query]) async {
    return _files.listFiles(query);
  }

  @override
  Future<FileObject> retrieveFile(String fileId) async {
    return _files.retrieveFile(fileId);
  }

  @override
  Future<FileDeleteResponse> deleteFile(String fileId) async {
    return _files.deleteFile(fileId);
  }

  @override
  Future<List<int>> getFileContent(String fileId) async {
    return _files.getFileContent(fileId);
  }
}
