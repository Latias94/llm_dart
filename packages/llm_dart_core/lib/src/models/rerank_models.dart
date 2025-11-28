/// Models for semantic reranking operations.
///
/// These types provide a provider-agnostic representation of reranking
/// requests and results so that both first-party helpers (like
/// `rerank(...)`) and provider-specific implementations can share a
/// common shape.
library;

/// Input document for reranking.
///
/// A document consists of a stable [id], the raw [text] content used for
/// similarity comparison, and optional [metadata] that can be used by
/// callers to attach application-specific information (such as original
/// object IDs, titles, or scores).
class RerankDocument {
  /// Stable identifier for the document (e.g. database ID or index).
  final String id;

  /// Text content used for semantic similarity with the query.
  final String text;

  /// Optional application-specific metadata.
  final Map<String, dynamic>? metadata;

  const RerankDocument({
    required this.id,
    required this.text,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (metadata != null) 'metadata': metadata,
      };

  factory RerankDocument.fromJson(Map<String, dynamic> json) {
    return RerankDocument(
      id: json['id'] as String,
      text: json['text'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Single ranked entry in a reranking result.
class RerankResultItem {
  /// Document that was reranked.
  final RerankDocument document;

  /// Relevance score for the document (higher is more relevant).
  final double score;

  /// Ranking position after reranking (0-based, 0 = best match).
  final int index;

  /// Original index of the document before reranking.
  final int originalIndex;

  const RerankResultItem({
    required this.document,
    required this.score,
    required this.index,
    required this.originalIndex,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'originalIndex': originalIndex,
        'score': score,
        'document': document.toJson(),
      };

  factory RerankResultItem.fromJson(Map<String, dynamic> json) {
    return RerankResultItem(
      index: json['index'] as int,
      originalIndex: json['originalIndex'] as int,
      score: (json['score'] as num).toDouble(),
      document:
          RerankDocument.fromJson(json['document'] as Map<String, dynamic>),
    );
  }
}

/// Result of a reranking operation.
class RerankResult {
  /// Query text used for reranking.
  final String query;

  /// Ranked list of documents with scores and indices.
  final List<RerankResultItem> ranking;

  const RerankResult({
    required this.query,
    required this.ranking,
  });

  /// Convenience view of the reranked documents in order.
  List<RerankDocument> get rerankedDocuments =>
      ranking.map((item) => item.document).toList();

  Map<String, dynamic> toJson() => {
        'query': query,
        'ranking': ranking.map((item) => item.toJson()).toList(),
      };

  factory RerankResult.fromJson(Map<String, dynamic> json) {
    final items = (json['ranking'] as List)
        .map(
          (item) => RerankResultItem.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    return RerankResult(
      query: json['query'] as String,
      ranking: items,
    );
  }
}

