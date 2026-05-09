// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_community/llm_dart_community.dart';

Future<void> main() async {
  final baseUrl =
      Platform.environment['OLLAMA_BASE_URL'] ?? Ollama.defaultBaseUrl;

  final catalog = ollama(baseUrl: baseUrl).catalog();
  final models = await catalog.listModels();

  print('Installed Ollama models: ${models.length}');
  for (final model in models.take(10)) {
    final family = model.details?.family ?? 'unknown-family';
    print('- ${model.name} ($family)');
  }
}
