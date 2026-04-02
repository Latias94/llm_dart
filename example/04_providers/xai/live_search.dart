// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/ai.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

/// xAI live search examples using the stable `AI.xai(...).chatModel(...)` API.
///
/// The shared app-facing layer remains `generateTextCall(...)`, while xAI's
/// search behavior is configured through `XAIGenerateTextOptions`.
Future<void> main() async {
  print('xAI Grok Live Search Examples\n');

  final apiKey = Platform.environment['XAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set XAI_API_KEY to run this example.');
    return;
  }

  final model = llm.AI.xai(apiKey: apiKey).chatModel('grok-3');

  await runCurrentEventsSearch(model);
  await runNewsFocusedSearch(model);
  await runConversationWithFreshData(model);

  print('xAI live search example completed.');
}

Future<void> runCurrentEventsSearch(core.LanguageModel model) async {
  await runSearchCase(
    label: 'Current events search',
    model: model,
    prompt: 'What are the latest developments in AI this week?',
    search: const openai.XAILiveSearchOptions.autoWeb(
      maxSearchResults: 5,
    ),
  );
}

Future<void> runNewsFocusedSearch(core.LanguageModel model) async {
  await runSearchCase(
    label: 'News-focused search',
    model: model,
    prompt:
        'Summarize the top technology news stories from the last few days and explain why they matter.',
    search: openai.XAILiveSearchOptions(
      maxSearchResults: 6,
      sources: const [
        openai.XAINewsSearchSource(countryCode: 'US'),
        openai.XAIWebSearchSource(
          allowedWebsites: [
            'techcrunch.com',
            'theverge.com',
            'openai.com',
            'anthropic.com',
          ],
        ),
      ],
    ),
  );
}

Future<void> runConversationWithFreshData(core.LanguageModel model) async {
  print('=== Conversation with Fresh Data ===');

  final history = <core.PromptMessage>[
    core.SystemPromptMessage.text(
      'You are a concise market research assistant.',
    ),
    core.UserPromptMessage.text(
      'I am researching renewable energy companies. What should I watch first?',
    ),
  ];

  final firstTurn = await core.generateTextCall(
    model: model,
    prompt: history,
    options: const core.GenerateTextOptions(
      temperature: 0.5,
      maxOutputTokens: 160,
    ),
    callOptions: const core.CallOptions(
      providerOptions: openai.XAIGenerateTextOptions(
        search: openai.XAILiveSearchOptions.autoWeb(
          maxSearchResults: 4,
        ),
      ),
    ),
  );

  print('Assistant 1: ${_truncate(firstTurn.text)}');
  _printSources(firstTurn);

  history.add(core.AssistantPromptMessage.text(firstTurn.text));
  history.add(
    core.UserPromptMessage.text(
      'Now compare the latest solar-related developments with what happened last year.',
    ),
  );

  final secondTurn = await core.generateTextCall(
    model: model,
    prompt: history,
    options: const core.GenerateTextOptions(
      temperature: 0.5,
      maxOutputTokens: 180,
    ),
    callOptions: core.CallOptions(
      providerOptions: openai.XAIGenerateTextOptions(
        search: openai.XAILiveSearchOptions(
          maxSearchResults: 5,
          sources: const [
            openai.XAINewsSearchSource(countryCode: 'US'),
            openai.XAIWebSearchSource(),
          ],
        ),
      ),
    ),
  );

  print('Assistant 2: ${_truncate(secondTurn.text)}');
  _printSources(secondTurn);
  print('');
}

Future<void> runSearchCase({
  required String label,
  required core.LanguageModel model,
  required String prompt,
  required openai.XAILiveSearchOptions search,
}) async {
  print('=== $label ===');

  try {
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.SystemPromptMessage.text(
          'Use fresh search results when helpful and cite the strongest sources.',
        ),
        core.UserPromptMessage.text(prompt),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.4,
        maxOutputTokens: 180,
      ),
      callOptions: core.CallOptions(
        providerOptions: openai.XAIGenerateTextOptions(search: search),
      ),
    );

    print(_truncate(result.text));
    _printSources(result);
    print('');
  } catch (error) {
    print('Error: $error\n');
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

  print('Sources:');
  for (final source in sources.take(4)) {
    print(
      '  - ${source.title ?? source.uri?.toString() ?? source.sourceId}',
    );
  }
}

String _truncate(String text, {int maxLength = 240}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }

  return '${normalized.substring(0, maxLength)}...';
}
