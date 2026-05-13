// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/openai.dart' as openai;

/// Migration-boundary demo for the removed `buildOpenAIResponses()` helper.
///
/// The replacement is not another root builder. Use:
/// - `openai(...).chatModel(..., settings: OpenAIChatModelSettings(...))`
///   for normal app-facing generation
/// - `openai(...).responsesLifecycle()` for raw response lifecycle CRUD
Future<void> main() async {
  print('OpenAI Responses Boundary Demo\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Please set OPENAI_API_KEY environment variable');
    return;
  }

  await demonstrateStableFirstAlternative(apiKey);
  await demonstrateDirectLifecycleEquivalent(apiKey);
  demonstrateGuardrails(apiKey);

  print('OpenAI Responses boundary demo completed.');
}

Future<void> demonstrateStableFirstAlternative(String apiKey) async {
  print('--- Stable-First Alternative ---');

  try {
    final model = openai.openai(apiKey: apiKey).chatModel(
          'gpt-4o',
          settings: const openai.OpenAIChatModelSettings(
            useResponsesApi: true,
            builtInTools: [
              openai.OpenAIWebSearchTool(),
            ],
          ),
        );

    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Give me a short update on why SDKs split app APIs from provider lifecycle APIs.',
        ),
      ],
      options: const core.GenerateTextOptions(maxOutputTokens: 300),
    );

    print('Stable response: ${result.text}');
    print('Stable response ID: ${result.responseId ?? 'unknown'}');
    print('If this is enough, do not drop to the raw lifecycle client.');
    print('');
  } catch (error) {
    print('Error in stable-first example: $error\n');
  }
}

Future<void> demonstrateDirectLifecycleEquivalent(String apiKey) async {
  print('--- Direct Lifecycle Equivalent ---');

  try {
    final responses = openai.openai(apiKey: apiKey).responsesLifecycle();

    print(
      'This is the provider-owned replacement for the old builder convenience helper.',
    );

    final response = await responses.createResponse(
      const {
        'model': 'gpt-4o',
        'input': 'Summarize the benefits of renewable energy.',
      },
    );

    print(
        'Lifecycle response: ${_truncate(response.outputText ?? '<no text>')}');

    final responseId = response.id;
    if (responseId != null) {
      final fetched = await responses.getResponse(responseId);
      print('Fetched by ID: ${_truncate(fetched.outputText ?? '<no text>')}');
    }

    print(
      'This path is for provider-specific response lifecycle management, not normal app chat flows.',
    );
    print('');
  } catch (error) {
    print('Error in lifecycle boundary example: $error\n');
  }
}

void demonstrateGuardrails(String apiKey) {
  print('--- Guardrails ---');

  final provider = openai.openai(apiKey: apiKey);
  final stableModel = provider.chatModel(
    'gpt-4o-mini',
    settings: const openai.OpenAIChatModelSettings(useResponsesApi: true),
  );
  final responses = provider.responsesLifecycle();

  print('Stable model type: ${stableModel.runtimeType}');
  print('Responses lifecycle client type: ${responses.runtimeType}');
  print(
    'Guardrail: the stable LanguageModel path intentionally does not expose raw response lifecycle CRUD.',
  );
  print('');
}

String _truncate(String text, {int maxLength = 120}) {
  if (text.length <= maxLength) {
    return text;
  }

  return '${text.substring(0, maxLength)}...';
}
