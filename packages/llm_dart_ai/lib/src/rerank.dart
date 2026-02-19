import 'dart:math' as math;

import 'package:llm_dart_core/llm_dart_core.dart';

import 'cosine_similarity.dart';
import 'embed.dart';
import 'types.dart';

/// Wrap an embedding model as a rerank model (local cosine similarity).
///
/// This is useful when you want a `RerankCapability` instance, but only have
/// embeddings available.
class EmbeddingRerankAdapter implements RerankCapability {
  final EmbeddingCapability embedder;

  const EmbeddingRerankAdapter(this.embedder);

  @override
  Future<RerankResponse> rerank(
    RerankRequest request, {
    CancelToken? cancelToken,
  }) async {
    final result = await rerankByEmbedding(
      model: embedder,
      query: request.query,
      documents: request.documents,
      topK: request.topK,
      cancelToken: cancelToken,
    );
    return result.rawResponse;
  }
}

/// Rerank using a provider-native rerank capability.
Future<RerankResult> rerank({
  required RerankCapability model,
  required String query,
  required List<RerankDocument> documents,
  int? topK,
  String? rerankModel,
  CancelToken? cancelToken,
}) async {
  final response = await model.rerank(
    RerankRequest(
      query: query,
      documents: documents,
      topK: topK,
      model: rerankModel,
    ),
    cancelToken: cancelToken,
  );
  return RerankResult(rawResponse: response);
}

/// Best-effort rerank via embeddings (local cosine similarity).
///
/// This is useful when a provider does not offer a native rerank API.
/// It is NOT a cross-encoder reranker; quality depends on the embedding model.
Future<RerankResult> rerankByEmbedding({
  required EmbeddingCapability model,
  required String query,
  required List<RerankDocument> documents,
  int? topK,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  if (documents.isEmpty) {
    return const RerankResult(
      rawResponse: RerankResponse(results: []),
    );
  }

  final inputs = <String>[query, ...documents.map((d) => d.text)];
  final embedResult = await embedMany(
    model: model,
    values: inputs,
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
  final vectors = embedResult.embeddings;
  if (vectors.length != inputs.length) {
    throw ResponseFormatError(
      'Invalid embedding response: expected query + documents vectors.',
      'expected=${inputs.length} actual=${vectors.length}',
    );
  }

  final queryVec = vectors.first;
  final scored = <RerankResultItem>[];

  for (var i = 0; i < documents.length; i++) {
    final docVec = vectors[i + 1];
    final score = cosineSimilarity(queryVec, docVec);
    scored.add(
      RerankResultItem(
        index: i,
        score: score,
        document: documents[i],
      ),
    );
  }

  scored.sort((a, b) => b.score.compareTo(a.score));

  final k = (topK == null || topK <= 0)
      ? scored.length
      : math.min(topK, scored.length);

  return RerankResult(
    rawResponse:
        RerankResponse(results: scored.take(k).toList(growable: false)),
  );
}
