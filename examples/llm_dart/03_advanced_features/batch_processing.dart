import 'dart:async';
import 'dart:collection';
import 'package:llm_dart/llm_dart.dart';

/// Advanced batch processing examples for LLM operations
///
/// This example demonstrates:
/// - Concurrent request processing
/// - Rate limiting and throttling
/// - Batch optimization strategies
/// - Error handling and retry logic
/// - Progress tracking and monitoring
/// - Memory management for large batches
/// - Cost optimization techniques
Future<void> main() async {
  print('📦 Batch Processing Examples\n');

  // Initialize model for batch processing
  final model = await initializeBatchModel();
  if (model == null) {
    print('❌ No model available for batch processing');
    return;
  }

  // Create batch processor
  final batchProcessor = BatchProcessor(model);

  // Demonstrate different batch processing scenarios
  await demonstrateBasicBatchProcessing(batchProcessor);
  await demonstrateConcurrentProcessing(batchProcessor);
  await demonstrateRateLimitedProcessing(batchProcessor);
  await demonstrateProgressTracking(batchProcessor);
  await demonstrateErrorHandlingAndRetry(batchProcessor);
  await demonstrateCostOptimization(batchProcessor);

  print('✅ Batch processing examples completed!');
  print('💡 Best practices:');
  print('   • Use appropriate batch sizes for your use case');
  print('   • Implement proper rate limiting');
  print('   • Handle errors gracefully with retry logic');
  print('   • Monitor costs and optimize accordingly');
}

/// Initialize language model for batch processing
Future<LanguageModel?> initializeBatchModel() async {
  try {
    // Use a model suitable for batch processing
    return await ai()
        .openai()
        .apiKey('your-openai-key')
        .model('gpt-3.5-turbo')
        .temperature(0.7)
        .buildLanguageModel();
  } catch (e) {
    print('⚠️  Model initialization failed: $e');
    return null;
  }
}

/// Demonstrate basic batch processing
Future<void> demonstrateBasicBatchProcessing(BatchProcessor processor) async {
  print('📋 Basic Batch Processing:');

  // Create sample batch of tasks
  final tasks = List.generate(
      10,
      (index) => BatchTask(
            id: 'task_$index',
            prompt: 'Summarize the benefits of technology #${index + 1}',
            metadata: {'category': 'technology', 'index': index},
          ));

  print('   🔄 Processing ${tasks.length} tasks...');

  try {
    final results = await processor.processBatch(tasks);

    print('   ✅ Batch completed:');
    print('      • Total tasks: ${tasks.length}');
    print('      • Successful: ${results.where((r) => r.isSuccess).length}');
    print('      • Failed: ${results.where((r) => !r.isSuccess).length}');

    // Show sample results
    final successfulResults = results.where((r) => r.isSuccess).take(3);
    for (final result in successfulResults) {
      print(
          '      📝 ${result.task.id}: ${result.response?.substring(0, 50)}...');
    }
  } catch (e) {
    print('   ❌ Batch processing failed: $e');
  }

  print('');
}

/// Demonstrate concurrent processing with limits
Future<void> demonstrateConcurrentProcessing(BatchProcessor processor) async {
  print('⚡ Concurrent Processing:');

  // Create larger batch for concurrency testing
  final tasks = List.generate(
      20,
      (index) => BatchTask(
            id: 'concurrent_$index',
            prompt: 'Explain concept #${index + 1} in simple terms',
            metadata: {'type': 'explanation'},
          ));

  print('   🔄 Processing ${tasks.length} tasks with concurrency...');

  final stopwatch = Stopwatch()..start();

  try {
    // Process with different concurrency levels
    final concurrencyLevels = [1, 3, 5];

    for (final concurrency in concurrencyLevels) {
      print('      🔧 Testing concurrency level: $concurrency');

      final config = BatchConfig(
        maxConcurrency: concurrency,
        batchSize: 5,
        retryAttempts: 2,
      );

      final startTime = DateTime.now();
      final results = await processor.processBatchWithConfig(
          tasks.take(10).toList(), config);
      final duration = DateTime.now().difference(startTime);

      final successRate =
          results.where((r) => r.isSuccess).length / results.length;
      print('         ⏱️  Duration: ${duration.inMilliseconds}ms');
      print(
          '         ✅ Success rate: ${(successRate * 100).toStringAsFixed(1)}%');
    }
  } catch (e) {
    print('   ❌ Concurrent processing failed: $e');
  }

  stopwatch.stop();
  print('   📊 Total test time: ${stopwatch.elapsedMilliseconds}ms');
  print('');
}

/// Demonstrate rate-limited processing
Future<void> demonstrateRateLimitedProcessing(BatchProcessor processor) async {
  print('🚦 Rate-Limited Processing:');

  // Create batch that would exceed rate limits
  final tasks = List.generate(
      15,
      (index) => BatchTask(
            id: 'rate_limited_$index',
            prompt: 'Generate a creative story about item #${index + 1}',
            metadata: {'type': 'creative'},
          ));

  print('   🔄 Processing with rate limiting...');

  try {
    final config = BatchConfig(
      maxConcurrency: 2,
      rateLimitDelay: Duration(milliseconds: 500), // 500ms between requests
      batchSize: 3,
    );

    final startTime = DateTime.now();
    final results = await processor.processBatchWithConfig(tasks, config);
    final duration = DateTime.now().difference(startTime);

    print('   ✅ Rate-limited processing completed:');
    print('      ⏱️  Total time: ${duration.inSeconds}s');
    print(
        '      📊 Average time per task: ${duration.inMilliseconds ~/ tasks.length}ms');
    print(
        '      ✅ Success rate: ${(results.where((r) => r.isSuccess).length / results.length * 100).toStringAsFixed(1)}%');
  } catch (e) {
    print('   ❌ Rate-limited processing failed: $e');
  }

  print('');
}

/// Demonstrate progress tracking
Future<void> demonstrateProgressTracking(BatchProcessor processor) async {
  print('📈 Progress Tracking:');

  final tasks = List.generate(
      12,
      (index) => BatchTask(
            id: 'progress_$index',
            prompt: 'Analyze data point #${index + 1}',
            metadata: {'analysis_type': 'data'},
          ));

  print('   🔄 Processing with progress tracking...');

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
        final eta = progress.estimatedTimeRemaining;
        print(
            '      📊 Progress: $percentage% (${progress.completedTasks}/${progress.totalTasks}) - ETA: ${eta.inSeconds}s');
      },
      onTaskComplete: (result) {
        final status = result.isSuccess ? '✅' : '❌';
        print('         $status ${result.task.id} completed');
      },
    );

    print('   ✅ Progress tracking completed');
  } catch (e) {
    print('   ❌ Progress tracking failed: $e');
  }

  print('');
}

/// Demonstrate error handling and retry logic
Future<void> demonstrateErrorHandlingAndRetry(BatchProcessor processor) async {
  print('🔄 Error Handling & Retry Logic:');

  // Create tasks that might fail (simulated)
  final tasks = [
    BatchTask(id: 'normal_1', prompt: 'Normal task 1'),
    BatchTask(
        id: 'failing_1',
        prompt: 'This task will fail',
        metadata: {'simulate_failure': true}),
    BatchTask(id: 'normal_2', prompt: 'Normal task 2'),
    BatchTask(
        id: 'failing_2',
        prompt: 'This task will also fail',
        metadata: {'simulate_failure': true}),
    BatchTask(id: 'normal_3', prompt: 'Normal task 3'),
  ];

  print('   🔄 Processing with retry logic...');

  try {
    final config = BatchConfig(
      maxConcurrency: 2,
      retryAttempts: 3,
      retryDelay: Duration(milliseconds: 200),
      continueOnError: true,
    );

    final results = await processor.processBatchWithConfig(tasks, config);

    print('   📊 Error handling results:');
    for (final result in results) {
      final status = result.isSuccess ? '✅' : '❌';
      final attempts = result.attemptCount;
      print('      $status ${result.task.id}: $attempts attempt(s)');

      if (!result.isSuccess && result.error != null) {
        print('         Error: ${result.error}');
      }
    }

    final successCount = results.where((r) => r.isSuccess).length;
    print(
        '   📈 Final success rate: ${(successCount / results.length * 100).toStringAsFixed(1)}%');
  } catch (e) {
    print('   ❌ Error handling demonstration failed: $e');
  }

  print('');
}

/// Demonstrate cost optimization techniques
Future<void> demonstrateCostOptimization(BatchProcessor processor) async {
  print('💰 Cost Optimization:');

  // Create tasks with different complexity levels
  final tasks = [
    BatchTask(
        id: 'simple_1',
        prompt: 'Yes or no?',
        metadata: {'complexity': 'simple'}),
    BatchTask(
        id: 'simple_2',
        prompt: 'True or false?',
        metadata: {'complexity': 'simple'}),
    BatchTask(
        id: 'medium_1',
        prompt: 'Explain this concept briefly',
        metadata: {'complexity': 'medium'}),
    BatchTask(
        id: 'complex_1',
        prompt:
            'Write a detailed analysis of this topic with examples and conclusions',
        metadata: {'complexity': 'complex'}),
  ];

  print('   💡 Optimizing for cost efficiency...');

  try {
    // Group tasks by complexity for optimal processing
    final groupedTasks = processor.groupTasksByComplexity(tasks);

    print('   📊 Task grouping:');
    for (final entry in groupedTasks.entries) {
      print('      ${entry.key}: ${entry.value.length} tasks');
    }

    // Process each group with appropriate settings
    final allResults = <BatchResult>[];

    for (final entry in groupedTasks.entries) {
      final complexity = entry.key;
      final groupTasks = entry.value;

      final config = processor.getOptimalConfigForComplexity(complexity);
      print('   🔧 Processing $complexity tasks with optimized config...');

      final results =
          await processor.processBatchWithConfig(groupTasks, config);
      allResults.addAll(results);

      // Calculate estimated cost
      final estimatedCost = processor.estimateCost(groupTasks, complexity);
      print('      💰 Estimated cost: \$${estimatedCost.toStringAsFixed(4)}');
    }

    print('   ✅ Cost optimization completed');
    print('   📊 Total tasks processed: ${allResults.length}');
    print(
        '   💰 Total estimated cost: \$${processor.calculateTotalCost(allResults).toStringAsFixed(4)}');
  } catch (e) {
    print('   ❌ Cost optimization failed: $e');
  }

  print('');
}

/// Batch task definition
class BatchTask {
  final String id;
  final String prompt;
  final Map<String, dynamic> metadata;

  BatchTask({
    required this.id,
    required this.prompt,
    this.metadata = const {},
  });
}

/// Batch processing result
class BatchResult {
  final BatchTask task;
  final String? response;
  final String? error;
  final int attemptCount;
  final Duration processingTime;

  BatchResult({
    required this.task,
    this.response,
    this.error,
    required this.attemptCount,
    required this.processingTime,
  });

  bool get isSuccess => response != null && error == null;
}

/// Batch processing configuration
class BatchConfig {
  final int maxConcurrency;
  final int batchSize;
  final int retryAttempts;
  final Duration retryDelay;
  final Duration? rateLimitDelay;
  final bool continueOnError;
  final bool enableProgressTracking;

  BatchConfig({
    this.maxConcurrency = 3,
    this.batchSize = 10,
    this.retryAttempts = 2,
    this.retryDelay = const Duration(milliseconds: 1000),
    this.rateLimitDelay,
    this.continueOnError = true,
    this.enableProgressTracking = false,
  });
}

/// Progress tracking information
class BatchProgress {
  final int totalTasks;
  final int completedTasks;
  final int failedTasks;
  final Duration elapsedTime;
  final Duration estimatedTimeRemaining;

  BatchProgress({
    required this.totalTasks,
    required this.completedTasks,
    required this.failedTasks,
    required this.elapsedTime,
    required this.estimatedTimeRemaining,
  });
}

/// Main batch processor class
class BatchProcessor {
  final LanguageModel _model;

  BatchProcessor(this._model);

  /// Process a batch of tasks with default configuration
  Future<List<BatchResult>> processBatch(List<BatchTask> tasks) async {
    return processBatchWithConfig(tasks, BatchConfig());
  }

  /// Process a batch with custom configuration
  Future<List<BatchResult>> processBatchWithConfig(
    List<BatchTask> tasks,
    BatchConfig config,
  ) async {
    final results = <BatchResult>[];
    final semaphore = Semaphore(config.maxConcurrency);

    // Process tasks in chunks
    for (int i = 0; i < tasks.length; i += config.batchSize) {
      final chunk = tasks.skip(i).take(config.batchSize).toList();

      final chunkFutures = chunk.map((task) async {
        return await semaphore.acquire(() async {
          return await _processTaskWithRetry(task, config);
        });
      });

      final chunkResults = await Future.wait(chunkFutures);
      results.addAll(chunkResults);

      // Apply rate limiting between chunks
      if (config.rateLimitDelay != null &&
          i + config.batchSize < tasks.length) {
        await Future.delayed(config.rateLimitDelay!);
      }
    }

    return results;
  }

  /// Process batch with progress tracking
  Future<List<BatchResult>> processBatchWithProgress(
    List<BatchTask> tasks,
    BatchConfig config, {
    Function(BatchProgress)? onProgress,
    Function(BatchResult)? onTaskComplete,
  }) async {
    final results = <BatchResult>[];
    final startTime = DateTime.now();

    final semaphore = Semaphore(config.maxConcurrency);
    var completedCount = 0;
    var failedCount = 0;

    final futures = tasks.map((task) async {
      return await semaphore.acquire(() async {
        final result = await _processTaskWithRetry(task, config);

        completedCount++;
        if (!result.isSuccess) failedCount++;

        onTaskComplete?.call(result);

        // Update progress
        if (onProgress != null) {
          final elapsed = DateTime.now().difference(startTime);
          final avgTimePerTask = elapsed.inMilliseconds / completedCount;
          final remainingTasks = tasks.length - completedCount;
          final eta =
              Duration(milliseconds: (avgTimePerTask * remainingTasks).round());

          onProgress(BatchProgress(
            totalTasks: tasks.length,
            completedTasks: completedCount,
            failedTasks: failedCount,
            elapsedTime: elapsed,
            estimatedTimeRemaining: eta,
          ));
        }

        return result;
      });
    });

    results.addAll(await Future.wait(futures));
    return results;
  }

  /// Process a single task with retry logic
  Future<BatchResult> _processTaskWithRetry(
      BatchTask task, BatchConfig config) async {
    final startTime = DateTime.now();

    for (int attempt = 1; attempt <= config.retryAttempts + 1; attempt++) {
      try {
        // Simulate failure for testing
        if (task.metadata['simulate_failure'] == true && attempt <= 2) {
          throw Exception('Simulated failure for testing');
        }

        final prompt = ChatPromptBuilder.user().text(task.prompt).build();
        final result = await generateTextWithModel(
          _model,
          promptMessages: [prompt],
        );
        final processingTime = DateTime.now().difference(startTime);

        return BatchResult(
          task: task,
          response: result.text,
          attemptCount: attempt,
          processingTime: processingTime,
        );
      } catch (e) {
        if (attempt <= config.retryAttempts) {
          await Future.delayed(config.retryDelay);
          continue;
        }

        final processingTime = DateTime.now().difference(startTime);
        return BatchResult(
          task: task,
          error: e.toString(),
          attemptCount: attempt,
          processingTime: processingTime,
        );
      }
    }

    // This should never be reached
    throw StateError('Unexpected end of retry loop');
  }

  /// Group tasks by complexity for optimization
  Map<String, List<BatchTask>> groupTasksByComplexity(List<BatchTask> tasks) {
    final groups = <String, List<BatchTask>>{};

    for (final task in tasks) {
      final complexity = task.metadata['complexity'] as String? ?? 'medium';
      groups.putIfAbsent(complexity, () => []).add(task);
    }

    return groups;
  }

  /// Get optimal configuration for complexity level
  BatchConfig getOptimalConfigForComplexity(String complexity) {
    switch (complexity) {
      case 'simple':
        return BatchConfig(
          maxConcurrency: 5,
          batchSize: 20,
          retryAttempts: 1,
        );
      case 'medium':
        return BatchConfig(
          maxConcurrency: 3,
          batchSize: 10,
          retryAttempts: 2,
        );
      case 'complex':
        return BatchConfig(
          maxConcurrency: 1,
          batchSize: 5,
          retryAttempts: 3,
          rateLimitDelay: Duration(seconds: 1),
        );
      default:
        return BatchConfig();
    }
  }

  /// Estimate cost for tasks
  double estimateCost(List<BatchTask> tasks, String complexity) {
    const costPerToken = 0.0001; // Example cost

    final tokensPerTask = {
      'simple': 50,
      'medium': 200,
      'complex': 800,
    };

    final tokens = tokensPerTask[complexity] ?? 200;
    return tasks.length * tokens * costPerToken;
  }

  /// Calculate total cost from results
  double calculateTotalCost(List<BatchResult> results) {
    // In a real implementation, you would calculate based on actual token usage
    return results.length * 0.01; // Example calculation
  }
}

/// Semaphore for controlling concurrency
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
    } else {
      _currentCount++;
    }
  }
}
