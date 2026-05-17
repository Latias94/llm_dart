import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_api.dart';

EmbedResult decodeOllamaEmbeddingResponse({
  required Object? body,
  required String modelId,
  required Map<String, String> headers,
}) {
  final json = decodeOllamaJsonObject(
    body,
    responseName: 'embedding response',
  );

  return EmbedResult(
    embeddings: decodeOllamaEmbeddings(json),
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
    providerMetadata: decodeOllamaEmbeddingProviderMetadata(json),
  );
}

List<List<double>> decodeOllamaEmbeddings(Map<String, Object?> json) {
  final embeddings = json['embeddings'];
  if (embeddings is! List) {
    throw StateError(
      'Expected Ollama embedding response to contain an embeddings list.',
    );
  }

  return embeddings.asMap().entries.map((entry) {
    final value = entry.value;
    if (value is! List) {
      throw StateError(
        'Expected Ollama embedding item ${entry.key} to be a numeric list.',
      );
    }

    return decodeOllamaEmbeddingValues(value, index: entry.key);
  }).toList();
}

List<double> decodeOllamaEmbeddingValues(
  List<Object?> values, {
  required int index,
}) {
  return List<double>.unmodifiable(
    values.map((item) {
      if (item is! num) {
        throw StateError(
          'Expected Ollama embedding value $index to be numeric, got ${item.runtimeType}.',
        );
      }

      return item.toDouble();
    }),
  );
}

ProviderMetadata? decodeOllamaEmbeddingProviderMetadata(
  Map<String, Object?> json,
) {
  return ProviderMetadata.forNamespace(
    'ollama',
    {
      if (json['total_duration'] != null)
        'totalDurationNanos': json['total_duration'],
      if (json['load_duration'] != null)
        'loadDurationNanos': json['load_duration'],
      if (json['prompt_eval_count'] != null)
        'promptEvalCount': json['prompt_eval_count'],
    },
  );
}
