part of 'llm_builder.dart';

/// Embedding-based implementation of [RerankingCapability].
///
/// This adapter wraps an [EmbeddingCapability] and computes cosine
/// similarity between query and document embeddings to produce a
/// [RerankResult]. This is used by [LLMBuilder.buildReranker] as a
/// provider-agnostic fallback when no dedicated reranking API is
/// available.
class _EmbeddingRerankingCapability implements RerankingCapability {
  final EmbeddingCapability _embedding;

  _EmbeddingRerankingCapability(this._embedding);

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
    final vectors = await _embedding.embed(
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
