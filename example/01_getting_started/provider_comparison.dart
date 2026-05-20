// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

const _demoCallOptions = core.CallOptions(
  timeout: Duration(seconds: 20),
);

/// Compare providers that already have stable root provider factories.
///
/// This example intentionally focuses on the migrated model path instead of the
/// legacy root builder surface.
Future<void> main() async {
  print('Stable Model Comparison Across Providers\n');

  const question =
      'Explain artificial intelligence in 3 key points, each point no more than 20 words.';
  final modelsByProvider = createModelsByProvider();

  if (modelsByProvider.isEmpty) {
    print('Set at least one provider API key to run this example:');
    print('  OPENAI_API_KEY');
    print('  ANTHROPIC_API_KEY');
    print('  GROQ_API_KEY');
    print('  DEEPSEEK_API_KEY');
    print('  XAI_API_KEY');
    return;
  }

  print('Question: $question\n');
  print(
    'Testing ${modelsByProvider.length} provider-owned models on the stable API...\n',
  );

  final results = await Future.wait(
    modelsByProvider.entries.map(
      (entry) => testProviderModel(entry.key, entry.value, question),
    ),
  );

  final byName = {
    for (final result in results) result.name: result,
  };

  displayComparison(byName);
  provideRecommendations(byName);
  await runRegistrySelectionExample();
}

Map<String, core.LanguageModel> createModelsByProvider() {
  final modelsByProvider = <String, core.LanguageModel>{};

  final openAIKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIKey != null && openAIKey.isNotEmpty) {
    modelsByProvider['OpenAI'] =
        openai.openai(apiKey: openAIKey).chatModel('gpt-4.1-mini');
  }

  final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (anthropicKey != null && anthropicKey.isNotEmpty) {
    modelsByProvider['Anthropic'] = anthropic
        .anthropic(
          apiKey: anthropicKey,
        )
        .chatModel('claude-sonnet-4-5');
  }

  final groqKey = Platform.environment['GROQ_API_KEY'];
  if (groqKey != null && groqKey.isNotEmpty) {
    modelsByProvider['Groq'] = openai
        .groq(
          apiKey: groqKey,
        )
        .chatModel('llama-3.3-70b-versatile');
  }

  final deepSeekKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (deepSeekKey != null && deepSeekKey.isNotEmpty) {
    modelsByProvider['DeepSeek'] = openai
        .deepSeek(
          apiKey: deepSeekKey,
        )
        .chatModel('deepseek-chat');
  }

  final xaiKey = Platform.environment['XAI_API_KEY'];
  if (xaiKey != null && xaiKey.isNotEmpty) {
    modelsByProvider['xAI'] = openai.xai(apiKey: xaiKey).chatModel('grok-3');
  }

  return modelsByProvider;
}

Future<ProviderResult> testProviderModel(
  String name,
  core.LanguageModel model,
  String question,
) async {
  final stopwatch = Stopwatch()..start();

  try {
    final result = await core.generateTextCall(
      model: model,
      messages: [
        core.UserModelMessage.text(question),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.7,
        maxOutputTokens: 120,
      ),
      callOptions: _demoCallOptions,
    );

    stopwatch.stop();

    return ProviderResult(
      name: name,
      success: true,
      response: result.text,
      responseTime: stopwatch.elapsedMilliseconds,
      usage: result.usage,
      reasoningText: result.reasoningText,
      modelId: model.modelId,
    );
  } catch (error) {
    stopwatch.stop();

    return ProviderResult(
      name: name,
      success: false,
      response: 'Error: $error',
      responseTime: stopwatch.elapsedMilliseconds,
      modelId: model.modelId,
    );
  }
}

void displayComparison(Map<String, ProviderResult> results) {
  print('Comparison Results:\n');

  final sortedResults = results.values.toList()
    ..sort((a, b) => a.responseTime.compareTo(b.responseTime));

  for (final result in sortedResults) {
    print('${result.name} (${result.modelId})');

    if (result.success) {
      print('  Status: success');
      print('  Response Time: ${result.responseTime}ms');
      print('  Reply: ${_truncate(result.response)}');

      if (result.usage != null) {
        print(
          '  Usage: input=${result.usage!.inputTokens}, output=${result.usage!.outputTokens}, total=${result.usage!.totalTokens}',
        );
      }

      if (result.reasoningText case final reasoning?) {
        print('  Reasoning: ${_truncate(reasoning, maxLength: 120)}');
      }
    } else {
      print('  Status: failed');
      print('  Error: ${result.response}');
    }

    print('');
  }
}

void provideRecommendations(Map<String, ProviderResult> results) {
  print('Recommendations:\n');

  final successful = results.values.where((result) => result.success).toList();
  if (successful.isEmpty) {
    print('No provider completed successfully.');
    return;
  }

  final fastest = successful.reduce(
    (current, next) =>
        current.responseTime < next.responseTime ? current : next,
  );
  print('Fastest response: ${fastest.name} (${fastest.responseTime}ms)');

  print('\nFit by scenario:');
  for (final result in successful) {
    switch (result.name) {
      case 'OpenAI':
        print(
            '  - OpenAI: balanced default choice and broad ecosystem support');
      case 'Anthropic':
        print(
            '  - Anthropic: strong long-form reasoning and safety-oriented flows');
      case 'Groq':
        print('  - Groq: latency-sensitive workloads');
      case 'DeepSeek':
        print('  - DeepSeek: value-oriented general chat and reasoning');
      case 'xAI':
        print('  - xAI: current-awareness and live-search-oriented use cases');
    }
  }

  print('\nNext steps:');
  print('  - run basic_configuration.dart to understand shared options');
  print(
      '  - run ../02_core_features/web_search.dart for provider-owned search');
  print('  - inspect ../04_providers/ for provider-specific features');
}

Future<void> runRegistrySelectionExample() async {
  final registry = llm.ProviderRegistry(
    providers: createRegistryProviders(),
  );

  final defaultProviderId = registry.hasLanguageProvider('openai')
      ? 'openai'
      : registry.languageProviderIds.isEmpty
          ? null
          : registry.languageProviderIds.first;
  final selectedProviderId =
      (Platform.environment['MODEL_PROVIDER'] ?? defaultProviderId ?? '')
          .trim();
  final modelId = _modelIdForProvider(selectedProviderId);
  if (!registry.hasLanguageProvider(selectedProviderId)) {
    print(
      'Dynamic model selection example skipped because '
      'MODEL_PROVIDER="$selectedProviderId" is not available.\n',
    );
    return;
  }

  final question = Platform.environment['MODEL_QUESTION'] ??
      'Give one short sentence about why runtime model selection is useful.';
  final model = registry.languageModel('$selectedProviderId:$modelId');
  try {
    final result = await core.generateTextCall(
      model: model,
      messages: [
        core.UserModelMessage.text(question),
      ],
      callOptions: _demoCallOptions,
    );

    print('Dynamic registry selection');
    print('  Selected: $selectedProviderId:$modelId');
    print('  Reply: ${_truncate(result.text)}\n');
  } catch (error) {
    print('Dynamic registry selection failed for $selectedProviderId:$modelId');
    print('  Error: $error\n');
  }
}

Map<String, llm.Provider> createRegistryProviders() {
  final providers = <String, llm.Provider>{};

  final openAIKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIKey != null && openAIKey.isNotEmpty) {
    providers['openai'] = openai.openai(apiKey: openAIKey);
  }

  final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (anthropicKey != null && anthropicKey.isNotEmpty) {
    providers['anthropic'] = anthropic.anthropic(apiKey: anthropicKey);
  }

  final groqKey = Platform.environment['GROQ_API_KEY'];
  if (groqKey != null && groqKey.isNotEmpty) {
    providers['groq'] = openai.groq(apiKey: groqKey);
  }

  final deepSeekKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (deepSeekKey != null && deepSeekKey.isNotEmpty) {
    providers['deepseek'] = openai.deepSeek(apiKey: deepSeekKey);
  }

  final xaiKey = Platform.environment['XAI_API_KEY'];
  if (xaiKey != null && xaiKey.isNotEmpty) {
    providers['xai'] = openai.xai(apiKey: xaiKey);
  }

  return providers;
}

String _modelIdForProvider(String providerId) {
  return switch (providerId) {
    'openai' => 'gpt-4.1-mini',
    'anthropic' => 'claude-sonnet-4-5',
    'groq' => 'llama-3.3-70b-versatile',
    'deepseek' => 'deepseek-chat',
    'xai' => 'grok-3',
    _ => 'gpt-4.1-mini',
  };
}

final class ProviderResult {
  final String name;
  final bool success;
  final String response;
  final int responseTime;
  final core.UsageStats? usage;
  final String? reasoningText;
  final String modelId;

  const ProviderResult({
    required this.name,
    required this.success,
    required this.response,
    required this.responseTime,
    required this.modelId,
    this.usage,
    this.reasoningText,
  });
}

String _truncate(String text, {int maxLength = 180}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }

  return '${normalized.substring(0, maxLength)}...';
}
