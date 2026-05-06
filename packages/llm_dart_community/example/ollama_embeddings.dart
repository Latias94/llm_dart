// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart_ai/llm_dart_ai.dart' as core;

Future<void> main() async {
  final baseUrl = Platform.environment['OLLAMA_BASE_URL'] ??
      community.Ollama.defaultBaseUrl;
  final modelId =
      Platform.environment['OLLAMA_EMBEDDING_MODEL'] ?? 'nomic-embed-text';

  final model = community.Ollama(
    baseUrl: baseUrl,
  ).embeddingModel(modelId);

  final result = await core.embed(
    model: model,
    value: 'Dart and Flutter are useful for client application development.',
  );

  print('model=$modelId');
  print('embeddingLength=${result.embedding.length}');
}
