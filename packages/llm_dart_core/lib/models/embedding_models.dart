import '../core/stream_parts.dart';

/// Token usage information for embedding calls (AI SDK-style).
class EmbeddingUsage {
  /// Total input tokens used to compute the embeddings.
  final int tokens;

  const EmbeddingUsage({required this.tokens}) : assert(tokens >= 0);

  Map<String, dynamic> toJson() => {'tokens': tokens};

  factory EmbeddingUsage.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'];
    if (tokens is int && tokens >= 0) {
      return EmbeddingUsage(tokens: tokens);
    }
    if (tokens is num && tokens.toInt() >= 0) {
      return EmbeddingUsage(tokens: tokens.toInt());
    }
    return const EmbeddingUsage(tokens: 0);
  }
}

/// Optional HTTP response information for debugging purposes (AI SDK-style).
class EmbeddingCallResponse {
  /// Sanitized response headers (best-effort; HTTP providers only).
  final Map<String, String>? headers;

  /// Response body (best-effort; HTTP providers only).
  final Object? body;

  const EmbeddingCallResponse({this.headers, this.body});

  Map<String, dynamic> toJson() => {
        if (headers != null) 'headers': headers,
        if (body != null) 'body': body,
      };

  factory EmbeddingCallResponse.fromJson(Map<String, dynamic> json) =>
      EmbeddingCallResponse(
        headers: (json['headers'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
        body: json['body'],
      );
}

/// Provider-agnostic embedding response (AI SDK v3-style).
class EmbeddingResponse {
  /// Generated embeddings in the same order as the input values.
  final List<List<double>> embeddings;

  /// Token usage (optional; providers may not report it).
  final EmbeddingUsage? usage;

  /// Warnings for the call, e.g. unsupported settings.
  final List<LLMWarning> warnings;

  /// Provider-specific metadata (namespaced) associated with this response.
  final Map<String, dynamic>? providerMetadata;

  /// Optional response information for debugging purposes.
  final EmbeddingCallResponse? response;

  const EmbeddingResponse({
    required this.embeddings,
    this.usage,
    this.warnings = const <LLMWarning>[],
    this.providerMetadata,
    this.response,
  });

  Map<String, dynamic> toJson() => {
        'embeddings': embeddings,
        if (usage != null) 'usage': usage!.toJson(),
        if (warnings.isNotEmpty)
          'warnings': warnings.map((w) => w.toJson()).toList(growable: false),
        if (providerMetadata != null && providerMetadata!.isNotEmpty)
          'providerMetadata': providerMetadata,
        if (response != null) 'response': response!.toJson(),
      };

  factory EmbeddingResponse.fromJson(Map<String, dynamic> json) {
    final embeddings = (json['embeddings'] as List?)
            ?.map((e) => (e as List)
                .cast<num>()
                .map((n) => n.toDouble())
                .toList(growable: false))
            .toList(growable: false) ??
        const <List<double>>[];

    final warningsJson = json['warnings'];
    final warnings = warningsJson is List
        ? warningsJson
            .whereType<Map>()
            .map((m) => LLMWarning.fromJson(m.cast<String, dynamic>()))
            .toList(growable: false)
        : const <LLMWarning>[];

    return EmbeddingResponse(
      embeddings: embeddings,
      usage: json['usage'] is Map
          ? EmbeddingUsage.fromJson(
              (json['usage'] as Map).cast<String, dynamic>(),
            )
          : null,
      warnings: warnings,
      providerMetadata: json['providerMetadata'] is Map
          ? Map<String, dynamic>.from(json['providerMetadata'] as Map)
          : null,
      response: json['response'] is Map
          ? EmbeddingCallResponse.fromJson(
              (json['response'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}
