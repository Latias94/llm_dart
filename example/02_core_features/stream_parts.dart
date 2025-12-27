// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';

/// 🧩 Stream Parts - Vercel-style streaming surface
///
/// This example demonstrates the recommended streaming APIs:
/// - `streamChatParts`: richer, provider-agnostic stream parts with block boundaries
/// - `streamText`: simpler legacy-friendly stream parts
///
/// Notes:
/// - Provider-native features should flow through `providerTools` / `providerOptions`
///   and be observed via `providerMetadata` (escape hatch).
/// - Concrete tool implementations (web fetch/search, file IO, etc.) should live
///   in your app code; the SDK focuses on tool protocol + orchestration.
///
/// Before running, set your API key:
/// export GROQ_API_KEY="your-key"
void main() async {
  print('🧩 Stream Parts - Vercel-style streaming surface\n');

  final apiKey = Platform.environment['GROQ_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GROQ_API_KEY environment variable');
    return;
  }

  registerGroq();

  final model = await LLMBuilder()
      .provider(groqProviderId)
      .apiKey(apiKey)
      .model('llama-3.1-8b-instant')
      .temperature(0.7)
      .maxTokens(300)
      .build();

  print('Prompt: Explain “streaming” in 3 bullet points.\n');

  await for (final part in streamChatParts(
    model: model,
    prompt: 'Explain “streaming” in 3 bullet points.',
  )) {
    switch (part) {
      case LLMTextStartPart():
        stdout.write('[text] ');
        break;

      case LLMTextDeltaPart(:final delta):
        stdout.write(delta);
        break;

      case LLMTextEndPart():
        stdout.writeln('\n');
        break;

      case LLMReasoningStartPart():
        stdout.writeln('[thinking]');
        break;

      case LLMReasoningDeltaPart(:final delta):
        stdout.writeln(delta);
        break;

      case LLMReasoningEndPart():
        stdout.writeln('[thinking end]\n');
        break;

      case LLMToolCallStartPart(:final toolCall):
        stdout.writeln('[tool start] ${toolCall.function.name}');
        break;

      case LLMToolCallDeltaPart(:final toolCall):
        stdout.writeln(
          '[tool delta] ${toolCall.function.name} '
          '(args+=${toolCall.function.arguments.length} chars)',
        );
        break;

      case LLMToolCallEndPart(:final toolCallId):
        stdout.writeln('[tool end] $toolCallId');
        break;

      case LLMToolResultPart(:final result):
        stdout.writeln('[tool result] ${result.toolCallId}');
        break;

      case LLMProviderMetadataPart(:final providerMetadata):
        stdout.writeln('[metadata] keys=${providerMetadata.keys.toList()}');
        break;

      case LLMFinishPart(:final response):
        stdout.writeln('\n✅ Finished');
        stdout.writeln('text=${response.text?.length ?? 0} chars');
        stdout.writeln('thinking=${response.thinking?.length ?? 0} chars');
        stdout.writeln('toolCalls=${response.toolCalls?.length ?? 0}');
        stdout.writeln(
            'providerMetadata keys=${response.providerMetadata?.keys.toList()}');
        break;

      case LLMErrorPart(:final error):
        stderr.writeln('❌ Error: $error');
        break;
    }
  }

  print('\nTip: For local tool execution, use `streamToolLoopParts(...)`.');
}
