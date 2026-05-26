// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as deepseek;
import 'package:llm_dart_openai/llm_dart_openai.dart' as groq;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openrouter;
import 'package:llm_dart_openai/llm_dart_openai.dart' as xai;

const _togetherBaseUrl = 'https://api.together.xyz/v1';
const _togetherModelId = 'meta-llama/Llama-3-70b-chat-hf';
const _togetherProfile = openai.OpenAICompatibleProfile(
  providerId: 'together-ai',
  defaultBaseUrl: _togetherBaseUrl,
);

/// Stable OpenAI-family profile examples.
///
/// This example demonstrates two explicit layers:
/// - stable provider facades such as `deepSeek(...)` and `openRouter(...)`
/// - provider-owned settings/options when capabilities diverge
///
/// "OpenAI-compatible" here means "shares the `LanguageModel` contract",
/// not "every provider feature should be forced into a shared abstraction".
Future<void> main() async {
  print('OpenAI-family Stable Profile Examples\n');

  await demonstrateStableProfiles();
  await demonstrateProviderOwnedExtensions();
  await demonstrateFallbackComposition();
  await demonstrateGenericCompatibleEndpoint();

  print('OpenAI-family example completed.');
}

Future<void> demonstrateStableProfiles() async {
  print('=== Stable Profile Facades ===');

  final cases = <({
    String label,
    String description,
    String envVar,
    core.LanguageModel Function(String apiKey) createModel,
  })>[
    (
      label: 'DeepSeek',
      description: 'Dedicated facade for cost-effective chat and reasoning.',
      envVar: 'DEEPSEEK_API_KEY',
      createModel: (apiKey) => deepseek.deepSeek(apiKey: apiKey).chatModel(
            'deepseek-chat',
          ),
    ),
    (
      label: 'Groq',
      description: 'Dedicated facade for low-latency inference.',
      envVar: 'GROQ_API_KEY',
      createModel: (apiKey) =>
          groq.groq(apiKey: apiKey).chatModel('llama-3.3-70b-versatile'),
    ),
    (
      label: 'xAI',
      description: 'Dedicated facade for Grok models and live-search options.',
      envVar: 'XAI_API_KEY',
      createModel: (apiKey) => xai.xai(apiKey: apiKey).chatModel('grok-3'),
    ),
    (
      label: 'OpenRouter',
      description: 'Dedicated facade for audited OpenRouter model routing.',
      envVar: 'OPENROUTER_API_KEY',
      createModel: (apiKey) =>
          openrouter.openRouter(apiKey: apiKey).chatModel('openai/gpt-4o-mini'),
    ),
  ];

  for (final entry in cases) {
    final apiKey = _readApiKey(entry.envVar);
    if (apiKey == null) {
      print('- ${entry.label}: skipped (${entry.envVar} is not set)');
      continue;
    }

    try {
      final model = entry.createModel(apiKey);
      final result = await _generateText(
        model: model,
        prompt: [
          core.SystemPromptMessage.text(
            'Answer concisely and focus on app architecture tradeoffs.',
          ),
          core.UserPromptMessage.text(
            'Why might a Flutter chat app keep multiple provider profiles available?',
          ),
        ],
      );

      print('- ${entry.label}');
      print('  Model: ${model.providerId}/${model.modelId}');
      print('  Why this facade exists: ${entry.description}');
      print('  Answer: ${_truncate(result.text)}');
      _printUsage(result);
    } catch (error) {
      print('- ${entry.label}: error -> $error');
    }
  }

  print('');
}

Future<void> demonstrateProviderOwnedExtensions() async {
  print('=== Provider-Owned Extensions ===');

  await demonstrateDeepSeekReasoningStream();
  await demonstrateXAILiveSearch();
  await demonstrateOpenRouterOnlineRouting();
}

Future<void> demonstrateDeepSeekReasoningStream() async {
  final apiKey = _readApiKey('DEEPSEEK_API_KEY');
  if (apiKey == null) {
    print('- DeepSeek reasoning stream: skipped (DEEPSEEK_API_KEY is not set)');
    return;
  }

  try {
    final model =
        deepseek.deepSeek(apiKey: apiKey).chatModel('deepseek-reasoner');
    final stream = core.streamTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Explain how a Flutter app should separate transport, domain state, and provider-specific UI details.',
        ),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.2,
        maxOutputTokens: 220,
      ),
    );

    final reasoning = StringBuffer();
    final answer = StringBuffer();

    await for (final event in stream) {
      switch (event) {
        case core.ReasoningDeltaEvent(:final delta):
          reasoning.write(delta);
        case core.TextDeltaEvent(:final delta):
          answer.write(delta);
        default:
          break;
      }
    }

    print('- DeepSeek reasoning stream');
    print('  Model: ${model.providerId}/${model.modelId}');
    print('  Reasoning preview: ${_truncate(reasoning.toString())}');
    print('  Answer: ${_truncate(answer.toString())}');
  } catch (error) {
    print('- DeepSeek reasoning stream: error -> $error');
  }
}

Future<void> demonstrateXAILiveSearch() async {
  final apiKey = _readApiKey('XAI_API_KEY');
  if (apiKey == null) {
    print('- xAI live search: skipped (XAI_API_KEY is not set)');
    return;
  }

  try {
    final model = xai.xai(apiKey: apiKey).chatModel('grok-3');
    final result = await _generateText(
      model: model,
      prompt: [
        core.SystemPromptMessage.text(
          'Use fresh information only when it helps answer the question.',
        ),
        core.UserPromptMessage.text(
          'What are recent themes in AI product launches this week?',
        ),
      ],
      callOptions: const core.CallOptions(
        providerOptions: xai.XAIGenerateTextOptions(
          search: xai.XAILiveSearchOptions.autoWeb(
            maxSearchResults: 4,
          ),
        ),
      ),
    );

    print('- xAI live search');
    print('  Model: ${model.providerId}/${model.modelId}');
    print('  Answer: ${_truncate(result.text)}');
    _printSources(result);
    _printUsage(result);
  } catch (error) {
    print('- xAI live search: error -> $error');
  }
}

Future<void> demonstrateOpenRouterOnlineRouting() async {
  final apiKey = _readApiKey('OPENROUTER_API_KEY');
  if (apiKey == null) {
    print(
      '- OpenRouter online routing: skipped (OPENROUTER_API_KEY is not set)',
    );
    return;
  }

  try {
    final model = openrouter.openRouter(apiKey: apiKey).chatModel(
          'openai/gpt-4o-mini',
          settings: const openrouter.OpenRouterChatModelSettings(
            search: openrouter.OpenRouterSearchOptions.onlineModel(),
          ),
        );

    final routingFeature = model.capabilityProfile.providerFeature(
      'openrouter',
      'openrouter.onlineModelRouting',
    );

    final result = await _generateText(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Why is explicit online-model routing different from a generic web-search flag?',
        ),
      ],
    );

    print('- OpenRouter online routing');
    print('  Model: ${model.providerId}/${model.modelId}');
    print('  Routing feature: ${routingFeature?.detail ?? 'not exposed'}');
    print('  Answer: ${_truncate(result.text)}');
    _printUsage(result);
  } catch (error) {
    print('- OpenRouter online routing: error -> $error');
  }
}

Future<void> demonstrateFallbackComposition() async {
  print('\n=== Shared Fallback Composition ===');

  final models = <core.LanguageModel>[
    if (_readApiKey('GROQ_API_KEY') case final apiKey?)
      groq.groq(apiKey: apiKey).chatModel('llama-3.3-70b-versatile'),
    if (_readApiKey('DEEPSEEK_API_KEY') case final apiKey?)
      deepseek.deepSeek(apiKey: apiKey).chatModel('deepseek-chat'),
    if (_readApiKey('OPENROUTER_API_KEY') case final apiKey?)
      openrouter.openRouter(apiKey: apiKey).chatModel('openai/gpt-4o-mini'),
  ];

  if (models.isEmpty) {
    print(
        'No fallback models available. Set GROQ_API_KEY, DEEPSEEK_API_KEY, or OPENROUTER_API_KEY.\n');
    return;
  }

  for (var index = 0; index < models.length; index += 1) {
    final model = models[index];

    try {
      final result = await _generateText(
        model: model,
        prompt: [
          core.UserPromptMessage.text(
            'Give one sentence on why fallback chains should stay app-owned.',
          ),
        ],
        options: const core.GenerateTextOptions(
          temperature: 0.3,
          maxOutputTokens: 90,
        ),
      );

      print(
          'Fallback step ${index + 1} succeeded via ${model.providerId}/${model.modelId}');
      print('  ${_truncate(result.text)}\n');
      return;
    } catch (error) {
      print(
          'Fallback step ${index + 1} failed via ${model.providerId}: $error');
    }
  }

  print('All fallback models failed.\n');
}

Future<void> demonstrateGenericCompatibleEndpoint() async {
  print('=== Explicit Custom Compatible Endpoint ===');

  final apiKey = _readApiKey('TOGETHER_API_KEY');
  if (apiKey == null) {
    print(
        '- Together AI custom profile: skipped (TOGETHER_API_KEY is not set)');
    print('');
    return;
  }

  try {
    final model = openai
        .openai(
          apiKey: apiKey,
          profile: _togetherProfile,
        )
        .chatModel(_togetherModelId);

    final result = await _generateText(
      model: model,
      prompt: [
        core.SystemPromptMessage.text(
          'Answer like an architecture reviewer.',
        ),
        core.UserPromptMessage.text(
          'Why should a library keep custom OpenAI-compatible endpoints explicit instead of auto-normalizing them into one mega abstraction?',
        ),
      ],
    );

    print('- Together AI via a local OpenAI-family profile');
    print('  Model: ${model.providerId}/${model.modelId}');
    print('  Base URL: $_togetherBaseUrl');
    print(
      '  Note: this path stays explicit because the endpoint shares the OpenAI-family chat contract but not a dedicated first-class facade.',
    );
    print('  Answer: ${_truncate(result.text)}');
    _printUsage(result);
    print('');
  } catch (error) {
    print('- Together AI custom profile: error -> $error\n');
  }
}

Future<core.GenerateTextCallResult<Object?>> _generateText({
  required core.LanguageModel model,
  required List<core.PromptMessage> prompt,
  core.GenerateTextOptions options = const core.GenerateTextOptions(
    temperature: 0.5,
    maxOutputTokens: 180,
  ),
  core.CallOptions callOptions = const core.CallOptions(),
}) {
  return core.generateTextCall(
    model: model,
    prompt: prompt,
    options: options,
    callOptions: callOptions,
  );
}

String? _readApiKey(String envVar) {
  final value = Platform.environment[envVar];
  if (value == null || value.isEmpty) {
    return null;
  }

  return value;
}

void _printUsage(core.GenerateTextCallResult<Object?> result) {
  if (result.usage case final usage?) {
    print(
      '  Usage: input=${usage.inputTokens ?? 'n/a'}, output=${usage.outputTokens ?? 'n/a'}, total=${usage.totalTokens ?? 'n/a'}',
    );
  }
}

void _printSources(core.GenerateTextCallResult<Object?> result) {
  final sources = result.content
      .whereType<core.SourceContentPart>()
      .map((part) => part.source)
      .toList(growable: false);

  if (sources.isEmpty) {
    return;
  }

  print('  Sources:');
  for (final source in sources.take(3)) {
    print('    - ${source.title ?? source.uri?.toString() ?? source.sourceId}');
  }
}

String _truncate(String text, {int maxLength = 220}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }

  return '${normalized.substring(0, maxLength)}...';
}
