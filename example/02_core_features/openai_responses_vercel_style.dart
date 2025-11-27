// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// OpenAI Responses API - Vercel-style streaming example
///
/// This example mirrors the Vercel AI pattern:
///   model: openai.responses('o3-mini')
///   result = streamText({ model, messages })
///
/// Here we:
/// - create an OpenAI Responses model with `createOpenAI`
/// - stream thinking + text deltas via `streamTextWithModel`
/// - print the final usage information
///
/// Before running:
///   export OPENAI_API_KEY="your-key"
Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('OPENAI_API_KEY is not set. Skipping example.');
    return;
  }

  // 1. Configure OpenAI provider (Vercel-style).
  final openai = createOpenAI(apiKey: apiKey);

  // 2. Create a Responses API-backed LanguageModel.
  //
  // In Vercel:
  //   const model = openai.responses('o3-mini');
  //
  // In Dart:
  final model = openai.responses('gpt-4.1-mini');

  // 3. Stream thinking + text parts using the high-level helper.
  final prompt = ChatPromptBuilder.user()
      .text('Explain what a binary search tree is, in 3 bullet points.')
      .build();

  print('Streaming response from OpenAI Responses API (streamTextParts):\n');

  await for (final part in adaptStreamText(
    streamTextWithModel(
      model,
      promptMessages: [prompt],
    ),
  )) {
    switch (part) {
      case StreamThinkingDelta(delta: final delta):
        // Thinking deltas (reasoning) in gray
        stdout.write('\x1B[90m$delta\x1B[0m');
        break;
      case StreamTextDelta(delta: final delta):
        // Final answer tokens
        stdout.write(delta);
        break;
      case StreamFinish(result: final result):
        print('\n\n---');
        final usage = result.usage;
        if (usage != null) {
          print('Tokens: prompt=${usage.promptTokens}, '
              'completion=${usage.completionTokens}, '
              'reasoning=${usage.reasoningTokens}, '
              'total=${usage.totalTokens}');
        }
        break;
      default:
        // For simplicity we ignore tool parts here.
        break;
    }
  }
}
