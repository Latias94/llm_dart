// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama_pkg;
import 'package:llm_dart_ai/llm_dart_ai.dart' as core;

Future<void> main() async {
  final baseUrl = Platform.environment['OLLAMA_BASE_URL'] ??
      ollama_pkg.Ollama.defaultBaseUrl;
  final modelId =
      Platform.environment['OLLAMA_EMBEDDING_MODEL'] ?? 'nomic-embed-text';

  final model = ollama_pkg
      .ollama(
        baseUrl: baseUrl,
      )
      .embeddingModel(modelId);

  final result = await core.embed(
    model: model,
    value: 'Dart and Flutter are useful for client application development.',
  );

  print('model=$modelId');
  print('embeddingLength=${result.embedding.length}');
}
