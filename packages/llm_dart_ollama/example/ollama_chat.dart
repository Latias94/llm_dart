// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama_pkg;
import 'package:llm_dart_ai/llm_dart_ai.dart' as core;

Future<void> main() async {
  final baseUrl = Platform.environment['OLLAMA_BASE_URL'] ??
      ollama_pkg.Ollama.defaultBaseUrl;
  final modelId = Platform.environment['OLLAMA_MODEL'] ?? 'llama3.2';

  final model = ollama_pkg
      .ollama(
        baseUrl: baseUrl,
      )
      .chatModel(modelId);

  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.SystemPromptMessage.text('You are concise.'),
      core.UserPromptMessage.text('Explain why local models can be useful.'),
    ],
  );

  print('model=$modelId');
  print(result.text);
}
