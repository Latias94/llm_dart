import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// Google Gemini code execution example.
///
/// This example shows how to:
/// - Enable Gemini's `code_execution` tool.
/// - Ask the model to run a small code snippet and return the result.
///
/// Reference: https://ai.google.dev/gemini-api/docs/code-execution
Future<void> main() async {
  print('💻 Google Gemini Code Execution Example\n');

  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set GOOGLE_API_KEY environment variable');
    print('   Get your API key from: https://aistudio.google.com/app/apikey');
    return;
  }

  try {
    final model = await ai()
        .google((google) => google.enableCodeExecution())
        .apiKey(apiKey)
        .model('gemini-2.5-flash')
        .buildLanguageModel();

    final messages = <ModelMessage>[
      ModelMessage.systemText(
        'You are a helpful assistant that can execute code for calculations '
        'and small simulations. Prefer running code when it improves accuracy.',
      ),
      ModelMessage.userText(
        '使用代码计算 1 到 10 的平方和，并给出计算过程。',
      ),
    ];

    final response = await generateTextPromptWithModel(
      model,
      messages: messages,
    );

    print('=== Code Execution Response ===');
    print(response.text);

    if (response.thinking != null) {
      print('\n--- Reasoning / Code Thoughts ---');
      print(response.thinking);
    }

    final meta = response.metadata;
    if (meta != null) {
      print('\n--- Call Metadata ---');
      print('provider: ${meta.provider}, model: ${meta.model}');
      print('providerMetadata: ${meta.providerMetadata}');
    }
  } catch (e) {
    print('❌ Error while calling Gemini code execution: $e');
  }
}
