import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// Example demonstrating GPT-5 specific features
///
/// This example shows how to use GPT-5's new capabilities:
/// - Verbosity control for output detail
/// - Minimal reasoning effort for faster responses
/// - GPT-5 model variants (gpt-5, gpt-5-mini, gpt-5-nano)
Future<void> main() async {
  // Get API key from environment
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('Please set OPENAI_API_KEY environment variable');
    return;
  }

  print('=== GPT-5 Features Demo ===\n');

  // Example 1: Using verbosity control
  await demonstrateVerbosity(apiKey);

  // Example 2: Using minimal reasoning effort
  await demonstrateMinimalReasoning(apiKey);

  // Example 3: Comparing GPT-5 model variants
  await compareModelVariants(apiKey);
}

/// Demonstrates verbosity control with GPT-5
Future<void> demonstrateVerbosity(String apiKey) async {
  print('--- Verbosity Control ---');

  final question = 'Explain how photosynthesis works.';

  // Low verbosity - terse response
  print('\n🔹 Low Verbosity (terse):');
  final lowProvider = await ai()
      .openai((openai) => openai.verbosity(Verbosity.low))
      .apiKey(apiKey)
      .model('gpt-5')
      .build();

  final lowResponse = await lowProvider.chat([
    ChatMessage.user(question),
  ]);
  print(lowResponse.text ?? 'No response');

  // High verbosity - detailed response
  print('\n🔹 High Verbosity (detailed):');
  final highProvider = await ai()
      .openai((openai) => openai.verbosity(Verbosity.high))
      .apiKey(apiKey)
      .model('gpt-5')
      .timeout(Duration(minutes: 5)) // Longer timeout for high verbosity
      .build();

  final highResponse = await highProvider.chat([
    ChatMessage.user(question),
  ]);
  print(highResponse.text ?? 'No response');

  print('\n${'=' * 50}\n');
}

/// Demonstrates minimal reasoning effort for faster responses
Future<void> demonstrateMinimalReasoning(String apiKey) async {
  print('--- Minimal Reasoning Effort ---');

  final provider = await ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-5')
      .reasoningEffort(ReasoningEffort.minimal) // New minimal option
      .build();

  print('🔹 Quick math problem with minimal reasoning:');
  final response = await provider.chat([
    ChatMessage.user('What is 15 * 23? Just give me the answer.'),
  ]);

  print('Response: ${response.text ?? 'No response'}');
  print('Usage: ${response.usage}');

  print('\n${'=' * 50}\n');
}

/// Compares different GPT-5 model variants
Future<void> compareModelVariants(String apiKey) async {
  print('--- GPT-5 Model Variants ---');

  final models = ['gpt-5', 'gpt-5-mini', 'gpt-5-nano'];
  final question = 'Write a haiku about artificial intelligence.';

  for (final model in models) {
    print('\n🔹 Model: $model');

    final provider = await ai().openai().apiKey(apiKey).model(model).build();

    try {
      final response = await provider.chat([
        ChatMessage.user(question),
      ]);

      print('Response: ${response.text ?? 'No response'}');
      if (response.usage != null) {
        print('Tokens: ${response.usage!.totalTokens}');
      }
    } catch (e) {
      print('Error with $model: $e');
      print('Note: $model may not be available in your region yet.');
    }
  }

  print('\n${'=' * 50}\n');
}
