import 'package:llm_dart_anthropic_compatible/chat.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_anthropic_compatible/config.dart';
import 'package:llm_dart_anthropic_compatible/dio_strategy.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import 'files.dart';
import 'models.dart';

/// Anthropic provider implementation
///
/// This provider implements multiple capability interfaces following the
/// modular architecture pattern. It supports:
/// - ChatCapability: Core chat functionality
///
/// **API Documentation:**
/// - Messages API: https://platform.claude.com/docs/en/api/messages
/// - Models API: https://platform.claude.com/docs/en/api/models/list
/// - Token Counting: https://platform.claude.com/docs/en/api/messages/count-tokens
/// - Extended Thinking: https://platform.claude.com/docs/en/build-with-claude/extended-thinking
///
/// This provider delegates to specialized capability modules for different
/// functionalities, maintaining clean separation of concerns.
class AnthropicProvider
    implements
        ChatCapability,
        PromptChatCapability,
        ChatStreamPartsCapability,
        PromptChatStreamPartsCapability,
        ProviderCapabilities {
  final AnthropicClient _client;
  final AnthropicConfig config;

  // Capability modules
  late final AnthropicChat _chat;
  late final AnthropicFiles _files;
  late final AnthropicModels _models;

  AnthropicProvider(this.config)
      : _client = AnthropicClient(config, strategy: AnthropicDioStrategy()) {
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

  /// Provider-specific APIs (not part of the standard surface).
  AnthropicFiles get filesApi => _files;
  AnthropicModels get modelsApi => _models;

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
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatStreamParts(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPrompt(prompt, tools: tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatPromptStream(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPromptStream(prompt,
        tools: tools, cancelToken: cancelToken);
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPromptStreamParts(
      prompt,
      tools: tools,
      cancelToken: cancelToken,
    );
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

  Future<List<AIModel>> models({CancelToken? cancelToken}) async {
    return _models.models(cancelToken: cancelToken);
  }

  /// List available models from Anthropic API
  ///
  /// **API Reference:** https://platform.claude.com/docs/en/api/models/list
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
  /// **API Reference:** https://platform.claude.com/docs/en/api/models
  ///
  /// Returns detailed information about a specific model including its
  /// capabilities, creation date, and display name.
  Future<AIModel?> getModel(String modelId) async {
    return _models.getModel(modelId);
  }

  /// Count tokens for messages using Anthropic's API
  ///
  /// **API Reference:** https://platform.claude.com/docs/en/api/messages/count-tokens
  ///
  /// This uses Anthropic's dedicated token counting endpoint to provide
  /// accurate token counts for messages, system prompts, tools, and thinking
  /// configurations without actually sending a chat request.
  Future<int> countTokens(List<ChatMessage> messages,
      {List<Tool>? tools}) async {
    return _chat.countTokens(messages, tools: tools);
  }

  // ========== Provider-specific: Files ==========
  Future<FileObject> uploadFile(FileUploadRequest request) async {
    return _files.uploadFile(request);
  }

  Future<FileListResponse> listFiles([FileListQuery? query]) async {
    return _files.listFiles(query);
  }

  Future<FileObject> retrieveFile(String fileId) async {
    return _files.retrieveFile(fileId);
  }

  Future<FileDeleteResponse> deleteFile(String fileId) async {
    return _files.deleteFile(fileId);
  }

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
