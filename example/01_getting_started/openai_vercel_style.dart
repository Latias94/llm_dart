// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// Quick Start - OpenAI (Vercel AI-style API)
///
/// This example shows how to use the `createOpenAI` helper to create
/// model-centric LanguageModel instances, similar to the Vercel AI SDK.
///
/// Set environment variables before running:
/// export OPENAI_API_KEY="your-key"
Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('OPENAI_API_KEY is not set. Skipping example.');
    return;
  }

  // Create an OpenAI provider instance (Vercel AI-style).
  final openai = createOpenAI(
    apiKey: apiKey,
    // baseUrl can be customized for proxies or enterprise endpoints:
    // baseUrl: 'https://my-proxy.example.com/openai/v1/',
  );

  // 1. Chat Completions-style model
  final chatModel = openai.chat('gpt-4o-mini');

  final chatResult = await generateTextWithModel(
    chatModel,
    messages: [
      ChatMessage.user('Introduce yourself in one sentence.'),
    ],
  );

  print('Chat result: ${chatResult.text}\n');

  // 2. Responses API-style model
  final responsesModel = openai.responses('gpt-4.1-mini');

  final responsesResult = await generateTextWithModel(
    responsesModel,
    messages: [
      ChatMessage.user(
        'Give me three bullet points about the benefits of Dart.',
      ),
    ],
  );

  print('Responses result: ${responsesResult.text}\n');

  // 3. Embeddings model
  final embeddingModel = openai.embedding('text-embedding-3-small');

  final embeddings = await embeddingModel.embed(
    ['Hello world', 'LLM Dart is awesome!'],
  );

  print('Embeddings count: ${embeddings.length}');
  print('First embedding length: ${embeddings.first.length}');
}
