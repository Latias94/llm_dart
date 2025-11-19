// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:async';
import 'package:llm_dart/llm_dart.dart';

/// 🛡️ Error Handling - Production-Ready Error Management
///
/// This example demonstrates comprehensive error handling strategies:
/// - Different error types and their handling
/// - Retry mechanisms and backoff strategies
/// - Graceful degradation and fallbacks
/// - Monitoring and logging best practices
/// - Capability factory method error handling
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main() async {
  print('🛡️ Error Handling - Production-Ready Error Management\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';

  // Create AI provider
  final provider = await ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-4o-mini')
      .temperature(0.7)
      .maxTokens(500)
      .build();

  // Demonstrate different error handling scenarios
  await demonstrateErrorTypes();
  await demonstrateRetryStrategies(provider);
  await demonstrateGracefulDegradation(provider);
  await demonstrateCircuitBreaker(provider);
  await demonstrateMonitoringAndLogging(provider);

  print('\n✅ Error handling completed!');
}

/// Demonstrate different error types
Future<void> demonstrateErrorTypes() async {
  print('🔍 Error Types and Classification:\n');

  // Test different error scenarios
  final errorTests = [
    () => testAuthenticationError(),
    () => testRateLimitError(),
    () => testInvalidRequestError(),
    () => testNetworkError(),
    () => testTimeoutError(),
    () => testUnsupportedCapabilityError(),
  ];

  for (final test in errorTests) {
    try {
      await test();
    } catch (e) {
      // Errors are handled within each test function
    }
  }

  print('   ✅ Error types demonstration completed\n');
}

/// Test authentication error
Future<void> testAuthenticationError() async {
  print('   🔐 Testing Authentication Error:');

  try {
    final invalidAi = await ai()
        .openai()
        .apiKey('invalid-key-12345')
        .model('gpt-4o-mini')
        .build();

    await invalidAi.chat([ChatMessage.user('Hello')]);
    print('      ❌ Expected authentication error but got success');
  } on AuthError catch (e) {
    print('      ✅ Caught AuthError: ${e.message}');
    print('      💡 Action: Check API key validity and permissions');
  } catch (e) {
    print('      ⚠️  Unexpected error type: ${e.runtimeType}');
  }
}

/// Test rate limit error
Future<void> testRateLimitError() async {
  print('   ⏱️  Testing Rate Limit (simulated):');

  // Note: This is simulated since we can't easily trigger real rate limits
  try {
    throw RateLimitError('Rate limit exceeded: 60 requests per minute');
  } on RateLimitError catch (e) {
    print('      ✅ Caught RateLimitError: ${e.message}');
    print('      💡 Action: Implement exponential backoff and retry');
  }
}

/// Test invalid request error
Future<void> testInvalidRequestError() async {
  print('   📝 Testing Invalid Request Error:');

  try {
    final provider = await ai()
        .openai()
        .apiKey(Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY')
        .model('invalid-model-name-xyz')
        .build();

    await provider.chat([ChatMessage.user('Hello')]);
    print('      ❌ Expected invalid request error but got success');
  } on InvalidRequestError catch (e) {
    print('      ✅ Caught InvalidRequestError: ${e.message}');
    print('      💡 Action: Validate request parameters before sending');
  } on ModelNotAvailableError catch (e) {
    print('      ✅ Caught ModelNotAvailableError: ${e.message}');
    print('      💡 Action: Use a valid model name');
  } on ServerError catch (e) {
    print('      ✅ Caught ServerError (model not found): ${e.message}');
    print('      💡 Action: Verify model availability');
  } catch (e) {
    print('      ⚠️  Unexpected error type: ${e.runtimeType}');
    print('      📝 Error details: $e');
  }
}

/// Test network error
Future<void> testNetworkError() async {
  print('   🌐 Testing Network Error:');

  try {
    final provider = await ai()
        .openai()
        .apiKey('sk-test')
        .baseUrl('https://invalid-domain-12345.com/v1/')
        .model('gpt-4o-mini')
        .build();

    await provider.chat([ChatMessage.user('Hello')]);
    print('      ❌ Expected network error but got success');
  } on HttpError catch (e) {
    print('      ✅ Caught HttpError: ${e.message}');
    print('      💡 Action: Check network connectivity and endpoint URL');
  } on GenericError catch (e) {
    print('      ✅ Caught GenericError (connection failed): ${e.message}');
    print('      💡 Action: Verify network connectivity and endpoint URL');
  } catch (e) {
    print('      ⚠️  Network-related error: ${e.runtimeType}');
    print('      📝 Error details: $e');
  }
}

/// Test timeout error
Future<void> testTimeoutError() async {
  print('   ⏰ Testing Timeout Error:');

  try {
    final provider = await ai()
        .openai()
        .apiKey(Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY')
        .model('gpt-4o-mini')
        .timeout(Duration(milliseconds: 1)) // Very short timeout
        .build();

    await provider.chat([ChatMessage.user('Hello')]);
    print('      ❌ Expected timeout error but got success');
  } on TimeoutError catch (e) {
    print('      ✅ Caught TimeoutError: ${e.message}');
    print('      💡 Action: Increase timeout or implement retry logic');
  } catch (e) {
    print('      ⚠️  Timeout-related error: ${e.runtimeType}');
  }
}

/// Test unsupported capability error (new capability factory methods)
Future<void> testUnsupportedCapabilityError() async {
  print('   🚫 Testing Unsupported Capability Error:');

  try {
    // Try to build audio capability with a provider that doesn't support it
    // Note: Using a fake API key to avoid actual API calls
    await ai()
        .groq() // Groq doesn't support audio capabilities
        .apiKey('fake-key-for-testing')
        .buildAudio(); // This should throw UnsupportedCapabilityError

    print('      ❌ Expected UnsupportedCapabilityError but got success');
  } on UnsupportedCapabilityError catch (e) {
    print('      ✅ Caught UnsupportedCapabilityError: ${e.message}');
    print(
        '      💡 Action: Use a provider that supports the required capability');
    print('      📋 Error details: $e');
  } catch (e) {
    print('      ⚠️  Unexpected error type: ${e.runtimeType}');
    print('      📝 Error details: $e');
  }

  // Test another unsupported capability
  try {
    // Try to build image generation with a provider that doesn't support it
    await ai()
        .groq() // Groq doesn't support image generation
        .apiKey('fake-key-for-testing')
        .buildImageGeneration(); // This should throw UnsupportedCapabilityError

    print('      ❌ Expected UnsupportedCapabilityError for image generation');
  } on UnsupportedCapabilityError catch (e) {
    print('      ✅ Image generation capability correctly rejected');
    print('      📝 Provider limitation: ${e.message}');
  } catch (e) {
    print('      ⚠️  Unexpected error for image generation: ${e.runtimeType}');
  }

  print('      💡 Capability factory methods provide compile-time type safety');
  print(
      '      🎯 Use buildAudio(), buildImageGeneration(), etc. for type-safe building');
}

/// Demonstrate retry strategies
Future<void> demonstrateRetryStrategies(ChatCapability ai) async {
  print('🔄 Retry Strategies:\n');

  // Test exponential backoff
  await testExponentialBackoff(ai);

  // Test linear backoff
  await testLinearBackoff(ai);

  // Test immediate retry
  await testImmediateRetry(ai);

  print('   ✅ Retry strategies demonstration completed\n');
}

/// Test exponential backoff retry
Future<void> testExponentialBackoff(ChatCapability ai) async {
  print('   📈 Exponential Backoff Retry:');

  final retryHandler = RetryHandler(
    maxRetries: 3,
    strategy: RetryStrategy.exponentialBackoff,
    baseDelay: Duration(milliseconds: 100),
  );

  try {
    final result = await retryHandler.execute(() async {
      // Simulate intermittent failure
      if (DateTime.now().millisecond % 3 != 0) {
        throw Exception('Simulated intermittent failure');
      }
      return await ai.chat([ChatMessage.user('Hello')]);
    });

    final text = result.text ?? '';
    final preview = text.length > 50 ? text.substring(0, 50) : text;
    print('      ✅ Success after retries: $preview...');
  } catch (e) {
    print('      ❌ Failed after all retries: $e');
  }
}

/// Test linear backoff retry
Future<void> testLinearBackoff(ChatCapability ai) async {
  print('   📊 Linear Backoff Retry:');

  final retryHandler = RetryHandler(
    maxRetries: 2,
    strategy: RetryStrategy.linearBackoff,
    baseDelay: Duration(milliseconds: 200),
  );

  try {
    final result = await retryHandler.execute(() async {
      return await ai.chat([ChatMessage.user('What is 2+2?')]);
    });

    print('      ✅ Success: ${result.text}');
  } catch (e) {
    print('      ❌ Failed: $e');
  }
}

/// Test immediate retry
Future<void> testImmediateRetry(ChatCapability ai) async {
  print('   ⚡ Immediate Retry:');

  final retryHandler = RetryHandler(
    maxRetries: 1,
    strategy: RetryStrategy.immediate,
  );

  try {
    final result = await retryHandler.execute(() async {
      return await ai.chat([ChatMessage.user('Hello again!')]);
    });

    final text = result.text ?? '';
    final preview = text.length > 30 ? text.substring(0, 30) : text;
    print('      ✅ Success: $preview...');
  } catch (e) {
    print('      ❌ Failed: $e');
  }
}

/// Demonstrate graceful degradation
Future<void> demonstrateGracefulDegradation(ChatCapability ai) async {
  print('🎭 Graceful Degradation:\n');

  final fallbackHandler = FallbackHandler([
    () => ai.chat([ChatMessage.user('What is the weather like?')]),
    () => _fallbackToSimpleResponse(),
    () => _fallbackToStaticResponse(),
  ]);

  try {
    final result = await fallbackHandler.execute();
    print('   ✅ Fallback result: ${result.text}');
  } catch (e) {
    print('   ❌ All fallbacks failed: $e');
  }

  print('   ✅ Graceful degradation demonstration completed\n');
}

/// Demonstrate circuit breaker pattern
Future<void> demonstrateCircuitBreaker(ChatCapability ai) async {
  print('⚡ Circuit Breaker Pattern:\n');

  final circuitBreaker = CircuitBreaker(
    failureThreshold: 2,
    timeout: Duration(seconds: 5),
  );

  // Simulate multiple calls
  for (int i = 1; i <= 5; i++) {
    try {
      final result = await circuitBreaker.execute(() async {
        // Simulate failures for first few calls
        if (i <= 2) {
          throw Exception('Simulated service failure');
        }
        return await ai.chat([ChatMessage.user('Hello $i')]);
      });

      final text = result.text ?? '';
      final preview = text.length > 30 ? text.substring(0, 30) : text;
      print('   Call $i: ✅ $preview...');
    } catch (e) {
      print('   Call $i: ❌ ${e.toString()}');
    }
  }

  print('   ✅ Circuit breaker demonstration completed\n');
}

/// Demonstrate monitoring and logging
Future<void> demonstrateMonitoringAndLogging(ChatCapability ai) async {
  print('📊 Monitoring and Logging:\n');

  final monitor = AIServiceMonitor();

  try {
    // Monitor a successful call
    await monitor.trackCall('chat_request', () async {
      return await ai.chat([ChatMessage.user('Successful request')]);
    });
  } catch (e) {
    print('   ⚠️  Monitoring error during successful call: $e');
  }

  try {
    // Monitor a failed call
    await monitor.trackCall('failed_request', () async {
      throw Exception('Simulated failure');
    });
  } catch (e) {
    print('   ⚠️  Expected monitoring error during failed call: $e');
  }

  // Display metrics
  monitor.displayMetrics();

  print('   ✅ Monitoring and logging demonstration completed\n');
}

/// Fallback response functions
Future<ChatResponse> _fallbackToSimpleResponse() async {
  await Future.delayed(Duration(milliseconds: 100));
  return SimpleChatResponse(
      'I apologize, but I\'m experiencing technical difficulties. Please try again later.');
}

Future<ChatResponse> _fallbackToStaticResponse() async {
  return SimpleChatResponse(
      'Service temporarily unavailable. Please contact support if the issue persists.');
}

/// Retry strategy enumeration
enum RetryStrategy {
  immediate,
  linearBackoff,
  exponentialBackoff,
}

/// Retry handler implementation
class RetryHandler {
  final int maxRetries;
  final RetryStrategy strategy;
  final Duration baseDelay;

  RetryHandler({
    required this.maxRetries,
    required this.strategy,
    this.baseDelay = const Duration(milliseconds: 1000),
  });

  Future<T> execute<T>(Future<T> Function() operation) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          rethrow;
        }

        final delay = _calculateDelay(attempt);
        print(
            '      Attempt $attempt failed, retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
    }

    // Final attempt
    return await operation();
  }

  Duration _calculateDelay(int attempt) {
    switch (strategy) {
      case RetryStrategy.immediate:
        return Duration.zero;
      case RetryStrategy.linearBackoff:
        return Duration(milliseconds: baseDelay.inMilliseconds * attempt);
      case RetryStrategy.exponentialBackoff:
        return Duration(
            milliseconds: baseDelay.inMilliseconds * (1 << (attempt - 1)));
    }
  }
}

/// Fallback handler implementation
class FallbackHandler {
  final List<Future<ChatResponse> Function()> fallbacks;

  FallbackHandler(this.fallbacks);

  Future<ChatResponse> execute() async {
    for (int i = 0; i < fallbacks.length; i++) {
      try {
        print('   Trying fallback ${i + 1}...');
        return await fallbacks[i]();
      } catch (e) {
        print('   Fallback ${i + 1} failed: $e');
        if (i == fallbacks.length - 1) {
          rethrow;
        }
      }
    }

    throw Exception('All fallbacks failed');
  }
}

/// Circuit breaker implementation
class CircuitBreaker {
  final int failureThreshold;
  final Duration timeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  CircuitBreaker({
    required this.failureThreshold,
    required this.timeout,
  });

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_isOpen) {
      if (_lastFailureTime != null &&
          DateTime.now().difference(_lastFailureTime!) > timeout) {
        _isOpen = false;
        _failureCount = 0;
        print('   🔄 Circuit breaker reset');
      } else {
        throw Exception('Circuit breaker is OPEN');
      }
    }

    try {
      final result = await operation();
      _failureCount = 0;
      return result;
    } catch (e) {
      _failureCount++;
      _lastFailureTime = DateTime.now();

      if (_failureCount >= failureThreshold) {
        _isOpen = true;
        print('   ⚡ Circuit breaker OPENED after $_failureCount failures');
      }

      rethrow;
    }
  }
}

/// AI service monitor for metrics collection
class AIServiceMonitor {
  final Map<String, int> _callCounts = {};
  final Map<String, int> _errorCounts = {};
  final Map<String, List<int>> _responseTimes = {};

  Future<T> trackCall<T>(
      String operationName, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      _recordSuccess(operationName, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordError(operationName);
      rethrow;
    }
  }

  void _recordSuccess(String operation, int responseTime) {
    _callCounts[operation] = (_callCounts[operation] ?? 0) + 1;
    _responseTimes[operation] = (_responseTimes[operation] ?? [])
      ..add(responseTime);
  }

  void _recordError(String operation) {
    _errorCounts[operation] = (_errorCounts[operation] ?? 0) + 1;
  }

  void displayMetrics() {
    print('   📈 Service Metrics:');

    for (final operation in _callCounts.keys) {
      final calls = _callCounts[operation] ?? 0;
      final errors = _errorCounts[operation] ?? 0;
      final times = _responseTimes[operation] ?? [];
      final avgTime =
          times.isNotEmpty ? times.reduce((a, b) => a + b) / times.length : 0;

      print('      $operation:');
      print('        • Total calls: $calls');
      print('        • Errors: $errors');
      print(
          '        • Success rate: ${((calls - errors) / calls * 100).toStringAsFixed(1)}%');
      print('        • Avg response time: ${avgTime.toStringAsFixed(1)}ms');
    }
  }
}

/// Simple chat response implementation
class SimpleChatResponse implements ChatResponse {
  final String _text;

  SimpleChatResponse(this._text);

  @override
  String? get text => _text;

  @override
  UsageInfo? get usage => null;

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata => null;

  @override
  CallMetadata? get callMetadata => null;
}

/// 🎯 Key Error Handling Concepts Summary:
///
/// Error Types:
/// - AuthError: Invalid API keys or permissions
/// - RateLimitError: Too many requests
/// - InvalidRequestError: Malformed requests
/// - HttpError: Network connectivity issues
/// - TimeoutError: Request timeouts
///
/// Retry Strategies:
/// - Immediate: Retry without delay
/// - Linear Backoff: Increasing delay linearly
/// - Exponential Backoff: Exponentially increasing delay
///
/// Resilience Patterns:
/// - Circuit Breaker: Prevent cascading failures
/// - Fallback: Alternative responses when primary fails
/// - Graceful Degradation: Reduced functionality instead of failure
///
/// Monitoring:
/// - Success/failure rates
/// - Response times
/// - Error categorization
/// - Performance metrics
///
/// Best Practices:
/// 1. Classify errors appropriately
/// 2. Implement appropriate retry strategies
/// 3. Use circuit breakers for external dependencies
/// 4. Provide meaningful fallbacks
/// 5. Monitor and log all operations
///
/// Next Steps:
/// - ../03_advanced_features/: Advanced AI capabilities
/// - ../04_providers/: Provider-specific features
/// - ../06_integration/: Production integration patterns
