// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// GPT-5 examples built on the stable OpenAI chat-model facade plus typed
/// OpenAI provider options.
Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Please set OPENAI_API_KEY environment variable');
    return;
  }

  print('=== GPT-5 Features Demo ===\n');

  await demonstrateVerbosity(apiKey);
  await demonstrateMinimalReasoning(apiKey);
  await compareModelVariants(apiKey);
}

Future<void> demonstrateVerbosity(String apiKey) async {
  print('--- Verbosity Control ---');

  final model = _createModel(apiKey, 'gpt-5.1');
  const question = 'Explain how photosynthesis works.';

  try {
    print('\n🔹 Low Verbosity (terse):');
    final lowResponse = await _generateText(
      model: model,
      prompt: question,
      maxOutputTokens: 500,
      providerOptions: const openai.OpenAIGenerateTextOptions(
        verbosity: 'low',
      ),
    );
    print(lowResponse.text);
    _printUsage(lowResponse);

    print('\n🔹 High Verbosity (detailed):');
    final highResponse = await _generateText(
      model: model,
      prompt: question,
      maxOutputTokens: 1400,
      timeout: const Duration(minutes: 5),
      providerOptions: const openai.OpenAIGenerateTextOptions(
        verbosity: 'high',
      ),
    );
    print(highResponse.text);
    _printUsage(highResponse);

    print(
      '\n   Length comparison: low=${lowResponse.text.length} chars, '
      'high=${highResponse.text.length} chars',
    );
  } catch (error) {
    print('❌ Verbosity example failed: $error');
  }

  print('\n${'=' * 50}\n');
}

Future<void> demonstrateMinimalReasoning(String apiKey) async {
  print('--- Minimal Reasoning Effort ---');

  final model = _createModel(apiKey, 'gpt-5-mini');

  try {
    print('🔹 Quick math problem with minimal reasoning:');
    final response = await _generateText(
      model: model,
      prompt: 'What is 15 * 23? Just give me the answer.',
      maxOutputTokens: 120,
      providerOptions: const openai.OpenAIGenerateTextOptions(
        reasoningEffort: openai.OpenAIReasoningEffort.minimal,
        verbosity: 'low',
      ),
    );

    print('Response: ${response.text}');
    _printUsage(response);

    if (response.reasoningText case final reasoning?) {
      print('Reasoning text: $reasoning');
    } else {
      print('Reasoning text: <not exposed>');
    }
  } catch (error) {
    print('❌ Minimal reasoning example failed: $error');
  }

  print('\n${'=' * 50}\n');
}

Future<void> compareModelVariants(String apiKey) async {
  print('--- GPT-5 Model Variants ---');

  const models = ['gpt-5.1', 'gpt-5-mini', 'gpt-5-nano'];
  const question = 'Write a haiku about artificial intelligence.';

  for (final modelId in models) {
    print('\n🔹 Model: $modelId');

    try {
      final response = await _generateText(
        model: _createModel(apiKey, modelId),
        prompt: question,
        maxOutputTokens: 160,
        providerOptions: const openai.OpenAIGenerateTextOptions(
          reasoningEffort: openai.OpenAIReasoningEffort.minimal,
          verbosity: 'low',
        ),
      );

      print('Response: ${response.text}');
      _printUsage(response);
    } catch (error) {
      print('Error with $modelId: $error');
      print('Note: $modelId may not be available in your account yet.');
    }
  }

  print('\n${'=' * 50}\n');
}

core.LanguageModel _createModel(String apiKey, String modelId) {
  return openai
      .openai(
        apiKey: apiKey,
      )
      .chatModel(modelId);
}

Future<core.GenerateTextCallResult<dynamic>> _generateText({
  required core.LanguageModel model,
  required String prompt,
  required int maxOutputTokens,
  openai.OpenAIGenerateTextOptions providerOptions =
      const openai.OpenAIGenerateTextOptions(),
  Duration? timeout,
}) {
  return core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text(prompt),
    ],
    options: core.GenerateTextOptions(
      maxOutputTokens: maxOutputTokens,
    ),
    callOptions: core.CallOptions(
      timeout: timeout,
      providerOptions: providerOptions,
    ),
  );
}

void _printUsage(core.GenerateTextCallResult<dynamic> result) {
  final usage = result.usage;
  if (usage == null) {
    print('Usage: <unavailable>');
    return;
  }

  print(
    'Usage: total=${usage.totalTokens}, '
    'input=${usage.inputTokens}, '
    'output=${usage.outputTokens}, '
    'reasoning=${usage.reasoningTokens}',
  );
}
