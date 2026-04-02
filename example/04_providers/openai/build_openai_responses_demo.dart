// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

/// Compatibility-boundary demo for `buildOpenAIResponses()`.
///
/// New app-facing code should usually prefer:
/// - `AI.openai(...).chatModel(...)`
/// - shared `core.generateTextCall(...)` / `core.streamTextCall(...)`
///
/// Use `buildOpenAIResponses()` only when you explicitly need raw OpenAI
/// response lifecycle APIs such as:
/// - `responses.getResponse(...)`
/// - `responses.continueConversation(...)`
/// - `responses.deleteResponse(...)`
Future<void> main() async {
  print('🚀 buildOpenAIResponses() Boundary Demo\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  await demonstrateStableFirstAlternative(apiKey);
  await demonstrateLifecycleBoundary(apiKey);
  await demonstrateGuardrails(apiKey);

  print('✅ buildOpenAIResponses() boundary demo completed!');
}

Future<void> demonstrateStableFirstAlternative(String apiKey) async {
  print('--- Stable-First Alternative ---');

  try {
    final model = llm.AI.openai(
      apiKey: apiKey,
    ).chatModel(
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
          'Give me a short update on recent AI model releases.',
        ),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 300,
      ),
    );

    print('Stable response: ${result.text}');
    print('Stable response ID: ${result.responseId ?? 'unknown'}');
    print('ℹ️  If this is enough, do not drop to buildOpenAIResponses().');
    print('');
  } catch (error) {
    print('Error in stable-first example: $error\n');
  }
}

Future<void> demonstrateLifecycleBoundary(String apiKey) async {
  print('--- OpenAI Lifecycle Boundary ---');

  try {
    final provider = await llm.ai()
        .openai((openaiBuilder) => openaiBuilder.webSearchTool())
        .apiKey(apiKey)
        .model('gpt-4o')
        .buildOpenAIResponses();

    print(
      'Provider supports openaiResponses: '
      '${provider.supports(llm.LLMCapability.openaiResponses)}',
    );

    final responses = provider.responses!;
    final response = await responses.chat([
      llm.ChatMessage.user('Summarize the benefits of renewable energy.'),
    ]);

    print('Lifecycle response: ${_truncate(response.text ?? '<no text>')}');

    final responseId = response is llm.OpenAIResponsesResponse
        ? response.responseId
        : null;
    if (responseId != null) {
      final fetched = await responses.getResponse(responseId);
      print('Fetched by ID: ${_truncate(fetched.text ?? '<no text>')}');
    }

    print(
      'ℹ️  This path is for provider-specific response lifecycle management, '
      'not normal Flutter chat flows.',
    );
    print('');
  } catch (error) {
    print('Error in lifecycle boundary example: $error\n');
  }
}

Future<void> demonstrateGuardrails(String apiKey) async {
  print('--- Guardrails ---');

  try {
    final standardProvider = await llm.ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .build();
    final responsesProvider = await llm.ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .buildOpenAIResponses();

    final standardHasResponses = standardProvider is llm.ProviderCapabilities &&
        (standardProvider as llm.ProviderCapabilities)
            .supports(llm.LLMCapability.openaiResponses);
    final boundaryHasResponses =
        responsesProvider.supports(llm.LLMCapability.openaiResponses);

    print('Standard build exposes openaiResponses: $standardHasResponses');
    print('buildOpenAIResponses exposes openaiResponses: $boundaryHasResponses');
  } catch (error) {
    print('Capability comparison failed: $error');
  }

  try {
    await llm.ai()
        .anthropic()
        .apiKey('dummy-key')
        .model('claude-3-sonnet-20240229')
        .buildOpenAIResponses();
    print('❌ Non-OpenAI provider should not support buildOpenAIResponses().');
  } catch (error) {
    print('Correctly rejected non-OpenAI provider: ${_truncate(error.toString())}');
  }

  print('');
}

String _truncate(String text, {int maxLength = 120}) {
  if (text.length <= maxLength) {
    return text;
  }

  return '${text.substring(0, maxLength)}...';
}
