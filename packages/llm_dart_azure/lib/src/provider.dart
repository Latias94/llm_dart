import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/chat.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/embeddings.dart';
import 'package:llm_dart_openai_compatible/responses.dart';

import 'config.dart';

/// Azure OpenAI provider implementation.
class AzureOpenAIProvider
    implements ChatCapability, EmbeddingCapability, ProviderCapabilities {
  final OpenAIClient _client;
  final AzureOpenAIConfig config;

  late final OpenAIChat _chat;
  late final OpenAIEmbeddings _embeddings;
  late final OpenAIResponses _responses;

  AzureOpenAIProvider(this.config) : _client = OpenAIClient(config) {
    _chat = OpenAIChat(_client, config);
    _embeddings = OpenAIEmbeddings(_client, config);
    _responses = OpenAIResponses(_client, config);
  }

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.embedding,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.vision,
        LLMCapability.openaiResponses,
      };

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI) {
      return _responses.chat(messages, cancelToken: cancelToken);
    }
    return _chat.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI) {
      return _responses.chatWithTools(messages, tools,
          cancelToken: cancelToken);
    }
    return _chat.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI) {
      return _responses.chatStream(messages,
          tools: tools, cancelToken: cancelToken);
    }
    return _chat.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI) {
      return _responses.chatStreamParts(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      );
    }
    return _chat.chatStreamParts(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() {
    if (config.useResponsesAPI) return _responses.memoryContents();
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) {
    if (config.useResponsesAPI) return _responses.summarizeHistory(messages);
    return _chat.summarizeHistory(messages);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }
}
