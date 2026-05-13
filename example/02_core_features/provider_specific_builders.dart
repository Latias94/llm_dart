// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/ollama.dart' as ollama;
import 'package:llm_dart/openai.dart' as openai;

/// Provider-specific request customization without root builders.
///
/// The modern rule is:
/// - provider/model identity goes in the focused provider facade
/// - provider request behavior goes in typed provider options
/// - shared generation controls stay in `GenerateTextOptions`
Future<void> main() async {
  print('Provider-Specific Typed Options Demo\n');

  await demoOpenAIOptions();
  await demoAnthropicOptions();
  await demoGoogleOptions();
  await demoOllamaOptions();
  explainBoundary();
}

Future<void> demoOpenAIOptions() async {
  print('--- OpenAI ---');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('  OPENAI_API_KEY not set, skipping live call.\n');
    return;
  }

  final model = openai.openai(apiKey: apiKey).chatModel(
        'gpt-4.1-mini',
        settings: const openai.OpenAIChatModelSettings(
          useResponsesApi: true,
          builtInTools: [
            openai.OpenAIWebSearchTool(),
          ],
        ),
      );

  final result = await core.generateTextCall(
    model: model,
    messages: [
      core.UserModelMessage.text(
        'Give one practical reason to keep provider options typed.',
      ),
    ],
    options: const core.GenerateTextOptions(maxOutputTokens: 120),
    callOptions: const core.CallOptions(
      providerOptions: openai.OpenAIGenerateTextOptions(
        verbosity: 'low',
        parallelToolCalls: true,
        store: false,
      ),
    ),
  );

  print('  ${result.text}\n');
}

Future<void> demoAnthropicOptions() async {
  print('--- Anthropic ---');

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('  ANTHROPIC_API_KEY not set, skipping live call.\n');
    return;
  }

  final model = anthropic.anthropic(apiKey: apiKey).chatModel(
        'claude-sonnet-4-5',
        settings: const anthropic.AnthropicChatModelSettings(
          betaFeatures: ['interleaved-thinking-2025-05-14'],
        ),
      );

  final result = await core.generateTextCall(
    model: model,
    messages: [
      core.UserModelMessage.text(
        'Explain provider-native metadata in one short sentence.',
      ),
    ],
    options: const core.GenerateTextOptions(maxOutputTokens: 120),
    callOptions: const core.CallOptions(
      providerOptions: anthropic.AnthropicGenerateTextOptions(
        serviceTier: 'auto',
        metadata: {
          'example': 'provider_specific_options',
        },
      ),
    ),
  );

  print('  ${result.text}\n');
}

Future<void> demoGoogleOptions() async {
  print('--- Google ---');

  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('  GOOGLE_API_KEY not set, skipping live call.\n');
    return;
  }

  final model = google.google(apiKey: apiKey).chatModel(
        'gemini-2.5-flash',
        settings: const google.GoogleChatModelSettings(
          safetySettings: [
            google.GoogleSafetySetting(
              category: google.GoogleHarmCategory.dangerousContent,
              threshold: google.GoogleHarmBlockThreshold.blockOnlyHigh,
            ),
          ],
        ),
      );

  final result = await core.generateTextCall(
    model: model,
    messages: [
      core.UserModelMessage.text(
        'Name one SDK design benefit of typed provider options.',
      ),
    ],
    options: const core.GenerateTextOptions(maxOutputTokens: 120),
    callOptions: const core.CallOptions(
      providerOptions: google.GoogleGenerateTextOptions(
        thinkingLevel: google.GoogleThinkingLevel.low,
        includeThoughts: false,
      ),
    ),
  );

  print('  ${result.text}\n');
}

Future<void> demoOllamaOptions() async {
  print('--- Ollama ---');

  final baseUrl =
      Platform.environment['OLLAMA_BASE_URL'] ?? ollama.ollamaDefaultBaseUrl;
  final model = ollama.ollama(baseUrl: baseUrl).chatModel('llama3.2');

  try {
    final result = await core.generateTextCall(
      model: model,
      messages: [
        core.UserModelMessage.text(
          'Explain why local runtime tuning should be provider-owned.',
        ),
      ],
      options: const core.GenerateTextOptions(maxOutputTokens: 120),
      callOptions: const core.CallOptions(
        providerOptions: ollama.OllamaGenerateTextOptions(
          numCtx: 4096,
          numThread: 8,
          keepAlive: '10m',
        ),
      ),
    );

    print('  ${result.text}\n');
  } catch (error) {
    print('  Ollama call failed at $baseUrl: $error\n');
  }
}

void explainBoundary() {
  print('--- Boundary Rule ---');
  print('  Root no longer owns a provider builder DSL.');
  print('  Use shared options for cross-provider behavior.');
  print('  Use typed provider options for native request behavior.');
  print('  Read ProviderMetadata only from results and stream events.');
}
