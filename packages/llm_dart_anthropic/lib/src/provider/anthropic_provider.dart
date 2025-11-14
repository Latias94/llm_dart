import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import '../chat/anthropic_chat.dart';
import '../client/anthropic_client.dart';
import '../config/anthropic_config.dart';
import '../files/anthropic_files.dart';
import '../models/anthropic_models.dart';

class AnthropicProvider
    implements
        ChatCapability,
        ModelListingCapability,
        FileManagementCapability,
        ProviderCapabilities {
  final AnthropicClient _client;
  final AnthropicConfig config;

  late final AnthropicChat _chat;
  late final AnthropicFiles _files;
  late final AnthropicModels _models;

  AnthropicProvider(this.config) : _client = AnthropicClient(config) {
    final validationError = config.validateThinkingConfig();
    if (validationError != null) {
      _client.logger
          .warning('Anthropic configuration warning: $validationError');
    }

    _chat = AnthropicChat(_client, config);
    _files = AnthropicFiles(_client, config);
    _models = AnthropicModels(_client, config);
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return _chat.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return _chat.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chat.summarizeHistory(messages);
  }

  String get providerName => 'Anthropic';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.modelListing,
        LLMCapability.fileManagement,
        if (config.supportsVision) LLMCapability.vision,
        if (config.supportsReasoning) LLMCapability.reasoning,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  @override
  Future<List<AIModel>> models({CancelToken? cancelToken}) async {
    return _models.models(cancelToken: cancelToken);
  }

  Future<List<AIModel>> listModels({
    String? beforeId,
    String? afterId,
    int limit = 20,
  }) async {
    return _models.listModels(
      beforeId: beforeId,
      afterId: afterId,
      limit: limit,
    );
  }

  Future<AIModel?> getModel(String modelId) async {
    return _models.getModel(modelId);
  }

  Future<int> countTokens(List<ChatMessage> messages,
      {List<Tool>? tools}) async {
    return _chat.countTokens(messages, tools: tools);
  }

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

  Future<FileObject> uploadFileFromBytes(
    List<int> bytes, {
    String? filename,
  }) async {
    return _files.uploadFileFromBytes(bytes, filename: filename);
  }

  Future<bool> fileExists(String fileId) async {
    return _files.fileExists(fileId);
  }

  Future<String> getFileContentAsString(String fileId) async {
    return _files.getFileContentAsString(fileId);
  }

  Future<int> getTotalStorageUsed() async {
    return _files.getTotalStorageUsed();
  }

  Future<Map<String, bool>> deleteFiles(List<String> fileIds) async {
    return _files.deleteFiles(fileIds);
  }
}
