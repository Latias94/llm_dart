import 'package:dio/dio.dart';

import '../../core/capability.dart';
import '../../models/chat_models.dart';
import '../../models/file_models.dart';
import '../../models/tool_models.dart';
import 'client.dart';
import 'config.dart';
import 'chat.dart';
import 'files.dart';
import 'models.dart';

/// Anthropic provider implementation
///
/// This provider implements multiple capability interfaces following the
/// modular architecture pattern. It supports:
/// - ChatCapability: Core chat functionality
/// - ModelListingCapability: Model discovery and information
///
/// **API Documentation:**
/// - Messages API: https://docs.anthropic.com/en/api/messages
/// - Models API: https://docs.anthropic.com/en/api/models-list
/// - Token Counting: https://docs.anthropic.com/en/api/messages-count-tokens
/// - Extended Thinking: https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
///
/// This provider delegates to specialized capability modules for different
/// functionalities, maintaining clean separation of concerns.
class AnthropicProvider
    implements
        ChatCapability,
        ModelListingCapability,
        FileManagementCapability,
        ProviderCapabilities {
  final AnthropicClient _client;
  final AnthropicConfig config;

  // Capability modules
  late final AnthropicChat _chat;
  late final AnthropicFiles _files;
  late final AnthropicModels _models;

  AnthropicProvider(this.config) : _client = AnthropicClient(config) {
    // Validate configuration on initialization
    final validationError = config.validateThinkingConfig();
    if (validationError != null) {
      _client.logger
          .warning('Anthropic configuration warning: $validationError');
    }

    // Initialize capability modules
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

  /// Get provider name
  String get providerName => 'Anthropic';

  // ========== ProviderCapabilities ==========

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

  /// List available models from Anthropic API
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/models-list
  ///
  /// Supports pagination with [beforeId], [afterId], and [limit] parameters.
  /// Returns a list of available models with their metadata.
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

  /// Get information about a specific model
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/models
  ///
  /// Returns detailed information about a specific model including its
  /// capabilities, creation date, and display name.
  Future<AIModel?> getModel(String modelId) async {
    return _models.getModel(modelId);
  }

  /// Count tokens for messages using Anthropic's API
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/messages-count-tokens
  ///
  /// This uses Anthropic's dedicated token counting endpoint to provide
  /// accurate token counts for messages, system prompts, tools, and thinking
  /// configurations without actually sending a chat request.
  Future<int> countTokens(List<ChatMessage> messages,
      {List<Tool>? tools}) async {
    return _chat.countTokens(messages, tools: tools);
  }

  // ========== FileManagementCapability Implementation ==========

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

  /// Upload file from bytes with automatic filename
  Future<FileObject> uploadFileFromBytes(
    List<int> bytes, {
    String? filename,
  }) async {
    return _files.uploadFileFromBytes(bytes, filename: filename);
  }

  /// Check if a file exists
  Future<bool> fileExists(String fileId) async {
    return _files.fileExists(fileId);
  }

  /// Get file content as string (for text files)
  Future<String> getFileContentAsString(String fileId) async {
    return _files.getFileContentAsString(fileId);
  }

  /// Get total storage used by all files
  Future<int> getTotalStorageUsed() async {
    return _files.getTotalStorageUsed();
  }

  /// Batch delete multiple files
  Future<Map<String, bool>> deleteFiles(List<String> fileIds) async {
    return _files.deleteFiles(fileIds);
  }
}
