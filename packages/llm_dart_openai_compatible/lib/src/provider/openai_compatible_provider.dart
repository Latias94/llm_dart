import 'dart:math' as math;

import 'package:llm_dart_core/llm_dart_core.dart';

import '../embeddings/openai_compatible_embeddings.dart';
import '../chat/openai_compatible_chat.dart';
import '../client/openai_compatible_client.dart';
import '../config/openai_compatible_config.dart';
import '../provider_profiles/openai_compatible_provider_profiles.dart';

/// Generic provider implementation for OpenAI-compatible vendors.
///
/// This wraps [OpenAICompatibleChat] and optional embedding/reranking
/// capabilities, exposing them through the core capability interfaces.
class OpenAICompatibleProvider
    implements
        ChatCapability,
        EmbeddingCapability,
        RerankingCapability,
        ProviderCapabilities {
  final OpenAICompatibleClient _client;
  final OpenAICompatibleChat _chat;
  late final OpenAICompatibleEmbeddings _embeddings;
  final OpenAICompatibleConfig config;

  OpenAICompatibleProvider(this.config)
      : _client = OpenAICompatibleClient(config),
        _chat = OpenAICompatibleChat(OpenAICompatibleClient(config), config) {
    _embeddings = OpenAICompatibleEmbeddings(_client, config);
  }

  String get providerName => config.providerId;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chat(
      messages,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chatWithTools(
      messages,
      tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
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
  Future<List<ChatMessage>?> memoryContents() => _chat.memoryContents();

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) =>
      _chat.summarizeHistory(messages);

  @override
  Set<LLMCapability> get supportedCapabilities {
    final capabilities = <LLMCapability>{
      LLMCapability.chat,
      LLMCapability.streaming,
    };

    if (config.tools != null && config.tools!.isNotEmpty) {
      capabilities.add(LLMCapability.toolCalling);
    }

    if (config.reasoningEffort != null) {
      capabilities.add(LLMCapability.reasoning);
    }

    final profile =
        OpenAICompatibleProviderProfiles.getConfig(config.providerId);
    if (profile != null &&
        profile.supportedCapabilities.contains(LLMCapability.embedding)) {
      capabilities.add(LLMCapability.embedding);
      capabilities.add(LLMCapability.reranking);
    }

    return capabilities;
  }

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);

  // ===== EmbeddingCapability =====

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  // ===== RerankingCapability =====

  @override
  Future<RerankResult> rerank({
    required String query,
    required List<RerankDocument> documents,
    int? topN,
    CancellationToken? cancelToken,
  }) async {
    if (documents.isEmpty) {
      return RerankResult(query: query, ranking: const []);
    }

    final texts = <String>[query, ...documents.map((d) => d.text)];
    final vectors = await _embeddings.embed(
      texts,
      cancelToken: cancelToken,
    );

    if (vectors.length != texts.length) {
      throw const ResponseFormatError(
        'Embedding provider returned an unexpected number of vectors for rerank()',
        '',
      );
    }

    final queryVector = vectors.first;
    final documentVectors = vectors.sublist(1);

    double dot(List<double> a, List<double> b) {
      final len = math.min(a.length, b.length);
      var sum = 0.0;
      for (var i = 0; i < len; i++) {
        sum += a[i] * b[i];
      }
      return sum;
    }

    double norm(List<double> v) {
      var sum = 0.0;
      for (final x in v) {
        sum += x * x;
      }
      return math.sqrt(sum);
    }

    double cosine(List<double> a, List<double> b) {
      final denom = norm(a) * norm(b);
      if (denom == 0) return 0.0;
      return dot(a, b) / denom;
    }

    final tempItems = <RerankResultItem>[];
    for (var i = 0; i < documents.length; i++) {
      final score = cosine(queryVector, documentVectors[i]);
      tempItems.add(
        RerankResultItem(
          document: documents[i],
          score: score,
          index: 0,
          originalIndex: i,
        ),
      );
    }

    tempItems.sort((a, b) => b.score.compareTo(a.score));

    final limited = (topN != null && topN > 0 && topN < tempItems.length)
        ? tempItems.sublist(0, topN)
        : tempItems;

    final ranked = <RerankResultItem>[];
    for (var rank = 0; rank < limited.length; rank++) {
      final item = limited[rank];
      ranked.add(
        RerankResultItem(
          document: item.document,
          score: item.score,
          index: rank,
          originalIndex: item.originalIndex,
        ),
      );
    }

    return RerankResult(
      query: query,
      ranking: ranked,
    );
  }
}
