// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 🛑 Cancellation Demo - Request Cancellation Support
///
/// This example demonstrates how to cancel in-flight LLM requests:
/// - Cancelling streaming chat responses
/// - Cancelling list models requests
/// - Handling cancellation errors gracefully
/// - Using CancelToken for request control
/// - Detecting and responding to cancellation
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
void main() async {
  print('🛑 Cancellation Demo - Request Cancellation Support\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Error: OPENAI_API_KEY environment variable not set');
    print('   Please set your API key:');
    print('   export OPENAI_API_KEY="your-key"\n');
    exit(1);
  }

  try {
    // Create AI provider
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .maxTokens(500)
        .build();

    // Demonstrate different cancellation scenarios
    await demonstrateStreamCancellation(provider);
    if (provider is ModelListingCapability) {
      await demonstrateListModelsCancellation(
          provider as ModelListingCapability);
    }
    await demonstrateMultipleRequestCancellation(provider);
    await demonstrateCancellationHandling(provider);
    await demonstrateCancellationTiming(provider);

    print('\n✅ Cancellation demo completed!');
  } catch (e) {
    print('❌ Failed to initialize provider: $e');
    print('   Check your API key and try again\n');
    exit(1);
  }
}

/// Demonstrate cancelling a streaming chat response
Future<void> demonstrateStreamCancellation(ChatCapability provider) async {
  print('🌊 Stream Cancellation:\n');

  try {
    // Create a cancel token
    final cancelToken = CancelToken();

    final messages = [
      ChatMessage.user(
          'Write a very long essay about the history of computers, '
          'starting from the abacus and covering at least 50 different '
          'milestones in computing history.')
    ];

    print('   User: Write a very long essay about computers...');
    print('   AI: ');

    var chunkCount = 0;
    var charCount = 0;
    var firstTokenReceived = false;

    // Start streaming
    final streamFuture = () async {
      await for (final event
          in provider.chatStream(messages, cancelToken: cancelToken)) {
        switch (event) {
          case TextDeltaEvent(delta: final delta):
            chunkCount++;
            charCount += delta.length;
            stdout.write(delta);

            // Cancel after receiving the first token
            if (!firstTokenReceived) {
              firstTokenReceived = true;
              print('\n\n   🛑 First token received, cancelling stream...');
              cancelToken.cancel('User stopped reading after first token');
            }
            break;

          case CompletionEvent():
            print('\n   ⚠️  Stream completed without cancellation');
            break;

          case ErrorEvent(error: final error):
            if (CancellationHelper.isCancelled(error)) {
              print('   ✅ Stream cancelled via ErrorEvent');
            } else {
              print('\n   ❌ Stream error: $error');
            }
            break;

          case ThinkingDeltaEvent():
          case ToolCallDeltaEvent():
            // Handle other event types
            break;
        }
      }
    }();

    // Wait for the stream to finish processing
    await streamFuture;

    print('   📊 Statistics before cancellation:');
    print('      • Chunks received: $chunkCount');
    print('      • Characters received: $charCount');
    print('   ✅ Stream cancellation successful\n');
  } on CancelledError catch (e) {
    print('\n   ✅ Caught CancelledError: ${e.message}');
    final reason = CancellationHelper.getCancellationReason(e);
    print('   📝 Cancellation reason: $reason\n');
  } catch (e) {
    if (CancellationHelper.isCancelled(e)) {
      print(
          '\n   ✅ Stream cancelled: ${CancellationHelper.getCancellationReason(e)}');
    } else {
      print('   ❌ Stream cancellation test failed: $e\n');
    }
  }
}

/// Demonstrate cancelling a list models request
Future<void> demonstrateListModelsCancellation(
    ModelListingCapability provider) async {
  print('📋 List Models Cancellation:\n');

  try {
    // Create a cancel token
    final cancelToken = CancelToken();

    print('   Requesting model list...');

    // Start the request and cancel immediately
    final requestFuture = provider.models(cancelToken: cancelToken);

    // Cancel almost immediately (but give it a moment to start)
    await Future.delayed(Duration(milliseconds: 10));
    print('   🛑 Cancelling request...');
    cancelToken.cancel('User cancelled model listing');

    // Try to await the result
    final models = await requestFuture;

    // If we get here, the request completed before cancellation
    print(
        '   ⚠️  Request completed before cancellation: ${models.length} models');
  } on CancelledError catch (e) {
    print('   ✅ Caught CancelledError: ${e.message}');
    print('   📝 List models request successfully cancelled');
  } catch (e) {
    if (CancellationHelper.isCancelled(e)) {
      print(
          '   ✅ Request cancelled: ${CancellationHelper.getCancellationReason(e)}');
    } else {
      print('   ❌ Unexpected error: $e');
    }
  }

  print('   ✅ List models cancellation test completed\n');
}

/// Demonstrate cancelling multiple requests with one token
Future<void> demonstrateMultipleRequestCancellation(
    ChatCapability provider) async {
  print('🔗 Multiple Request Cancellation:\n');

  try {
    // Create a shared cancel token
    final sharedToken = CancelToken();

    print('   Starting multiple requests with shared token...');

    // Start multiple requests with the same token
    final request1 = provider.chat(
      [ChatMessage.user('What is 2+2?')],
      cancelToken: sharedToken,
    );

    final request2 = provider.chat(
      [ChatMessage.user('What is the capital of France?')],
      cancelToken: sharedToken,
    );

    final request3 = provider.chat(
      [ChatMessage.user('Write a haiku about coding.')],
      cancelToken: sharedToken,
    );

    // Give requests a moment to start
    await Future.delayed(Duration(milliseconds: 50));

    print('   🛑 Cancelling all requests with shared token...');
    sharedToken.cancel('Batch cancellation');

    // Try to await all results
    var cancelledCount = 0;
    var completedCount = 0;

    await Future.wait([
      request1
          .then((_) => completedCount++)
          .catchError((e) => cancelledCount++),
      request2
          .then((_) => completedCount++)
          .catchError((e) => cancelledCount++),
      request3
          .then((_) => completedCount++)
          .catchError((e) => cancelledCount++),
    ]);

    print('   📊 Results:');
    print('      • Cancelled requests: $cancelledCount');
    print('      • Completed requests: $completedCount');
    print('   ✅ Multiple request cancellation completed\n');
  } catch (e) {
    print('   ❌ Multiple request cancellation failed: $e\n');
  }
}

/// Demonstrate proper cancellation error handling
Future<void> demonstrateCancellationHandling(ChatCapability provider) async {
  print('🛡️  Cancellation Error Handling:\n');

  // Test 1: Using CancellationHelper.isCancelled()
  print('   Test 1: Using CancellationHelper.isCancelled()');
  try {
    final cancelToken = CancelToken();
    final requestFuture = provider.chat(
      [ChatMessage.user('Hello')],
      cancelToken: cancelToken,
    );

    cancelToken.cancel('Test cancellation');
    await requestFuture;

    print('      ❌ Expected cancellation error');
  } catch (e) {
    if (CancellationHelper.isCancelled(e)) {
      print('      ✅ Correctly detected cancellation');
      final reason = CancellationHelper.getCancellationReason(e);
      print('      📝 Reason: $reason');
    } else {
      print('      ⚠️  Not a cancellation error: ${e.runtimeType}');
    }
  }

  // Test 2: Using CancelledError catch
  print('\n   Test 2: Using CancelledError catch');
  try {
    final cancelToken = CancelToken();
    final requestFuture = provider.chat(
      [ChatMessage.user('Hello again')],
      cancelToken: cancelToken,
    );

    cancelToken.cancel('Test CancelledError catch');
    await requestFuture;

    print('      ❌ Expected CancelledError');
  } on CancelledError catch (e) {
    print('      ✅ Caught CancelledError: ${e.message}');
  } catch (e) {
    if (CancellationHelper.isCancelled(e)) {
      print('      ✅ Caught via generic handler (also valid)');
    } else {
      print('      ⚠️  Unexpected error type: ${e.runtimeType}');
    }
  }

  // Test 3: Distinguishing cancellation from other errors
  print('\n   Test 3: Distinguishing cancellation from other errors');

  // Test cancellation error
  try {
    final cancelToken = CancelToken();
    final future = provider.chat(
      [ChatMessage.user('Test')],
      cancelToken: cancelToken,
    );
    cancelToken.cancel();
    await future;
  } catch (e) {
    final isCancelled = CancellationHelper.isCancelled(e);
    print(
        '      • Cancellation: ${isCancelled ? "Cancellation ✅" : "Other error ❌"}');
  }

  // Test other error type (invalid API key)
  try {
    final invalidProvider =
        await ai().openai().apiKey('sk-invalid').model('gpt-4o-mini').build();
    await invalidProvider.chat([ChatMessage.user('Test')]);
  } catch (e) {
    final isCancelled = CancellationHelper.isCancelled(e);
    print(
        '      • Invalid API Key: ${isCancelled ? "Cancellation ❌" : "Other error ✅"}');
  }

  print('\n   ✅ Cancellation error handling tests completed\n');
}

/// Demonstrate cancellation timing and behavior
Future<void> demonstrateCancellationTiming(ChatCapability provider) async {
  print('⏱️  Cancellation Timing:\n');

  // Test 1: Cancel before request starts
  print('   Test 1: Pre-cancelled token');
  try {
    final cancelToken = CancelToken();
    cancelToken.cancel('Pre-cancelled');

    final response = await provider.chat(
      [ChatMessage.user('This should not execute')],
      cancelToken: cancelToken,
    );

    print(
        '      ⚠️  Request completed despite pre-cancellation: ${response.text}');
  } catch (e) {
    if (CancellationHelper.isCancelled(e)) {
      print('      ✅ Pre-cancelled token correctly rejected request');
    } else {
      print('      ⚠️  Unexpected error: $e');
    }
  }

  // Test 2: Cancel during execution
  print('\n   Test 2: Cancel during execution');
  final stopwatch = Stopwatch()..start();
  try {
    final cancelToken = CancelToken();

    final requestFuture = provider.chat(
      [ChatMessage.user('Count from 1 to 1000 with explanations.')],
      cancelToken: cancelToken,
    );

    // Cancel after 200ms
    await Future.delayed(Duration(milliseconds: 200));
    cancelToken.cancel('Mid-execution cancellation');

    await requestFuture;
    print('      ⚠️  Request completed');
  } catch (e) {
    stopwatch.stop();
    if (CancellationHelper.isCancelled(e)) {
      print('      ✅ Request cancelled during execution');
      print('      ⏱️  Time elapsed: ${stopwatch.elapsedMilliseconds}ms');
    } else {
      print('      ⚠️  Unexpected error: $e');
    }
  }

  // Test 3: Multiple cancellations are safe
  print('\n   Test 3: Multiple cancel() calls are safe');
  final cancelToken = CancelToken();
  cancelToken.cancel('First cancel');
  cancelToken.cancel('Second cancel'); // Should not throw
  cancelToken.cancel('Third cancel'); // Should not throw
  print('      ✅ Multiple cancel() calls handled safely');
  print('      📝 Token is cancelled: ${cancelToken.isCancelled}');

  print('\n   ✅ Cancellation timing tests completed\n');
}
