import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../common/openai_json_support.dart';
import '../common/openai_non_text_model_support.dart';

EmbedResult decodeOpenAIEmbeddingResponse({
  required Object? body,
  required String modelId,
  required Map<String, String> headers,
}) {
  final json = decodeOpenAIJsonObject(
    body,
    responseName: 'embeddings response',
  );

  return EmbedResult(
    embeddings: decodeOpenAIEmbeddingData(json),
    usage: decodeOpenAIEmbeddingUsage(json['usage']),
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
  );
}

List<List<double>> decodeOpenAIEmbeddingData(Map<String, Object?> json) {
  final data = json['data'];
  if (data is! List) {
    throw StateError(
      'Expected an OpenAI embeddings response with a data list.',
    );
  }

  final indexedEmbeddings = <({int index, List<double> embedding})>[];
  for (var index = 0; index < data.length; index += 1) {
    final item = data[index];
    if (item is! Map) {
      throw StateError(
        'Expected OpenAI embedding item $index to be a JSON object.',
      );
    }

    final map = Map<String, Object?>.from(item);
    final embedding = map['embedding'];
    if (embedding is! List) {
      throw StateError(
        'Expected OpenAI embedding item $index to contain an embedding list.',
      );
    }

    indexedEmbeddings.add(
      (
        index: openAIIntOrNull(map['index']) ?? index,
        embedding: decodeOpenAIEmbeddingValues(embedding),
      ),
    );
  }

  indexedEmbeddings.sort((left, right) => left.index.compareTo(right.index));
  return indexedEmbeddings.map((entry) => entry.embedding).toList();
}

List<double> decodeOpenAIEmbeddingValues(List<Object?> values) {
  return List<double>.unmodifiable(
    values.map((value) {
      if (value is! num) {
        throw StateError(
          'Expected OpenAI embedding value to be numeric, got '
          '${value.runtimeType}.',
        );
      }

      return value.toDouble();
    }),
  );
}

UsageStats? decodeOpenAIEmbeddingUsage(Object? usage) {
  if (usage is! Map) {
    return null;
  }

  final map = Map<String, Object?>.from(usage);
  return UsageStats(
    inputTokens: openAIIntOrNull(map['prompt_tokens']),
    totalTokens: openAIIntOrNull(map['total_tokens']),
  );
}
