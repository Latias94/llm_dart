// High-level embedding and reranking helpers that operate on EmbeddingCapability instances.

library;

import 'dart:math' as math;

import 'package:llm_dart_core/llm_dart_core.dart';

/// Generate embeddings using an existing [EmbeddingCapability] instance.
Future<List<List<double>>> embedWithModel(
  EmbeddingCapability model, {
  required List<String> input,
  CancellationToken? cancelToken,
}) {
  return model.embed(input, cancelToken: cancelToken);
}

/// Embedding-based reranking using an existing [EmbeddingCapability] instance.
///
/// This helper computes cosine similarity between the [query] embedding and
/// each document embedding, then returns a [RerankResult] with ranked items.
///
/// It is provider-agnostic and works with any embedding model.
Future<RerankResult> rerankWithModel({
  required EmbeddingCapability model,
  required String query,
  required List<String> documents,
  int? topN,
  CancellationToken? cancelToken,
}) async {
  if (documents.isEmpty) {
    return RerankResult(query: query, ranking: const []);
  }

  final texts = <String>[query, ...documents];
  final vectors = await model.embed(texts, cancelToken: cancelToken);

  if (vectors.length != texts.length) {
    throw const ResponseFormatError(
      'Embedding provider returned an unexpected number of vectors for rerankWithModel()',
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
        document: RerankDocument(id: i.toString(), text: documents[i]),
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

  return RerankResult(query: query, ranking: ranked);
}
