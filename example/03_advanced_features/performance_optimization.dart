import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Stable performance optimization patterns for shared language models.
///
/// This example demonstrates:
/// - response caching in app-owned state
/// - parallel request orchestration on shared text calls
/// - streaming-first UX measurements
/// - context trimming and memory-aware conversation handling
Future<void> main() async {
  print('Stable performance optimization examples\n');

  final balancedModel = _resolveBalancedModel();
  final streamingModel = _resolveStreamingModel(balancedModel);

  if (balancedModel == null && streamingModel == null) {
    print('No text model is configured.');
    print('Set OPENAI_API_KEY or GROQ_API_KEY.');
    return;
  }

  if (balancedModel != null) {
    print('Balanced model: ${balancedModel.label}');
    print(
      'Model id: ${balancedModel.model.providerId}/${balancedModel.model.modelId}\n',
    );

    await _demonstrateCachingStrategies(balancedModel);
    await _demonstrateParallelProcessing(balancedModel);
    await _demonstrateBatchProcessing(balancedModel);
    await _demonstrateMemoryOptimization(balancedModel);
  }

  if (streamingModel != null) {
    print('Streaming model: ${streamingModel.label}');
    print(
      'Model id: ${streamingModel.model.providerId}/${streamingModel.model.modelId}\n',
    );

    await _demonstrateStreamingOptimization(streamingModel);
  }

  print('Completed stable performance optimization examples.');
  print(
      'Keep caches, batching, and memory policies in your app/runtime layer.');
}

_TextModelEntry? _resolveBalancedModel() {
  final openAIKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIKey != null && openAIKey.isNotEmpty) {
    return _TextModelEntry(
      label: 'OpenAI gpt-4o-mini',
      model: openai
          .openai(
            apiKey: openAIKey,
          )
          .chatModel('gpt-4o-mini'),
      defaultOptions: const core.GenerateTextOptions(
        temperature: 0.3,
        maxOutputTokens: 180,
      ),
    );
  }

  final groqKey = Platform.environment['GROQ_API_KEY'];
  if (groqKey != null && groqKey.isNotEmpty) {
    return _TextModelEntry(
      label: 'Groq llama-3.1-8b-instant',
      model: openai
          .groq(
            apiKey: groqKey,
          )
          .chatModel('llama-3.1-8b-instant'),
      defaultOptions: const core.GenerateTextOptions(
        temperature: 0.3,
        maxOutputTokens: 180,
      ),
    );
  }

  return null;
}

_TextModelEntry? _resolveStreamingModel(_TextModelEntry? fallback) {
  final groqKey = Platform.environment['GROQ_API_KEY'];
  if (groqKey != null && groqKey.isNotEmpty) {
    return _TextModelEntry(
      label: 'Groq llama-3.1-8b-instant',
      model: openai
          .groq(
            apiKey: groqKey,
          )
          .chatModel('llama-3.1-8b-instant'),
      defaultOptions: const core.GenerateTextOptions(
        temperature: 0.7,
        maxOutputTokens: 260,
      ),
    );
  }

  return fallback;
}

Future<void> _demonstrateCachingStrategies(_TextModelEntry entry) async {
  print('Caching strategies:');

  final cache = <String, _TextAnswer>{};
  final questions = [
    'What is the capital of France?',
    'What is 2 + 2?',
    'What is the capital of France?',
    'Explain photosynthesis briefly.',
    'What is 2 + 2?',
  ];

  try {
    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];

      final answer = cache[question] ??
          await _ask(
            entry,
            question,
          );
      final fromCache = cache.containsKey(question);
      cache.putIfAbsent(question, () => answer);

      print('  ${index + 1}. "$question"');
      print(
        '    Source: ${fromCache ? 'cache' : 'model'} '
        '(${answer.duration.inMilliseconds}ms)',
      );
      print('    Preview: ${_preview(answer.text, 60)}');
    }

    print('\n  Cache size: ${cache.length}');
    print(
        '  Cached responses avoid repeated model calls and rate-limit usage.');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> _demonstrateParallelProcessing(_TextModelEntry entry) async {
  print('Parallel processing:');

  final questions = [
    'What is machine learning?',
    'Explain blockchain technology.',
    'What is quantum computing?',
    'Define artificial intelligence.',
    'What is cloud computing?',
  ];

  try {
    final sequentialStopwatch = Stopwatch()..start();
    for (final question in questions) {
      await _ask(entry, question);
    }
    sequentialStopwatch.stop();

    final parallelStopwatch = Stopwatch()..start();
    await Future.wait(
      questions.map((question) => _ask(entry, question)),
    );
    parallelStopwatch.stop();

    final speedup = sequentialStopwatch.elapsedMilliseconds /
        parallelStopwatch.elapsedMilliseconds;

    print('  Sequential: ${sequentialStopwatch.elapsedMilliseconds}ms');
    print('  Parallel: ${parallelStopwatch.elapsedMilliseconds}ms');
    print('  Speedup: ${speedup.toStringAsFixed(1)}x');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> _demonstrateStreamingOptimization(_TextModelEntry entry) async {
  print('Streaming optimization:');

  const prompt = 'Write a short story about a robot learning to paint.';

  try {
    final regular = await _ask(
      entry,
      prompt,
      options: core.GenerateTextOptions(
        temperature: entry.defaultOptions.temperature,
        maxOutputTokens: 260,
      ),
    );

    final streamStopwatch = Stopwatch()..start();
    var firstChunkAt = -1;
    var chunkCount = 0;
    final buffer = StringBuffer();

    final stream = core.streamTextCall(
      model: entry.model,
      prompt: [
        core.UserPromptMessage.text(prompt),
      ],
      options: core.GenerateTextOptions(
        temperature: entry.defaultOptions.temperature,
        maxOutputTokens: 260,
      ),
    );

    await for (final event in stream) {
      switch (event) {
        case core.TextDeltaEvent(:final delta):
          chunkCount++;
          buffer.write(delta);
          if (firstChunkAt < 0) {
            firstChunkAt = streamStopwatch.elapsedMilliseconds;
          }
        case core.FinishEvent():
          streamStopwatch.stop();
        default:
          break;
      }
    }

    final firstChunkDelay =
        firstChunkAt < 0 ? streamStopwatch.elapsedMilliseconds : firstChunkAt;
    final perceivedSpeedup = regular.duration.inMilliseconds / firstChunkDelay;

    print('  Regular response time: ${regular.duration.inMilliseconds}ms');
    print('  Streaming first chunk: ${firstChunkDelay}ms');
    print('  Streaming total time: ${streamStopwatch.elapsedMilliseconds}ms');
    print('  Chunks received: $chunkCount');
    print('  Perceived speedup: ${perceivedSpeedup.toStringAsFixed(1)}x');
    print('  Preview: ${_preview(buffer.toString(), 80)}');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> _demonstrateBatchProcessing(_TextModelEntry entry) async {
  print('Batch processing:');

  final prompts = List.generate(
    12,
    (index) =>
        'Summarize technology trend #${index + 1} in one sentence for executives.',
  );

  const batchSize = 4;
  final results = <_TextAnswer>[];
  final totalStopwatch = Stopwatch()..start();

  try {
    for (var offset = 0; offset < prompts.length; offset += batchSize) {
      final batch = prompts.skip(offset).take(batchSize).toList();
      final batchStopwatch = Stopwatch()..start();

      final batchResults = await Future.wait(
        batch.map((prompt) => _ask(entry, prompt)),
      );
      batchStopwatch.stop();

      results.addAll(batchResults);
      print(
        '  Batch ${(offset ~/ batchSize) + 1}'
        ' completed in ${batchStopwatch.elapsedMilliseconds}ms',
      );

      await Future.delayed(const Duration(milliseconds: 100));
    }

    totalStopwatch.stop();
    final observedTokens = results
        .map((result) => result.usage?.totalTokens)
        .whereType<int>()
        .fold<int>(0, (sum, value) => sum + value);

    print('  Total items processed: ${results.length}');
    print('  Total time: ${totalStopwatch.elapsedMilliseconds}ms');
    print(
      '  Average per item: '
      '${(totalStopwatch.elapsedMilliseconds / results.length).toStringAsFixed(1)}ms',
    );
    print(
      '  Observed tokens: ${observedTokens == 0 ? 'unknown' : observedTokens}',
    );
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> _demonstrateMemoryOptimization(_TextModelEntry entry) async {
  print('Memory optimization:');

  final conversation = <core.PromptMessage>[];
  const maxMessages = 10;

  try {
    for (var turn = 1; turn <= 15; turn++) {
      final userMessage = core.UserPromptMessage.text(
        'Message $turn: tell me about topic $turn.',
      );
      final answer = await _askWithHistory(
        entry,
        userMessage,
        conversation,
      );

      conversation
        ..add(userMessage)
        ..add(core.AssistantPromptMessage.text(answer.text));

      if (conversation.length > maxMessages) {
        final overflow = conversation.length - maxMessages;
        conversation.removeRange(0, overflow);
        print('  Trimmed $overflow old message(s) on turn $turn');
      }

      print('  Turn $turn: ${conversation.length} messages in context');
    }

    var totalChars = 0;
    final stream = core.streamTextCall(
      model: entry.model,
      prompt: [
        core.UserPromptMessage.text(
          'Write a detailed explanation of quantum computing.',
        ),
      ],
      options: core.GenerateTextOptions(
        temperature: entry.defaultOptions.temperature,
        maxOutputTokens: 400,
      ),
    );

    await for (final event in stream) {
      switch (event) {
        case core.TextDeltaEvent(:final delta):
          totalChars += delta.length;
        default:
          break;
      }
    }

    print(
        '  Streamed characters without building large prompt state: $totalChars');
    print('  Context trimming keeps runtime memory bounded in long sessions.');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<_TextAnswer> _ask(
  _TextModelEntry entry,
  String prompt, {
  core.GenerateTextOptions? options,
}) async {
  final stopwatch = Stopwatch()..start();
  final result = await core.generateTextCall(
    model: entry.model,
    prompt: [
      core.UserPromptMessage.text(prompt),
    ],
    options: _mergeOptions(entry.defaultOptions, options),
  );
  stopwatch.stop();

  return _TextAnswer(
    text: result.text,
    duration: stopwatch.elapsed,
    usage: result.usage,
  );
}

Future<_TextAnswer> _askWithHistory(
  _TextModelEntry entry,
  core.UserPromptMessage userMessage,
  List<core.PromptMessage> history,
) async {
  final stopwatch = Stopwatch()..start();
  final result = await core.generateTextCall(
    model: entry.model,
    prompt: [
      ...history,
      userMessage,
    ],
    options: entry.defaultOptions,
  );
  stopwatch.stop();

  return _TextAnswer(
    text: result.text,
    duration: stopwatch.elapsed,
    usage: result.usage,
  );
}

core.GenerateTextOptions _mergeOptions(
  core.GenerateTextOptions base,
  core.GenerateTextOptions? override,
) {
  if (override == null) {
    return base;
  }

  return core.GenerateTextOptions(
    maxOutputTokens: override.maxOutputTokens ?? base.maxOutputTokens,
    temperature: override.temperature ?? base.temperature,
    stopSequences: override.stopSequences ?? base.stopSequences,
    topP: override.topP ?? base.topP,
    topK: override.topK ?? base.topK,
    responseFormat: override.responseFormat ?? base.responseFormat,
  );
}

String _preview(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }

  return '${value.substring(0, maxLength)}...';
}

final class _TextModelEntry {
  final String label;
  final core.LanguageModel model;
  final core.GenerateTextOptions defaultOptions;

  const _TextModelEntry({
    required this.label,
    required this.model,
    required this.defaultOptions,
  });
}

final class _TextAnswer {
  final String text;
  final Duration duration;
  final core.UsageStats? usage;

  const _TextAnswer({
    required this.text,
    required this.duration,
    required this.usage,
  });
}
