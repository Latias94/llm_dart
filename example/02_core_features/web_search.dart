// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;
import 'package:llm_dart/openrouter.dart' as openrouter;
import 'package:llm_dart/xai.dart' as xai;

/// Stable web-search examples built on the shared text-call layer.
///
/// This example intentionally does not use the legacy root builder helpers such
/// as `enableWebSearch()`, `webSearch()`, or `newsSearch()`.
///
/// Search is not a single shared boolean in the new architecture:
/// - OpenAI uses provider-owned built-in tools.
/// - Anthropic uses provider-owned native tools.
/// - xAI uses provider-owned live-search invocation options.
/// - OpenRouter uses provider-owned model settings for `:online` shaping.
///
/// The shared app-facing flow stays the same:
/// 1. Create a stable `AI.*(...).chatModel(...)`.
/// 2. Call `generateTextCall(...)`.
/// 3. Pass provider-specific search behavior through typed settings/options.
Future<void> main() async {
  print('Stable Web Search Patterns\n');

  final openaiApiKey = Platform.environment['OPENAI_API_KEY'];
  final anthropicApiKey = Platform.environment['ANTHROPIC_API_KEY'];
  final xaiApiKey = Platform.environment['XAI_API_KEY'];
  final openRouterApiKey = Platform.environment['OPENROUTER_API_KEY'];

  if (openaiApiKey == null &&
      anthropicApiKey == null &&
      xaiApiKey == null &&
      openRouterApiKey == null) {
    print('Set at least one API key to run this example:');
    print('  OPENAI_API_KEY');
    print('  ANTHROPIC_API_KEY');
    print('  XAI_API_KEY');
    print('  OPENROUTER_API_KEY');
    return;
  }

  await runOpenAISearch(openaiApiKey);
  await runAnthropicSearch(anthropicApiKey);
  await runXAISearch(xaiApiKey);
  await runOpenRouterSearch(openRouterApiKey);

  print(
      'Search remains provider-owned, but the app-facing call layer is shared.');
}

Future<void> runOpenAISearch(String? apiKey) async {
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping OpenAI because OPENAI_API_KEY is not set.\n');
    return;
  }

  final model = llm.AI.openai(apiKey: apiKey).chatModel('gpt-5-mini');

  await runSearchCase(
    label: 'OpenAI Responses web search',
    model: model,
    prompt:
        'Search for recent Dart SDK release notes and summarize the highlights.',
    callOptions: const core.CallOptions(
      providerOptions: openai.OpenAIGenerateTextOptions(
        builtInTools: [openai.OpenAIWebSearchTool()],
      ),
    ),
  );
}

Future<void> runAnthropicSearch(String? apiKey) async {
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping Anthropic because ANTHROPIC_API_KEY is not set.\n');
    return;
  }

  final model = llm.AI.anthropic(apiKey: apiKey).chatModel('claude-sonnet-4-5');

  await runSearchCase(
    label: 'Anthropic native web search',
    model: model,
    prompt:
        'Find recent Flutter desktop updates and summarize the most relevant changes for app developers.',
    callOptions: core.CallOptions(
      providerOptions: anthropic.AnthropicGenerateTextOptions(
        tools: [
          anthropic.AnthropicTools.webSearch20250305(
            maxUses: 3,
            allowedDomains: const [
              'dart.dev',
              'docs.flutter.dev',
              'github.com',
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> runXAISearch(String? apiKey) async {
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping xAI because XAI_API_KEY is not set.\n');
    return;
  }

  final model = llm.xai(apiKey: apiKey).chatModel('grok-3');

  await runSearchCase(
    label: 'xAI live search',
    model: model,
    prompt:
        'Find the latest announcements about open-source AI coding tools and summarize the trend.',
    callOptions: const core.CallOptions(
      providerOptions: xai.XAIGenerateTextOptions(
        search: xai.XAILiveSearchOptions(
          maxSearchResults: 5,
          sources: [
            xai.XAIWebSearchSource(),
            xai.XAINewsSearchSource(),
          ],
        ),
      ),
    ),
  );
}

Future<void> runOpenRouterSearch(String? apiKey) async {
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping OpenRouter because OPENROUTER_API_KEY is not set.\n');
    return;
  }

  final model = llm
      .openRouter(
        apiKey: apiKey,
      )
      .chatModel(
        'openai/gpt-4.1-mini',
        settings: const openrouter.OpenRouterChatModelSettings(
          search: openrouter.OpenRouterSearchOptions.onlineModel(),
        ),
      );

  await runSearchCase(
    label: 'OpenRouter online-model search',
    model: model,
    prompt:
        'Search for recent AI infrastructure cost trends and summarize the main themes.',
  );
}

Future<void> runSearchCase({
  required String label,
  required core.LanguageModel model,
  required String prompt,
  core.CallOptions callOptions = const core.CallOptions(),
}) async {
  print('=== $label ===');

  try {
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.SystemPromptMessage.text(
          'You are a concise research assistant. Summarize the answer and keep only high-signal details.',
        ),
        core.UserPromptMessage.text(prompt),
      ],
      callOptions: callOptions,
    );

    print(_truncate(result.text));

    final sources = result.content
        .whereType<core.SourceContentPart>()
        .map((part) => part.source)
        .toList(growable: false);
    if (sources.isNotEmpty) {
      print('Sources:');
      for (final source in sources.take(3)) {
        final label = source.title ?? source.uri?.toString() ?? source.sourceId;
        print('  - $label');
      }
    }

    final usage = result.usage;
    if (usage != null) {
      print(
        'Usage: input=${usage.inputTokens}, output=${usage.outputTokens}, total=${usage.totalTokens}',
      );
    }
  } catch (error) {
    print('Error: $error');
  }

  print('');
}

String _truncate(String text, {int maxLength = 320}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }

  return '${normalized.substring(0, maxLength)}...';
}
