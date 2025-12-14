import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/anthropic_client.dart';
import '../config/anthropic_config.dart';

class AnthropicFiles implements FileManagementCapability {
  final AnthropicClient client;
  final AnthropicConfig config;

  AnthropicFiles(this.client, this.config);

  String get filesEndpoint => 'files';

  @override
  Future<FileObject> uploadFile(FileUploadRequest request) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        request.file,
        filename: request.filename,
      ),
    });

    final response = await client.postForm(filesEndpoint, formData);
    return FileObject.fromAnthropic(response);
  }

  @override
  Future<FileListResponse> listFiles([FileListQuery? query]) async {
    final response = await client.getJson(filesEndpoint);
    return FileListResponse.fromAnthropic(response);
  }

  @override
  Future<FileObject> retrieveFile(String fileId) async {
    final response = await client.getJson('$filesEndpoint/$fileId');
    return FileObject.fromAnthropic(response);
  }

  @override
  Future<FileDeleteResponse> deleteFile(String fileId) async {
    await client.delete('$filesEndpoint/$fileId');
    return FileDeleteResponse(id: fileId, deleted: true);
  }

  @override
  Future<List<int>> getFileContent(String fileId) async {
    return client.getRaw('$filesEndpoint/$fileId/content');
  }

  Future<FileObject> uploadFileFromBytes(
    List<int> bytes, {
    String? filename,
  }) async {
    final request = FileUploadRequest(
      file: Uint8List.fromList(bytes),
      filename: filename ?? 'upload',
    );
    return uploadFile(request);
  }

  Future<bool> fileExists(String fileId) async {
    try {
      await retrieveFile(fileId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> getFileContentAsString(String fileId) async {
    final bytes = await getFileContent(fileId);
    return String.fromCharCodes(bytes);
  }

  Future<int> getTotalStorageUsed() async {
    final files = await listFiles();
    return files.data.fold<int>(
      0,
      (sum, file) => sum + file.sizeBytes,
    );
  }

  Future<Map<String, bool>> deleteFiles(List<String> fileIds) async {
    final result = <String, bool>{};
    for (final id in fileIds) {
      try {
        await deleteFile(id);
        result[id] = true;
      } catch (_) {
        result[id] = false;
      }
    }
    return result;
  }
}
