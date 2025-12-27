/// Rerank models (cross-provider, task-level).
library;

import '../core/capability.dart' show UsageInfo;

/// A document to be reranked.
///
/// This intentionally keeps the "standard surface" minimal:
/// - `text` is the content used for reranking.
/// - `id` and `metadata` are optional and provider-specific (escape hatches).
class RerankDocument {
  final String text;
  final String? id;
  final Map<String, dynamic>? metadata;

  const RerankDocument({
    required this.text,
    this.id,
    this.metadata,
  });

  factory RerankDocument.fromText(String text) => RerankDocument(text: text);

  Map<String, dynamic> toJson() => {
        'text': text,
        if (id != null) 'id': id,
        if (metadata != null) 'metadata': metadata,
      };
}

/// A provider-agnostic rerank request.
class RerankRequest {
  final String query;
  final List<RerankDocument> documents;

  /// The maximum number of results to return.
  ///
  /// If null, providers may return all results.
  final int? topK;

  /// Optional provider/model id (provider-specific).
  final String? model;

  const RerankRequest({
    required this.query,
    required this.documents,
    this.topK,
    this.model,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'documents': documents.map((d) => d.toJson()).toList(growable: false),
        if (topK != null) 'topK': topK,
        if (model != null) 'model': model,
      };
}

/// A single rerank result.
class RerankResultItem {
  /// Index into the original input documents list.
  final int index;

  /// A higher score means "more relevant".
  final double score;

  final RerankDocument document;

  const RerankResultItem({
    required this.index,
    required this.score,
    required this.document,
  });
}

/// Provider-agnostic rerank response.
class RerankResponse {
  final List<RerankResultItem> results;

  /// Provider/model id, when available.
  final String? model;

  /// Optional usage information, when providers surface it.
  final UsageInfo? usage;

  const RerankResponse({
    required this.results,
    this.model,
    this.usage,
  });
}

