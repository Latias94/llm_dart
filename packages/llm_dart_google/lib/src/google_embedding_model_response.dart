import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_json_support.dart';

EmbedResult decodeGoogleEmbeddingResponse({
  required Object? body,
  required bool batch,
  required String modelId,
  required Map<String, String> headers,
}) {
  final json = decodeGoogleEmbeddingJsonObject(body);
  return EmbedResult(
    embeddings: batch
        ? decodeGoogleBatchEmbeddings(json)
        : [
            decodeGoogleSingleEmbedding(json),
          ],
    usage: decodeGoogleEmbeddingUsage(json['usageMetadata']),
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
  );
}

Map<String, Object?> decodeGoogleEmbeddingJsonObject(Object? body) {
  return decodeGoogleJsonObject(
    body,
    responseName: 'embedding',
  );
}

List<double> decodeGoogleSingleEmbedding(Map<String, Object?> json) {
  final embedding = json['embedding'];
  if (embedding is! Map) {
    throw StateError(
      'Expected a Google embedding response with an embedding object.',
    );
  }

  return decodeGoogleEmbeddingValues(
    Map<String, Object?>.from(embedding),
    fieldPath: 'embedding',
  );
}

List<List<double>> decodeGoogleBatchEmbeddings(Map<String, Object?> json) {
  final embeddings = json['embeddings'];
  if (embeddings is! List) {
    throw StateError(
      'Expected a Google batch embedding response with an embeddings list.',
    );
  }

  return embeddings.asMap().entries.map((entry) {
    final item = entry.value;
    if (item is! Map) {
      throw StateError(
        'Expected Google batch embedding item ${entry.key} to be a JSON object.',
      );
    }

    final map = Map<String, Object?>.from(item);
    final embedding = map['embedding'];
    if (embedding is! Map) {
      throw StateError(
        'Expected Google batch embedding item ${entry.key} to contain an embedding object.',
      );
    }

    return decodeGoogleEmbeddingValues(
      Map<String, Object?>.from(embedding),
      fieldPath: 'embeddings[${entry.key}].embedding',
    );
  }).toList();
}

List<double> decodeGoogleEmbeddingValues(
  Map<String, Object?> embedding, {
  required String fieldPath,
}) {
  final values = embedding['values'];
  if (values is! List) {
    throw StateError(
      'Expected Google $fieldPath.values to be a numeric list.',
    );
  }

  return List<double>.unmodifiable(
    values.map((value) {
      if (value is! num) {
        throw StateError(
          'Expected Google embedding value in $fieldPath.values to be numeric, got ${value.runtimeType}.',
        );
      }

      return value.toDouble();
    }),
  );
}

UsageStats? decodeGoogleEmbeddingUsage(Object? usage) {
  if (usage is! Map) {
    return null;
  }

  final map = Map<String, Object?>.from(usage);
  return UsageStats(
    inputTokens: googleEmbeddingIntOrNull(map['promptTokenCount']),
    totalTokens: googleEmbeddingIntOrNull(map['totalTokenCount']),
  );
}

int? googleEmbeddingIntOrNull(Object? value) {
  return switch (value) {
    int() => value,
    num() => value.toInt(),
    _ => null,
  };
}
