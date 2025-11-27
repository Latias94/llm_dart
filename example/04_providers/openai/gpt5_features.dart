import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// Example demonstrating GPT-5 specific features
///
/// This example shows how to use GPT-5's new capabilities:
/// - Verbosity control for output detail
/// - Minimal reasoning effort for faster responses
/// - GPT-5 model variants (gpt-5.1, gpt-5-mini, gpt-5-nano)
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
  final lowModel = await ai()
      .openai((openai) => openai.verbosity(Verbosity.low))
      .apiKey(apiKey)
      .model('gpt-5.1')
      .buildLanguageModel();

  final lowPrompt = ChatPromptBuilder.user().text(question).build();
  final lowResponse = await generateTextWithModel(
    lowModel,
    promptMessages: [lowPrompt],
  );
  print(lowResponse.text ?? 'No response');

  // High verbosity - detailed response
  print('\n🔹 High Verbosity (detailed):');
  final highModel = await ai()
      .openai((openai) => openai.verbosity(Verbosity.high))
      .apiKey(apiKey)
      .model('gpt-5.1')
      .timeout(Duration(minutes: 5)) // Longer timeout for high verbosity
      .buildLanguageModel();

  final highPrompt = ChatPromptBuilder.user().text(question).build();
  final highResponse = await generateTextWithModel(
    highModel,
    promptMessages: [highPrompt],
  );
  print(highResponse.text ?? 'No response');

  print('\n${'=' * 50}\n');
}

/// Demonstrates minimal reasoning effort for faster responses
Future<void> demonstrateMinimalReasoning(String apiKey) async {
  print('--- Minimal Reasoning Effort ---');

  final model = await ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-5-mini')
      .reasoningEffort(ReasoningEffort.minimal) // New minimal option
      .buildLanguageModel();

  print('🔹 Quick math problem with minimal reasoning:');
  final prompt = ChatPromptBuilder.user()
      .text('What is 15 * 23? Just give me the answer.')
      .build();
  final response = await generateTextWithModel(
    model,
    promptMessages: [prompt],
  );

  print('Response: ${response.text ?? 'No response'}');
  print('Usage: ${response.usage}');

  print('\n${'=' * 50}\n');
}

/// Compares different GPT-5 model variants
Future<void> compareModelVariants(String apiKey) async {
  print('--- GPT-5 Model Variants ---');

  final models = ['gpt-5.1', 'gpt-5-mini', 'gpt-5-nano'];
  final question = 'Write a haiku about artificial intelligence.';

  for (final model in models) {
    print('\n🔹 Model: $model');

    final languageModel =
        await ai().openai().apiKey(apiKey).model(model).buildLanguageModel();

    try {
      final prompt = ChatPromptBuilder.user().text(question).build();
      final response = await generateTextWithModel(
        languageModel,
        promptMessages: [prompt],
      );

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
