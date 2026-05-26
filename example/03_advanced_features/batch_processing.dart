import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Stable batch processing patterns for shared text-generation models.
///
/// This example demonstrates:
/// - app-owned batch orchestration on top of `core.generateTextCall(...)`
/// - concurrency, rate limiting, and retry policies outside provider shells
/// - progress tracking and rough cost heuristics without the legacy builder API
Future<void> main() async {
  print('Stable batch processing examples\n');

  final entry = _resolveBatchModel();
  if (entry == null) {
    print('No batch-processing model is configured.');
    print('Set GROQ_API_KEY or OPENAI_API_KEY.');
    return;
  }

  print('Selected model: ${entry.label}');
  print('Model id: ${entry.model.providerId}/${entry.model.modelId}\n');

  final processor = BatchProcessor(
    model: entry.model,
    defaultOptions: entry.defaultOptions,
  );

  await demonstrateBasicBatchProcessing(processor);
  await demonstrateConcurrentProcessing(processor);
  await demonstrateRateLimitedProcessing(processor);
  await demonstrateProgressTracking(processor);
  await demonstrateErrorHandlingAndRetry(processor);
  await demonstrateCostOptimization(processor);

  print('Completed stable batch processing examples.');
  print('Keep batching, retry, and budgeting in app-owned code.');
  print('Use provider packages only for provider-native controls that cannot');
  print('be represented by the shared text-call layer.');
}

_BatchModelEntry? _resolveBatchModel() {
  final groqKey = Platform.environment['GROQ_API_KEY'];
  if (groqKey != null && groqKey.isNotEmpty) {
    return _BatchModelEntry(
      label: 'Groq llama-3.1-8b-instant',
      model: openai
          .groq(
            apiKey: groqKey,
          )
          .chatModel('llama-3.1-8b-instant'),
      defaultOptions: const core.GenerateTextOptions(
        temperature: 0.4,
        maxOutputTokens: 160,
      ),
    );
  }

  final openAIKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIKey != null && openAIKey.isNotEmpty) {
    return _BatchModelEntry(
      label: 'OpenAI gpt-4o-mini',
      model: openai
          .openai(
            apiKey: openAIKey,
          )
          .chatModel('gpt-4o-mini'),
      defaultOptions: const core.GenerateTextOptions(
        temperature: 0.4,
        maxOutputTokens: 160,
      ),
    );
  }

  return null;
}

Future<void> demonstrateBasicBatchProcessing(BatchProcessor processor) async {
  print('Basic batch processing:');

  final tasks = List.generate(
    10,
    (index) => BatchTask(
      id: 'task_$index',
      prompt: 'Summarize the benefits of technology topic #${index + 1}.',
      metadata: {
        'category': 'technology',
        'index': index,
        'complexity': 'medium',
      },
    ),
  );

  print('  Processing ${tasks.length} tasks...');

  try {
    final results = await processor.processBatch(tasks);
    final successful = results.where((result) => result.isSuccess).toList();
    final failed = results.length - successful.length;

    print('  Batch completed:');
    print('    Total tasks: ${tasks.length}');
    print('    Successful: ${successful.length}');
    print('    Failed: $failed');

    for (final result in successful.take(3)) {
      final preview = _preview(result.response ?? '');
      final usage = result.usage?.totalTokens;
      final usageText = usage == null ? 'unknown tokens' : '$usage tokens';
      print('    ${result.task.id}: $preview ($usageText)');
    }
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> demonstrateConcurrentProcessing(BatchProcessor processor) async {
  print('Concurrent processing:');

  final tasks = List.generate(
    20,
    (index) => BatchTask(
      id: 'concurrent_$index',
      prompt: 'Explain concept #${index + 1} in simple terms.',
      metadata: {
        'type': 'explanation',
        'complexity': 'medium',
      },
    ),
  );

  print('  Comparing concurrency levels...');

  try {
    for (final concurrency in const [1, 3, 5]) {
      final config = BatchConfig(
        maxConcurrency: concurrency,
        batchSize: 5,
        retryAttempts: 2,
      );

      final startTime = DateTime.now();
      final results = await processor.processBatchWithConfig(
        tasks.take(10).toList(),
        config,
      );
      final duration = DateTime.now().difference(startTime);
      final successRate =
          results.where((result) => result.isSuccess).length / results.length;

      print('    Concurrency $concurrency:');
      print('      Duration: ${duration.inMilliseconds}ms');
      print('      Success rate: ${(successRate * 100).toStringAsFixed(1)}%');
    }
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> demonstrateRateLimitedProcessing(BatchProcessor processor) async {
  print('Rate-limited processing:');

  final tasks = List.generate(
    15,
    (index) => BatchTask(
      id: 'rate_limited_$index',
      prompt: 'Generate a short story opening about item #${index + 1}.',
      metadata: {
        'type': 'creative',
        'complexity': 'complex',
      },
    ),
  );

  try {
    final config = BatchConfig(
      maxConcurrency: 2,
      rateLimitDelay: const Duration(milliseconds: 500),
      batchSize: 3,
      requestOptions: const core.GenerateTextOptions(
        temperature: 0.8,
        maxOutputTokens: 220,
      ),
    );

    final startTime = DateTime.now();
    final results = await processor.processBatchWithConfig(tasks, config);
    final duration = DateTime.now().difference(startTime);

    print('  Completed with rate limiting:');
    print('    Total time: ${duration.inSeconds}s');
    print(
      '    Average per task: ${duration.inMilliseconds ~/ tasks.length}ms',
    );
    print(
      '    Success rate: ${(results.where((result) => result.isSuccess).length / results.length * 100).toStringAsFixed(1)}%',
    );
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> demonstrateProgressTracking(BatchProcessor processor) async {
  print('Progress tracking:');

  final tasks = List.generate(
    12,
    (index) => BatchTask(
      id: 'progress_$index',
      prompt: 'Analyze data point #${index + 1} in one paragraph.',
      metadata: {
        'analysis_type': 'data',
        'complexity': 'medium',
      },
    ),
  );

  try {
    final config = BatchConfig(
      maxConcurrency: 3,
      batchSize: 4,
      enableProgressTracking: true,
    );

    await processor.processBatchWithProgress(
      tasks,
      config,
      onProgress: (progress) {
        final percentage = (progress.completedTasks / progress.totalTasks * 100)
            .toStringAsFixed(1);
        print(
          '    Progress: $percentage% '
          '(${progress.completedTasks}/${progress.totalTasks}) '
          'ETA ${progress.estimatedTimeRemaining.inSeconds}s',
        );
      },
      onTaskComplete: (result) {
        final status = result.isSuccess ? 'OK' : 'ERR';
        print('      [$status] ${result.task.id}');
      },
    );

    print('  Progress-tracked batch completed.');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> demonstrateErrorHandlingAndRetry(BatchProcessor processor) async {
  print('Error handling and retry logic:');

  final tasks = [
    BatchTask(id: 'normal_1', prompt: 'Normal task 1'),
    BatchTask(
      id: 'failing_1',
      prompt: 'This task will fail on the first retries.',
      metadata: const {
        'simulate_failure': true,
      },
    ),
    BatchTask(id: 'normal_2', prompt: 'Normal task 2'),
    BatchTask(
      id: 'failing_2',
      prompt: 'This task will also fail on the first retries.',
      metadata: const {
        'simulate_failure': true,
      },
    ),
    BatchTask(id: 'normal_3', prompt: 'Normal task 3'),
  ];

  try {
    final config = BatchConfig(
      maxConcurrency: 2,
      retryAttempts: 3,
      retryDelay: const Duration(milliseconds: 200),
      continueOnError: true,
    );

    final results = await processor.processBatchWithConfig(tasks, config);
    for (final result in results) {
      final status = result.isSuccess ? 'OK' : 'ERR';
      print(
        '    [$status] ${result.task.id}: ${result.attemptCount} attempt(s)',
      );

      if (!result.isSuccess && result.error != null) {
        print('      Error: ${result.error}');
      }
    }

    final successCount = results.where((result) => result.isSuccess).length;
    print(
      '  Final success rate: ${(successCount / results.length * 100).toStringAsFixed(1)}%',
    );
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> demonstrateCostOptimization(BatchProcessor processor) async {
  print('Cost optimization:');

  final tasks = [
    BatchTask(
      id: 'simple_1',
      prompt: 'Yes or no?',
      metadata: const {'complexity': 'simple'},
    ),
    BatchTask(
      id: 'simple_2',
      prompt: 'True or false?',
      metadata: const {'complexity': 'simple'},
    ),
    BatchTask(
      id: 'medium_1',
      prompt: 'Explain this concept briefly.',
      metadata: const {'complexity': 'medium'},
    ),
    BatchTask(
      id: 'complex_1',
      prompt: 'Write a detailed analysis with examples and conclusions.',
      metadata: const {'complexity': 'complex'},
    ),
  ];

  try {
    final groupedTasks = processor.groupTasksByComplexity(tasks);
    print('  Task grouping:');
    for (final entry in groupedTasks.entries) {
      print('    ${entry.key}: ${entry.value.length} task(s)');
    }

    final allResults = <BatchResult>[];
    for (final entry in groupedTasks.entries) {
      final complexity = entry.key;
      final groupTasks = entry.value;
      final config = processor.getOptimalConfigForComplexity(complexity);

      print('  Processing $complexity tasks with optimized config...');
      final results =
          await processor.processBatchWithConfig(groupTasks, config);
      allResults.addAll(results);

      final estimatedCost = processor.estimateCost(groupTasks, complexity);
      print('    Estimated cost: \$${estimatedCost.toStringAsFixed(4)}');
    }

    final actualCost = processor.calculateTotalCost(allResults);
    final totalTokens = processor.totalObservedTokens(allResults);

    print('  Completed cost optimization demo.');
    print('    Total tasks processed: ${allResults.length}');
    print('    Observed tokens: ${totalTokens ?? 'unknown'}');
    print('    Approximate cost: \$${actualCost.toStringAsFixed(4)}');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

class BatchTask {
  final String id;
  final String prompt;
  final String? systemPrompt;
  final Map<String, Object?> metadata;
  final core.GenerateTextOptions? options;

  const BatchTask({
    required this.id,
    required this.prompt,
    this.systemPrompt,
    this.metadata = const {},
    this.options,
  });
}

class BatchResult {
  final BatchTask task;
  final String? response;
  final String? error;
  final int attemptCount;
  final Duration processingTime;
  final core.UsageStats? usage;

  const BatchResult({
    required this.task,
    this.response,
    this.error,
    required this.attemptCount,
    required this.processingTime,
    this.usage,
  });

  bool get isSuccess => response != null && error == null;
}

class BatchConfig {
  final int maxConcurrency;
  final int batchSize;
  final int retryAttempts;
  final Duration retryDelay;
  final Duration? rateLimitDelay;
  final bool continueOnError;
  final bool enableProgressTracking;
  final core.GenerateTextOptions requestOptions;

  const BatchConfig({
    this.maxConcurrency = 3,
    this.batchSize = 10,
    this.retryAttempts = 2,
    this.retryDelay = const Duration(seconds: 1),
    this.rateLimitDelay,
    this.continueOnError = true,
    this.enableProgressTracking = false,
    this.requestOptions = const core.GenerateTextOptions(),
  });
}

class BatchProgress {
  final int totalTasks;
  final int completedTasks;
  final int failedTasks;
  final Duration elapsedTime;
  final Duration estimatedTimeRemaining;

  const BatchProgress({
    required this.totalTasks,
    required this.completedTasks,
    required this.failedTasks,
    required this.elapsedTime,
    required this.estimatedTimeRemaining,
  });
}

class BatchProcessor {
  final core.LanguageModel _model;
  final core.GenerateTextOptions _defaultOptions;

  BatchProcessor({
    required core.LanguageModel model,
    required core.GenerateTextOptions defaultOptions,
  })  : _model = model,
        _defaultOptions = defaultOptions;

  Future<List<BatchResult>> processBatch(List<BatchTask> tasks) {
    return processBatchWithConfig(tasks, const BatchConfig());
  }

  Future<List<BatchResult>> processBatchWithConfig(
    List<BatchTask> tasks,
    BatchConfig config,
  ) async {
    final results = <BatchResult>[];
    final semaphore = Semaphore(config.maxConcurrency);

    for (var index = 0; index < tasks.length; index += config.batchSize) {
      final chunk = tasks.skip(index).take(config.batchSize).toList();
      final chunkFutures = chunk.map((task) {
        return semaphore.acquire(() async {
          return _processTaskWithRetry(task, config);
        });
      });

      final chunkResults = await Future.wait(chunkFutures);
      results.addAll(chunkResults);

      if (config.rateLimitDelay != null &&
          index + config.batchSize < tasks.length) {
        await Future.delayed(config.rateLimitDelay!);
      }

      if (!config.continueOnError &&
          chunkResults.any((result) => !result.isSuccess)) {
        break;
      }
    }

    return results;
  }

  Future<List<BatchResult>> processBatchWithProgress(
    List<BatchTask> tasks,
    BatchConfig config, {
    void Function(BatchProgress progress)? onProgress,
    void Function(BatchResult result)? onTaskComplete,
  }) async {
    final results = <BatchResult>[];
    final startTime = DateTime.now();
    final semaphore = Semaphore(config.maxConcurrency);
    var completedCount = 0;
    var failedCount = 0;

    final futures = tasks.map((task) async {
      return semaphore.acquire(() async {
        final result = await _processTaskWithRetry(task, config);

        completedCount++;
        if (!result.isSuccess) {
          failedCount++;
        }

        onTaskComplete?.call(result);

        if (onProgress != null) {
          final elapsed = DateTime.now().difference(startTime);
          final averageMillis = elapsed.inMilliseconds / completedCount;
          final remaining = tasks.length - completedCount;
          final eta = Duration(
            milliseconds: (averageMillis * remaining).round(),
          );

          onProgress(
            BatchProgress(
              totalTasks: tasks.length,
              completedTasks: completedCount,
              failedTasks: failedCount,
              elapsedTime: elapsed,
              estimatedTimeRemaining: eta,
            ),
          );
        }

        return result;
      });
    });

    results.addAll(await Future.wait(futures));
    return results;
  }

  Future<BatchResult> _processTaskWithRetry(
    BatchTask task,
    BatchConfig config,
  ) async {
    final startedAt = DateTime.now();

    for (var attempt = 1; attempt <= config.retryAttempts + 1; attempt++) {
      try {
        if (task.metadata['simulate_failure'] == true && attempt <= 2) {
          throw StateError('Simulated failure for retry testing.');
        }

        final prompt = <core.PromptMessage>[
          if (task.systemPrompt case final systemPrompt?)
            core.SystemPromptMessage.text(systemPrompt),
          core.UserPromptMessage.text(task.prompt),
        ];

        final options = _mergeOptions(
          _mergeOptions(_defaultOptions, config.requestOptions),
          task.options,
        );

        final result = await core.generateTextCall(
          model: _model,
          prompt: prompt,
          options: options,
        );

        return BatchResult(
          task: task,
          response: result.text,
          attemptCount: attempt,
          processingTime: DateTime.now().difference(startedAt),
          usage: result.usage,
        );
      } catch (error) {
        if (attempt <= config.retryAttempts) {
          await Future.delayed(config.retryDelay);
          continue;
        }

        return BatchResult(
          task: task,
          error: error.toString(),
          attemptCount: attempt,
          processingTime: DateTime.now().difference(startedAt),
        );
      }
    }

    throw StateError('Unexpected retry-loop termination.');
  }

  Map<String, List<BatchTask>> groupTasksByComplexity(List<BatchTask> tasks) {
    final groups = <String, List<BatchTask>>{};

    for (final task in tasks) {
      final complexity = task.metadata['complexity'] as String? ?? 'medium';
      groups.putIfAbsent(complexity, () => []).add(task);
    }

    return groups;
  }

  BatchConfig getOptimalConfigForComplexity(String complexity) {
    return switch (complexity) {
      'simple' => const BatchConfig(
          maxConcurrency: 5,
          batchSize: 20,
          retryAttempts: 1,
          requestOptions: core.GenerateTextOptions(
            temperature: 0.0,
            maxOutputTokens: 32,
          ),
        ),
      'medium' => const BatchConfig(
          maxConcurrency: 3,
          batchSize: 10,
          retryAttempts: 2,
          requestOptions: core.GenerateTextOptions(
            temperature: 0.3,
            maxOutputTokens: 120,
          ),
        ),
      'complex' => const BatchConfig(
          maxConcurrency: 1,
          batchSize: 5,
          retryAttempts: 3,
          rateLimitDelay: Duration(seconds: 1),
          requestOptions: core.GenerateTextOptions(
            temperature: 0.7,
            maxOutputTokens: 300,
          ),
        ),
      _ => const BatchConfig(),
    };
  }

  double estimateCost(List<BatchTask> tasks, String complexity) {
    const approximateCostPer1kTokens = 0.0025;
    final tokensPerTask = switch (complexity) {
      'simple' => 60,
      'medium' => 220,
      'complex' => 700,
      _ => 220,
    };

    final totalTokens = tasks.length * tokensPerTask;
    return totalTokens / 1000 * approximateCostPer1kTokens;
  }

  int? totalObservedTokens(List<BatchResult> results) {
    final tokens = results
        .map((result) => result.usage?.totalTokens)
        .whereType<int>()
        .toList();

    if (tokens.isEmpty) {
      return null;
    }

    return tokens.reduce((left, right) => left + right);
  }

  double calculateTotalCost(List<BatchResult> results) {
    const approximateCostPer1kTokens = 0.0025;
    final observedTokens = totalObservedTokens(results);
    if (observedTokens != null) {
      return observedTokens / 1000 * approximateCostPer1kTokens;
    }

    var estimatedTokens = 0;
    for (final result in results) {
      estimatedTokens += _estimateTokens(result.task.prompt);
      estimatedTokens += _estimateTokens(result.response ?? '');
    }

    return estimatedTokens / 1000 * approximateCostPer1kTokens;
  }
}

class Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<T> acquire<T>(Future<T> Function() operation) async {
    await _acquire();
    try {
      return await operation();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void _release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
      return;
    }

    _currentCount++;
  }
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

int _estimateTokens(String text) {
  if (text.isEmpty) {
    return 0;
  }

  return (text.length / 4).ceil();
}

String _preview(String value) {
  const maxLength = 60;
  if (value.length <= maxLength) {
    return value;
  }

  return '${value.substring(0, maxLength)}...';
}

final class _BatchModelEntry {
  final String label;
  final core.LanguageModel model;
  final core.GenerateTextOptions defaultOptions;

  const _BatchModelEntry({
    required this.label,
    required this.model,
    required this.defaultOptions,
  });
}
