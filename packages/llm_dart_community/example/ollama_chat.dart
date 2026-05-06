// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart_ai/llm_dart_ai.dart' as core;

Future<void> main() async {
  final baseUrl = Platform.environment['OLLAMA_BASE_URL'] ??
      community.Ollama.defaultBaseUrl;
  final modelId = Platform.environment['OLLAMA_MODEL'] ?? 'llama3.2';

  final model = community.Ollama(
    baseUrl: baseUrl,
  ).chatModel(modelId);

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
