// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:async';
import 'package:llm_dart/legacy.dart';

/// ⚡ Performance Optimization - Speed and Efficiency
///
/// This example demonstrates various performance optimization techniques:
/// - Caching strategies for responses
/// - Request batching and parallelization
/// - Streaming for better user experience
/// - Memory management and resource optimization
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main() async {
  print('⚡ Performance Optimization - Speed and Efficiency\n');

  // Get API keys
  final openaiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';
  final groqKey = Platform.environment['GROQ_API_KEY'] ?? 'gsk-TESTKEY';

  // Demonstrate different optimization techniques
  await demonstrateCachingStrategies(openaiKey);
  await demonstrateParallelProcessing(openaiKey);
  await demonstrateStreamingOptimization(groqKey);
  await demonstrateBatchProcessing(openaiKey);
  await demonstrateMemoryOptimization(openaiKey);

  print('\n✅ Performance optimization completed!');
  print('📖 Explore ../04_providers/ for provider-specific optimizations');
}

/// Demonstrate caching strategies
Future<void> demonstrateCachingStrategies(String apiKey) async {
  print('💾 Caching Strategies:\n');

  try {
    // Create provider
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.3) // Lower temperature for more consistent responses
        .maxTokens(200)
        .build();

    // Simple in-memory cache
    final cache = <String, String>{};

    final questions = [
      'What is the capital of France?',
      'What is 2 + 2?',
      'What is the capital of France?', // Duplicate for cache test
      'Explain photosynthesis briefly.',
      'What is 2 + 2?', // Another duplicate
    ];

    print('   Testing cache performance:');

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final stopwatch = Stopwatch()..start();

      String response;
      bool fromCache = false;

      if (cache.containsKey(question)) {
        response = cache[question]!;
        fromCache = true;
      } else {
        final aiResponse = await provider.chat([ChatMessage.user(question)]);
        response = aiResponse.text ?? 'No response';
        cache[question] = response;
      }

      stopwatch.stop();

      print('   ${i + 1}. "$question"');
      print(
          '      ${fromCache ? '💾 Cached' : '🌐 API'}: ${stopwatch.elapsedMilliseconds}ms');
      print(
          '      Response: ${response.substring(0, response.length > 50 ? 50 : response.length)}...\n');
    }

    print('   💡 Caching Benefits:');
    print('      • Dramatically faster responses for repeated queries');
    print('      • Reduced API costs and rate limit usage');
    print('      • Better user experience with instant responses');
    print('      • Offline capability for cached content');
    print('   ✅ Caching demonstration successful\n');
  } catch (e) {
    print('   ❌ Caching demonstration failed: $e\n');
  }
}

/// Demonstrate parallel processing
Future<void> demonstrateParallelProcessing(String apiKey) async {
  print('🔄 Parallel Processing:\n');

  try {
    // Create provider
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .maxTokens(100)
        .build();

    final questions = [
      'What is machine learning?',
      'Explain blockchain technology.',
      'What is quantum computing?',
      'Define artificial intelligence.',
      'What is cloud computing?',
    ];

    // Sequential processing
    print('   Sequential Processing:');
    final sequentialStopwatch = Stopwatch()..start();

    for (final question in questions) {
      await provider.chat([ChatMessage.user(question)]);
      print('      ✓ ${question.substring(0, 30)}...');
    }

    sequentialStopwatch.stop();
    print('      Total time: ${sequentialStopwatch.elapsedMilliseconds}ms\n');

    // Parallel processing
    print('   Parallel Processing:');
    final parallelStopwatch = Stopwatch()..start();

    final futures = questions
        .map((question) => provider.chat([ChatMessage.user(question)]))
        .toList();

    await Future.wait(futures);
    parallelStopwatch.stop();

    for (int i = 0; i < questions.length; i++) {
      print('      ✓ ${questions[i].substring(0, 30)}...');
    }

    print('      Total time: ${parallelStopwatch.elapsedMilliseconds}ms');

    final speedup = sequentialStopwatch.elapsedMilliseconds /
        parallelStopwatch.elapsedMilliseconds;
    print('      🚀 Speedup: ${speedup.toStringAsFixed(1)}x faster\n');

    print('   💡 Parallel Processing Benefits:');
    print('      • Significant time savings for independent requests');
    print('      • Better resource utilization');
    print('      • Improved user experience');
    print('      • Scalable for large batch operations');
    print('   ✅ Parallel processing demonstration successful\n');
  } catch (e) {
    print('   ❌ Parallel processing demonstration failed: $e\n');
  }
}

/// Demonstrate streaming optimization
Future<void> demonstrateStreamingOptimization(String apiKey) async {
  print('🌊 Streaming Optimization:\n');

  try {
    // Create fast provider (Groq for speed)
    final provider = await ai()
        .groq()
        .apiKey(apiKey)
        .model('llama-3.1-8b-instant')
        .temperature(0.7)
        .maxTokens(300)
        .build();

    final question = 'Write a short story about a robot learning to paint.';

    // Regular response
    print('   Regular Response:');
    final regularStopwatch = Stopwatch()..start();
    final response = await provider.chat([ChatMessage.user(question)]);
    regularStopwatch.stop();

    print('      Total time: ${regularStopwatch.elapsedMilliseconds}ms');
    print(
        '      Time to first content: ${regularStopwatch.elapsedMilliseconds}ms');
    print('      Response: ${response.text}\n');

    // Streaming response
    print('   Streaming Response:');
    final streamStopwatch = Stopwatch()..start();
    var firstChunkTime = 0;
    var chunkCount = 0;
    final responseBuffer = StringBuffer();

    await for (final event
        in provider.chatStream([ChatMessage.user(question)])) {
      switch (event) {
        case TextDeltaEvent(delta: final delta):
          chunkCount++;
          responseBuffer.write(delta);

          if (firstChunkTime == 0) {
            firstChunkTime = streamStopwatch.elapsedMilliseconds;
            print('      Time to first chunk: ${firstChunkTime}ms');
          }
          break;

        case CompletionEvent():
          streamStopwatch.stop();
          break;

        case ErrorEvent(error: final error):
          print('      Error: $error');
          return;

        case ThinkingDeltaEvent():
        case ToolCallDeltaEvent():
          break;
      }
    }

    print('      Total time: ${streamStopwatch.elapsedMilliseconds}ms');
    print('      Chunks received: $chunkCount');
    print('      Response: ${responseBuffer.toString()}\n');

    final timeToFirstContent = firstChunkTime;
    final perceivedSpeedup =
        regularStopwatch.elapsedMilliseconds / timeToFirstContent;

    print('   📊 Streaming Performance:');
    print(
        '      • Time to first content: ${timeToFirstContent}ms vs ${regularStopwatch.elapsedMilliseconds}ms');
    print(
        '      • Perceived speedup: ${perceivedSpeedup.toStringAsFixed(1)}x faster');
    print(
        '      • User sees content ${perceivedSpeedup.toStringAsFixed(1)}x sooner');

    print('\n   💡 Streaming Benefits:');
    print('      • Dramatically reduced perceived latency');
    print('      • Better user engagement');
    print('      • Progressive content display');
    print('      • Ability to process content as it arrives');
    print('   ✅ Streaming optimization demonstration successful\n');
  } catch (e) {
    print('   ❌ Streaming optimization demonstration failed: $e\n');
  }
}

/// Demonstrate batch processing
Future<void> demonstrateBatchProcessing(String apiKey) async {
  print('📦 Batch Processing:\n');

  try {
    // Create provider
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.3)
        .maxTokens(50)
        .build();

    // Simulate a large dataset
    final dataItems = List.generate(
        20,
        (i) =>
            'Summarize this topic in one sentence: Topic ${i + 1} about technology trends.');

    print('   Processing ${dataItems.length} items...');

    // Batch processing with controlled concurrency
    const batchSize = 5;
    final results = <String>[];
    final totalStopwatch = Stopwatch()..start();

    for (int i = 0; i < dataItems.length; i += batchSize) {
      final batch = dataItems.skip(i).take(batchSize).toList();

      print(
          '   Processing batch ${(i ~/ batchSize) + 1}/${(dataItems.length / batchSize).ceil()}...');

      final batchStopwatch = Stopwatch()..start();

      // Process batch in parallel
      final batchFutures =
          batch.map((item) => provider.chat([ChatMessage.user(item)])).toList();

      final batchResponses = await Future.wait(batchFutures);
      batchStopwatch.stop();

      // Collect results
      for (final response in batchResponses) {
        results.add(response.text ?? 'No response');
      }

      print('      Batch completed in ${batchStopwatch.elapsedMilliseconds}ms');

      // Small delay to respect rate limits
      await Future.delayed(Duration(milliseconds: 100));
    }

    totalStopwatch.stop();

    print('\n   📊 Batch Processing Results:');
    print('      • Total items processed: ${results.length}');
    print('      • Total time: ${totalStopwatch.elapsedMilliseconds}ms');
    print(
        '      • Average time per item: ${(totalStopwatch.elapsedMilliseconds / results.length).toStringAsFixed(1)}ms');
    print('      • Batch size: $batchSize items');

    print('\n   💡 Batch Processing Benefits:');
    print('      • Controlled concurrency prevents rate limiting');
    print('      • Progress tracking for long operations');
    print('      • Memory efficient for large datasets');
    print('      • Fault tolerance with batch-level retries');
    print('   ✅ Batch processing demonstration successful\n');
  } catch (e) {
    print('   ❌ Batch processing demonstration failed: $e\n');
  }
}

/// Demonstrate memory optimization
Future<void> demonstrateMemoryOptimization(String apiKey) async {
  print('🧠 Memory Optimization:\n');

  try {
    // Create provider
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .maxTokens(200)
        .build();

    // Simulate conversation with memory management
    final conversation = <ChatMessage>[];
    const maxContextLength = 10; // Keep only last 10 messages

    print('   Simulating long conversation with memory management:');

    for (int i = 1; i <= 15; i++) {
      // Add user message
      conversation.add(ChatMessage.user('Message $i: Tell me about topic $i'));

      // Get AI response
      final response = await provider.chat(conversation);

      // Add AI response
      conversation.add(ChatMessage.assistant(response.text ?? ''));

      // Memory management: keep only recent messages
      if (conversation.length > maxContextLength) {
        final messagesToRemove = conversation.length - maxContextLength;
        conversation.removeRange(0, messagesToRemove);
        print('      Trimmed $messagesToRemove old messages (turn $i)');
      }

      print('      Turn $i: ${conversation.length} messages in context');
    }

    print('\n   📊 Memory Management Results:');
    print('      • Final conversation length: ${conversation.length} messages');
    print('      • Maximum context maintained: $maxContextLength messages');
    print('      • Memory usage kept constant despite long conversation');

    // Demonstrate streaming memory efficiency
    print('\n   Streaming Memory Efficiency:');
    print('      Processing large response with streaming...');

    var totalChars = 0;

    await for (final event in provider.chatStream([
      ChatMessage.user('Write a detailed explanation of quantum computing.')
    ])) {
      switch (event) {
        case TextDeltaEvent(delta: final delta):
          totalChars += delta.length;
          // In real app, process chunk immediately instead of accumulating
          print(
              '      Processed chunk: ${delta.length} chars (total: $totalChars)');
          break;

        case CompletionEvent():
          print('      Streaming completed');
          break;

        case ErrorEvent():
        case ThinkingDeltaEvent():
        case ToolCallDeltaEvent():
          break;
      }
    }

    print('\n   💡 Memory Optimization Benefits:');
    print('      • Constant memory usage for long conversations');
    print('      • Streaming prevents large response accumulation');
    print('      • Context window management maintains relevance');
    print('      • Scalable for production applications');
    print('   ✅ Memory optimization demonstration successful\n');
  } catch (e) {
    print('   ❌ Memory optimization demonstration failed: $e\n');
  }
}

/// 🎯 Key Performance Optimization Concepts Summary:
///
/// Caching Strategies:
/// - In-memory caching for repeated queries
/// - Persistent caching for long-term storage
/// - Cache invalidation and TTL policies
/// - Distributed caching for scalability
///
/// Parallel Processing:
/// - Concurrent requests for independent operations
/// - Controlled concurrency to respect rate limits
/// - Future.wait() for batch operations
/// - Load balancing across providers
///
/// Streaming Optimization:
/// - Reduced perceived latency
/// - Progressive content display
/// - Real-time processing capabilities
/// - Memory efficient for large responses
///
/// Batch Processing:
/// - Controlled concurrency
/// - Progress tracking
/// - Fault tolerance
/// - Rate limit management
///
/// Memory Management:
/// - Context window trimming
/// - Streaming for large responses
/// - Efficient data structures
/// - Garbage collection optimization
///
/// Best Practices:
/// 1. Cache frequently requested content
/// 2. Use parallel processing for independent tasks
/// 3. Implement streaming for better UX
/// 4. Manage memory usage in long conversations
/// 5. Monitor and measure performance metrics
///
/// Next Steps:
/// - ../04_providers/: Provider-specific optimizations
/// - ../06_integration/: Production integration patterns
/// - ../02_core_features/error_handling.dart: Robust error handling
