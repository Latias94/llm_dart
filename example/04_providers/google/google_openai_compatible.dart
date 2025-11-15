// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// Google Gemini via OpenAI-Compatible Interface
///
/// This example demonstrates how to use Google Gemini models through the
/// OpenAI-compatible interface exposed by `googleOpenAI()`.
///
/// It showcases:
/// - Model selection for chat and reasoning
/// - Enabling thinking/reasoning output
/// - Configuring web search for current information
Future<void> main() async {
  print('🔗 Google Gemini (OpenAI-Compatible) Example\n');

  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GOOGLE_API_KEY environment variable');
    print('   Get your API key from: https://aistudio.google.com/app/apikey');
    return;
  }

  // Recommended reasoning-capable model (see provider profile).
  const modelId = 'gemini-2.5-flash-preview-05-20';

  // Build provider using the OpenAI-compatible interface.
  // Reasoning configuration and web search are applied via extensions and
  // translated by the Google-specific request transformers.
  final provider = await ai()
      .googleOpenAI()
      .apiKey(apiKey)
      .model(modelId)
      // Enable higher reasoning effort for complex tasks.
      .reasoningEffort(ReasoningEffort.high)
      // Enable web search with sensible defaults.
      .enableWebSearch()
      .webSearch(
    maxResults: 5,
    blockedDomains: const ['reddit.com', 'twitter.com'],
  ).build();

  // Example question that benefits from up-to-date information and reasoning.
  final messages = [
    ChatMessage.system(
      'You are a research assistant. Answer concisely and cite key sources.',
    ),
    ChatMessage.user(
      'Summarize the latest advances in small language models (SLMs) '
      'for on-device inference. Focus on practical deployment tips.',
    ),
  ];

  try {
    final response = await provider.chat(messages);

    print('\n🧠 Model reply:\n');
    print(response.text ?? '<no text>');

    if (response.thinking != null) {
      print('\n💭 Model thinking (truncated):\n');
      final thinking = response.thinking!;
      print(thinking.length > 600
          ? '${thinking.substring(0, 600)}...'
          : thinking);
    }

    if (response.usage != null) {
      print('\n📊 Usage: ${response.usage}');
    }
  } catch (e) {
    print('\n❌ Request failed: $e');
  }
}
