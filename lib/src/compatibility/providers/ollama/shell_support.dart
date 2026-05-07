import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart_provider/llm_dart_provider.dart' as core;
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioTransportClient;

import '../../../../core/capability.dart';
import '../../../../core/config.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/ollama/client.dart';
import '../../../../providers/ollama/config.dart';
import '../../config/legacy_config_keys.dart';
import '../compat_provider_support.dart';
import '../../legacy_chat_adapter.dart';
import 'ollama_chat_compat.dart';
import 'ollama_completion_compat.dart';
import 'ollama_models_compat.dart';

part 'shell_chat_router.dart';
part 'shell_config_support.dart';
part 'shell_embedding_support.dart';

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
  late final _OllamaCompatChatRouter _chatRouter = _OllamaCompatChatRouter(
    compatConfig: compatConfig,
    compatChat: compatChat,
    chatFallback: chatFallback,
  );
  late final _OllamaCompatEmbeddingSupport _embeddingSupport =
      _OllamaCompatEmbeddingSupport(
    config: config,
    embeddingModel: embeddingModel,
  );

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
    return _chatRouter.canUseChatBridge(messages);
  }

  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    return _chatRouter.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
  }

  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return _chatRouter.chatStream(
      messages,
      tools: tools,
      cancelToken: cancelToken,
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
    return _embeddingSupport.embed(input, cancelToken: cancelToken);
  }

  Future<List<AIModel>> models({
    TransportCancellation? cancelToken,
  }) {
    return modelListing.models(cancelToken: cancelToken);
  }
}
