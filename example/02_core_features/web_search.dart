import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_google/provider_tools.dart';
import 'package:llm_dart_google/web_search_tool_options.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/provider_tools.dart';
import 'package:llm_dart_openai/web_search_context_size.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';

/// Provider-native Web Search Example (Vercel-style)
///
/// This example demonstrates web search as a **provider-native tool**
/// (server-side / built-in) configured via `ProviderTool`.
///
/// Design goals:
/// - Keep the standard surface small (`llm_dart_ai` task APIs).
/// - Treat web search as provider-specific: semantics differ across providers.
/// - Avoid a “unified web search API” that pretends every provider behaves the same.
///
/// If you want full control (e.g. custom search engine / scraping), implement
/// web search as a local `FunctionTool` in your app code and run it via
/// `runToolLoop*` instead.
void main() async {
  print('🔍 Provider-native Web Search Demo\n');

  registerAnthropic();
  registerOpenAI();
  registerGoogle();
  registerXAI();
  registerOpenAICompatibleProvider('openrouter');

  final xaiApiKey = Platform.environment['XAI_API_KEY'];
  final anthropicApiKey = Platform.environment['ANTHROPIC_API_KEY'];
  final openaiApiKey = Platform.environment['OPENAI_API_KEY'];
  final googleApiKey = Platform.environment['GOOGLE_API_KEY'];
  final openrouterApiKey = Platform.environment['OPENROUTER_API_KEY'];

  if (xaiApiKey == null &&
      anthropicApiKey == null &&
      openaiApiKey == null &&
      googleApiKey == null &&
      openrouterApiKey == null) {
    print('❌ Please set at least one API key:');
    print('   - XAI_API_KEY for xAI Grok');
    print('   - ANTHROPIC_API_KEY for Claude');
    print('   - OPENAI_API_KEY for OpenAI');
    print('   - GOOGLE_API_KEY for Google Gemini');
    print('   - OPENROUTER_API_KEY for OpenRouter');
    return;
  }

  await demoAnthropicProviderTool(anthropicApiKey);
  await demoOpenAIProviderTool(openaiApiKey);
  await demoGoogleProviderTool(googleApiKey);
  await demoXaiLiveSearch(xaiApiKey);
  await demoOpenRouterOnlineSuffix(openrouterApiKey);
}

Future<void> demoAnthropicProviderTool(String? apiKey) async {
  if (apiKey == null) return;

  print('🧠 Anthropic (provider tool: web_search_*)');
  print('=' * 50);

  final model = await LLMBuilder()
      .provider(anthropicProviderId)
      .apiKey(apiKey)
      .model('claude-sonnet-4-20250514')
      .providerTool(
        AnthropicProviderTools.webSearch(
          options: const AnthropicWebSearchToolOptions(
            maxUses: 2,
            allowedDomains: ['wikipedia.org', 'github.com', 'arxiv.org'],
            userLocation: AnthropicUserLocation(
              city: 'San Francisco',
              region: 'California',
              country: 'US',
              timezone: 'America/Los_Angeles',
            ),
          ),
        ),
      )
      .build();

  final prompt = Prompt(messages: [
    PromptMessage.user(
      'Summarize the latest Gemini releases and cite key sources.',
    ),
  ]);

  final result = await generateText(model: model, promptIr: prompt);

  print(result.text);
  print('\nproviderMetadata keys: ${result.providerMetadata?.keys.toList()}');
  print('');
}

Future<void> demoOpenAIProviderTool(String? apiKey) async {
  if (apiKey == null) return;

  print('🔍 OpenAI (Responses API built-in tool: web_search_preview)');
  print('=' * 50);

  final base = LLMBuilder()
      .provider(openaiProviderId)
      .apiKey(apiKey)
      .model('gpt-5-mini')
      .providerTool(
        OpenAIProviderTools.webSearch(
          contextSize: OpenAIWebSearchContextSize.medium,
        ),
      );

  final model =
      await base.providerOption('openai', 'useResponsesAPI', true).build();

  final prompt = Prompt(messages: [
    PromptMessage.user(
      'What happened in AI research this week? Include citations if available.',
    ),
  ]);

  final result = await generateText(model: model, promptIr: prompt);

  print(result.text);
  print('\nproviderMetadata keys: ${result.providerMetadata?.keys.toList()}');
  print('');
}

Future<void> demoGoogleProviderTool(String? apiKey) async {
  if (apiKey == null) return;

  print('🌐 Google Gemini (grounding tool: google_search)');
  print('=' * 50);

  final model = await LLMBuilder()
      .provider(googleProviderId)
      .apiKey(apiKey)
      .model('gemini-2.0-flash')
      .providerTool(
        GoogleProviderTools.webSearch(
          options: const GoogleWebSearchToolOptions(
            mode: GoogleDynamicRetrievalMode.dynamic,
            dynamicThreshold: 0.7,
          ),
        ),
      )
      .build();

  final prompt = Prompt(messages: [
    PromptMessage.user(
        'Find recent announcements about Dart and summarize them.'),
  ]);

  final result = await generateText(model: model, promptIr: prompt);

  print(result.text);
  print('\nproviderMetadata keys: ${result.providerMetadata?.keys.toList()}');
  print('');
}

Future<void> demoXaiLiveSearch(String? apiKey) async {
  if (apiKey == null) return;

  print('🤖 xAI Grok (parameter-based live search)');
  print('=' * 50);

  final model = await LLMBuilder()
      .provider(xaiProviderId)
      .apiKey(apiKey)
      .model('grok-3')
      .providerOptions('xai', {
    'liveSearch': true,
    'searchParameters': SearchParameters.newsSearch(
      maxResults: 5,
      fromDate: '2025-01-01',
    ).toJson(),
  }).build();

  final prompt = Prompt(messages: [
    PromptMessage.user('What are the top AI news stories today?'),
  ]);

  final result = await generateText(model: model, promptIr: prompt);

  print(result.text);
  print('\nproviderMetadata keys: ${result.providerMetadata?.keys.toList()}');
  print('');
}

Future<void> demoOpenRouterOnlineSuffix(String? apiKey) async {
  if (apiKey == null) return;

  print('🌐 OpenRouter (model suffix :online)');
  print('=' * 50);

  final model = await LLMBuilder()
      .provider('openrouter')
      .apiKey(apiKey)
      .model('anthropic/claude-3.5-sonnet:online')
      .providerOption('openrouter', 'webSearch', const {
        'enabled': true,
        'max_results': 5,
        'strategy': 'plugin',
        'search_type': 'web',
      })
      .providerOption('openrouter', 'webSearchEnabled', true)
      .build();

  final prompt = Prompt(messages: [
    PromptMessage.user('Search for recent papers about tool calling.'),
  ]);

  final result = await generateText(model: model, promptIr: prompt);

  print(result.text);
  print('\nproviderMetadata keys: ${result.providerMetadata?.keys.toList()}');
  print('');
}
