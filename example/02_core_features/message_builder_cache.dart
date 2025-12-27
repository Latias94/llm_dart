import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Anthropic prompt caching example (Vercel-style escape hatch).
///
/// **⚠️ ANTHROPIC / ANTHROPIC-COMPATIBLE ONLY**:
/// Prompt caching is provider-specific. Other providers will ignore
/// `providerOptions['anthropic']['cacheControl']`.
///
/// In the new architecture:
/// - Provider-only knobs live in `providerOptions` (namespaced by provider id)
/// - Prompt IR (`Prompt`) is the recommended user-facing prompt surface
/// - `ChatMessage.extensions` is reserved for internal protocol adapters
///
/// To run:
/// ```bash
/// export ANTHROPIC_API_KEY="..."
/// dart run example/02_core_features/message_builder_cache.dart
/// ```
Future<void> main() async {
  print('=== Anthropic Prompt Caching (providerOptions) ===\n');

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set ANTHROPIC_API_KEY to run this example.');
    return;
  }

  registerAnthropic();

  final cacheControl1h = {
    'type': 'ephemeral',
    'ttl': '1h',
  };

  final cacheControl5m = {
    'type': 'ephemeral',
    'ttl': '5m',
  };

  final model = await LLMBuilder()
      .provider(anthropicProviderId)
      .apiKey(apiKey)
      .model('claude-sonnet-4-20250514')
      // Config-level default (call-wide) cache control.
      .option('cacheControl', cacheControl1h)
      .build();

  // Prompt-level override (per message / part).
  final prompt = Prompt(
    messages: [
      PromptMessage(
        role: ChatRole.system,
        parts: [
          const TextPart('You are a helpful AI assistant.'),
          const TextPart(''),
          TextPart(
            'Large static document (cached for 1h).',
            providerOptions: {
              'anthropic': {'cacheControl': cacheControl1h},
            },
          ),
          const TextPart(''),
          TextPart(
            'Short-lived session context (cached for 5m).',
            providerOptions: {
              'anthropic': {'cacheControl': cacheControl5m},
            },
          ),
        ],
      ),
      PromptMessage.user(
          'Summarize the cached context and give a short answer.'),
    ],
  );

  try {
    final result = await generateText(
      model: model,
      promptIr: prompt,
    );

    print(result.text);
    print('\nproviderMetadata keys: ${result.providerMetadata?.keys.toList()}');
  } catch (e) {
    print('❌ Request failed: $e');
  }
}
