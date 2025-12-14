// DeepSeek provider implementation (prompt-first).

import 'package:llm_dart_core/llm_dart_core.dart';

import '../chat/deepseek_chat.dart';
import '../client/deepseek_client.dart';
import '../config/deepseek_config.dart';
import '../models/deepseek_models.dart';
import '../completion/deepseek_completion.dart';

/// DeepSeek provider implementation.
///
/// This provider implements multiple capability interfaces and delegates
/// to specialized capability modules for different functionalities.
class DeepSeekProvider
    implements
        ChatCapability,
        CompletionCapability,
        ModelListingCapability,
        ProviderCapabilities {
  final DeepSeekClient _client;
  final DeepSeekConfig config;

  late final DeepSeekChat _chat;
  late final DeepSeekModels _models;
  late final DeepSeekCompletion _completion;

  DeepSeekProvider(this.config) : _client = DeepSeekClient(config) {
    _chat = DeepSeekChat(_client, config);
    _models = DeepSeekModels(_client, config);
    _completion = DeepSeekCompletion(_client, config);
  }

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return _chat.chat(
      messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chatStream(
      messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<AIModel>> models({CancellationToken? cancelToken}) async {
    return _models.models(cancelToken: cancelToken);
  }

  @override
  Future<CompletionResponse> complete(CompletionRequest request) {
    return _completion.complete(request);
  }

  /// FIM-style completion helper (prefix + suffix).
  Future<CompletionResponse> completeFim({
    required String prefix,
    required String suffix,
    int? maxTokens,
    double? temperature,
    double? topP,
    double? topK,
    List<String>? stop,
  }) {
    return _completion.completeFim(
      prefix: prefix,
      suffix: suffix,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      topK: topK,
      stop: stop,
    );
  }

  String get providerName => 'DeepSeek';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.completion,
        LLMCapability.modelListing,
        if (config.supportsVision) LLMCapability.vision,
        if (config.supportsReasoning) LLMCapability.reasoning,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }
}
