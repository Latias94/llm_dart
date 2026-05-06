import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart_core/model.dart' as core;
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioTransportClient;

import '../../../../core/capability.dart';
import '../../../../core/config.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/ollama/client.dart';
import '../../../../providers/ollama/config.dart';
import '../../../config/legacy_config_keys.dart';
import '../compat_provider_support.dart';
import '../../legacy_chat_adapter.dart';
import 'ollama_chat_compat.dart';
import 'ollama_completion_compat.dart';
import 'ollama_models_compat.dart';

/// Root-compatibility glue for the Ollama provider shell.
///
/// This keeps compatibility-specific config shaping, bridge gating, and the
/// legacy chat adapter out of the provider implementation file so the root
/// provider can act more clearly as a shell above package-owned modern models.
final class OllamaCompatShellSupport {
  final OllamaConfig config;
  final OllamaClient client;
  final LLMConfig compatConfig;
  final LegacyChatCapabilityAdapter compatChat;
  final core.EmbeddingModel embeddingModel;
  final OllamaChat chatFallback;
  final OllamaCompletion completion;
  final OllamaModels modelListing;

  OllamaCompatShellSupport._({
    required this.config,
    required this.client,
    required this.compatConfig,
    required this.compatChat,
    required this.embeddingModel,
    required this.chatFallback,
    required this.completion,
    required this.modelListing,
  });

  factory OllamaCompatShellSupport({
    required OllamaConfig config,
  }) {
    final client = OllamaClient(config);
    final modernProvider = modern_community.Ollama(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      transport: DioTransportClient(dio: client.dio),
    );
    final compatConfig = _toCompatConfig(config);

    return OllamaCompatShellSupport._(
      config: config,
      client: client,
      compatConfig: compatConfig,
      compatChat: LegacyChatCapabilityAdapter(
        model: modernProvider.chatModel(config.model),
        config: compatConfig,
        providerOptions: _buildCompatProviderOptions(config),
      ),
      embeddingModel: modernProvider.embeddingModel(config.model),
      chatFallback: OllamaChat(client, config),
      completion: OllamaCompletion(client, config),
      modelListing: OllamaModels(client, config),
    );
  }

  bool canUseChatBridge(List<ChatMessage> messages) {
    if (messages.any((message) => message.name != null)) {
      return false;
    }

    final hasConfigSystemPrompt =
        compatConfig.systemPrompt != null && compatConfig.systemPrompt!.isNotEmpty;
    if (hasConfigSystemPrompt &&
        messages.any((message) => message.role == ChatRole.system)) {
      return false;
    }

    return true;
  }

  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    return executeCompatChat(
      originalConfig: compatConfig,
      messages: messages,
      tools: tools,
      canUseBridge: (config, messages, tools) => canUseChatBridge(messages),
      bridge: () =>
          compatChat.chatWithTools(messages, tools, cancelToken: cancelToken),
      fallback: () => chatFallback.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChatStream(
      originalConfig: compatConfig,
      messages: messages,
      tools: tools,
      canUseBridge: (config, messages, tools) => canUseChatBridge(messages),
      bridge: () =>
          compatChat.chatStream(messages, tools: tools, cancelToken: cancelToken),
      fallback: () => chatFallback.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<List<ChatMessage>?> memoryContents() {
    return chatFallback.memoryContents();
  }

  Future<String> summarizeHistory(List<ChatMessage> messages) {
    return chatFallback.summarizeHistory(messages);
  }

  Future<CompletionResponse> complete(CompletionRequest request) {
    return completion.complete(request);
  }

  Future<List<List<double>>> embed(
    List<String> input, {
    TransportCancellation? cancelToken,
  }) async {
    final result = await embeddingModel.embed(
      core.EmbedRequest(
        values: input,
        callOptions: core.CallOptions(
          timeout: config.timeout,
          cancellation: cancelToken,
        ),
      ),
    );

    return result.embeddings;
  }

  Future<List<AIModel>> models({
    TransportCancellation? cancelToken,
  }) {
    return modelListing.models(cancelToken: cancelToken);
  }
}

LLMConfig _toCompatConfig(OllamaConfig config) {
  return LLMConfig(
    apiKey: config.apiKey,
    baseUrl: config.baseUrl,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    extensions: {
      if (config.jsonSchema != null)
        LegacyExtensionKeys.jsonSchema: config.jsonSchema!,
      if (config.numCtx != null) LegacyExtensionKeys.numCtx: config.numCtx!,
      if (config.numGpu != null) LegacyExtensionKeys.numGpu: config.numGpu!,
      if (config.numThread != null)
        LegacyExtensionKeys.numThread: config.numThread!,
      if (config.numa != null) LegacyExtensionKeys.numa: config.numa!,
      if (config.numBatch != null)
        LegacyExtensionKeys.numBatch: config.numBatch!,
      if (config.keepAlive != null)
        LegacyExtensionKeys.keepAlive: config.keepAlive!,
      if (config.raw != null) LegacyExtensionKeys.raw: config.raw!,
      if (config.reasoning != null)
        LegacyExtensionKeys.reasoning: config.reasoning!,
    },
  );
}

modern_community.OllamaGenerateTextOptions _buildCompatProviderOptions(
  OllamaConfig config,
) {
  return modern_community.OllamaGenerateTextOptions(
    numCtx: config.numCtx,
    numGpu: config.numGpu,
    numThread: config.numThread,
    numBatch: config.numBatch,
    numa: config.numa,
    keepAlive: config.keepAlive ?? '5m',
    raw: config.raw == true ? true : null,
    reasoning: config.reasoning,
  );
}
