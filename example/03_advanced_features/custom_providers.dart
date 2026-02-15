// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';

import 'package:llm_dart_core/llm_dart_core.dart';

/// 🔧 Custom Providers - Build Your Own AI Providers
///
/// This example demonstrates how to create custom AI providers:
/// - Implementing the ChatCapability interface
/// - Adding custom functionality and behavior
/// - Integration with existing LLM Dart patterns
/// - Testing and validation strategies
///
/// Use cases for custom providers:
/// - Mock providers for testing
/// - Local model integration
/// - Custom API wrappers
/// - Specialized AI services
void main() async {
  print('🔧 Custom Providers - Build Your Own AI Providers\n');

  // Demonstrate different custom provider scenarios
  await demonstrateMockProvider();
  await demonstrateLoggingProvider();
  await demonstrateCachingProvider();
  await demonstrateCustomAPIProvider();
  await demonstrateProviderChaining();

  print('\n✅ Custom providers completed!');
}

/// Demonstrate a mock provider for testing
Future<void> demonstrateMockProvider() async {
  print('🎭 Mock Provider for Testing:\n');

  try {
    // Create mock provider
    final mockProvider = MockChatProvider();

    // Test basic chat
    final response =
        await mockProvider.chat([ChatMessage.user('Hello, how are you?')]);

    print('   User: Hello, how are you?');
    print('   🤖 Mock AI: ${response.text}');

    // Test streaming
    print('\n   Streaming test:');
    print('   🤖 Mock AI: ');

    await for (final part
        in mockProvider.chatStreamParts([ChatMessage.user('Count to 5')])) {
      switch (part) {
        case LLMTextDeltaPart(delta: final delta):
          stdout.write(delta);
          break;
        case LLMFinishPart():
          print('\n');
          break;
        case LLMErrorPart(error: final error):
          print('Error: $error');
          break;
        default:
          break;
      }
    }

    print('   💡 Mock Provider Benefits:');
    print('      • Predictable responses for testing');
    print('      • No API costs during development');
    print('      • Fast execution for unit tests');
    print('      • Controllable behavior and errors');
    print('   ✅ Mock provider demonstration successful\n');
  } catch (e) {
    print('   ❌ Mock provider failed: $e\n');
  }
}

/// Demonstrate a logging provider wrapper
Future<void> demonstrateLoggingProvider() async {
  print('📝 Logging Provider Wrapper:\n');

  try {
    // Create base provider (mock for demo)
    final baseProvider = MockChatProvider();

    // Wrap with logging
    final loggingProvider = LoggingChatProvider(baseProvider);

    // Test with logging
    final response = await loggingProvider
        .chat([ChatMessage.user('What is artificial intelligence?')]);

    print('   User: What is artificial intelligence?');
    print('   🤖 AI: ${response.text}');

    print('\n   💡 Logging Provider Features:');
    print('      • Automatic request/response logging');
    print('      • Performance metrics collection');
    print('      • Error tracking and debugging');
    print('      • Transparent wrapper pattern');
    print('   ✅ Logging provider demonstration successful\n');
  } catch (e) {
    print('   ❌ Logging provider failed: $e\n');
  }
}

/// Demonstrate a caching provider
Future<void> demonstrateCachingProvider() async {
  print('💾 Caching Provider:\n');

  try {
    // Create base provider
    final baseProvider = MockChatProvider();

    // Wrap with caching
    final cachingProvider = CachingChatProvider(baseProvider);

    final question = 'What is the capital of France?';

    // First call - cache miss
    print('   First call (cache miss):');
    final stopwatch1 = Stopwatch()..start();
    final response1 = await cachingProvider.chat([ChatMessage.user(question)]);
    stopwatch1.stop();
    print('   🤖 AI: ${response1.text}');
    print('   ⏱️  Time: ${stopwatch1.elapsedMilliseconds}ms');

    // Second call - cache hit
    print('\n   Second call (cache hit):');
    final stopwatch2 = Stopwatch()..start();
    final response2 = await cachingProvider.chat([ChatMessage.user(question)]);
    stopwatch2.stop();
    print('   🤖 AI: ${response2.text}');
    print('   ⏱️  Time: ${stopwatch2.elapsedMilliseconds}ms');

    print('\n   💡 Caching Provider Benefits:');
    print('      • Faster responses for repeated queries');
    print('      • Reduced API costs');
    print('      • Better user experience');
    print('      • Configurable cache policies');
    print('   ✅ Caching provider demonstration successful\n');
  } catch (e) {
    print('   ❌ Caching provider failed: $e\n');
  }
}

/// Demonstrate custom API provider
Future<void> demonstrateCustomAPIProvider() async {
  print('🌐 Custom API Provider:\n');

  try {
    // Create custom API provider
    final customProvider = CustomAPIProvider(
      baseUrl: 'https://api.example.com',
      apiKey: 'custom-api-key',
      model: 'custom-model-v1',
    );

    // Test custom provider
    final response = await customProvider
        .chat([ChatMessage.user('Hello from custom provider!')]);

    print('   User: Hello from custom provider!');
    print('   🤖 Custom AI: ${response.text}');

    print('\n   💡 Custom API Provider Features:');
    print('      • Integration with proprietary APIs');
    print('      • Custom authentication methods');
    print('      • Specialized model configurations');
    print('      • Domain-specific optimizations');
    print('   ✅ Custom API provider demonstration successful\n');
  } catch (e) {
    print('   ❌ Custom API provider failed: $e\n');
  }
}

/// Demonstrate provider chaining
Future<void> demonstrateProviderChaining() async {
  print('🔗 Provider Chaining:\n');

  try {
    // Create base provider
    final baseProvider = MockChatProvider();

    // Chain multiple wrappers
    final chainedProvider =
        LoggingChatProvider(CachingChatProvider(baseProvider));

    // Test chained provider
    final response = await chainedProvider
        .chat([ChatMessage.user('Test chained providers')]);

    print('   User: Test chained providers');
    print('   🤖 Chained AI: ${response.text}');

    print('\n   💡 Provider Chaining Benefits:');
    print('      • Composable functionality');
    print('      • Separation of concerns');
    print('      • Reusable components');
    print('      • Flexible architecture');
    print('   ✅ Provider chaining demonstration successful\n');
  } catch (e) {
    print('   ❌ Provider chaining failed: $e\n');
  }
}

/// Mock chat provider for testing
class MockChatProvider implements ChatCapability, ChatStreamPartsCapability {
  final Random _random = Random();

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    // Simulate API delay
    await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(200)));

    final userMessage = messages.lastWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => ChatMessage.user(''),
    );

    // Generate mock response based on user input
    final response = _generateMockResponse(userMessage.content.toString());

    return MockChatResponse(
      text: response,
      usage: MockUsage(
        promptTokens: 10 + _random.nextInt(20),
        completionTokens: 20 + _random.nextInt(30),
      ),
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final userMessage = messages.lastWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => ChatMessage.user(''),
    );

    final response = _generateMockResponse(userMessage.content.toString());
    final words = response.split(' ');

    yield const LLMStreamStartPart();
    yield const LLMTextStartPart();

    // Stream words with delays
    for (final word in words) {
      await Future.delayed(Duration(milliseconds: 50 + _random.nextInt(100)));
      yield LLMTextDeltaPart('$word ');
    }

    yield LLMTextEndPart(response);
    yield LLMFinishPart(
      MockChatResponse(
        text: response,
        usage: MockUsage(
          promptTokens: 10 + _random.nextInt(20),
          completionTokens: words.length,
        ),
      ),
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return chat(messages, cancelToken: cancelToken); // Simple implementation
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return 'Mock summary of ${messages.length} messages';
  }

  String _generateMockResponse(String input) {
    final responses = [
      'This is a mock response to: $input',
      'Mock AI here! You said: $input',
      'Simulated response for testing purposes.',
      'Hello! This is a predictable mock response.',
      'Mock provider responding to your message.',
    ];
    return responses[_random.nextInt(responses.length)];
  }
}

/// Logging wrapper provider
class LoggingChatProvider implements ChatCapability, ChatStreamPartsCapability {
  final ChatCapability _baseProvider;

  LoggingChatProvider(this._baseProvider);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    final stopwatch = Stopwatch()..start();

    print('   📝 [LOG] Starting chat request with ${messages.length} messages');

    try {
      final response =
          await _baseProvider.chat(messages, cancelToken: cancelToken);
      stopwatch.stop();

      print('   📝 [LOG] Chat completed in ${stopwatch.elapsedMilliseconds}ms');
      if (response.usage != null) {
        print('   📝 [LOG] Token usage: ${response.usage!.totalTokens}');
      }

      return response;
    } catch (e) {
      stopwatch.stop();
      print(
          '   📝 [LOG] Chat failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    print('   📝 [LOG] Starting streaming chat request');

    final partsCap = _baseProvider is ChatStreamPartsCapability
        ? _baseProvider as ChatStreamPartsCapability
        : null;
    if (partsCap == null) {
      throw UnsupportedError(
        'Base provider does not support ChatStreamPartsCapability',
      );
    }

    await for (final part in partsCap.chatStreamParts(
      messages,
      providerTools: providerTools,
      tools: tools,
      cancelToken: cancelToken,
    )) {
      switch (part) {
        case LLMTextDeltaPart():
          print('   📝 [LOG] Text delta received');
          break;
        case LLMToolCallStartPart():
          print('   📝 [LOG] Tool call started');
          break;
        case LLMFinishPart():
          print('   📝 [LOG] Stream finished');
          break;
        case LLMErrorPart():
          print('   📝 [LOG] Stream error occurred');
          break;
        default:
          break;
      }
      yield part;
    }
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    print('   📝 [LOG] Chat with ${tools?.length ?? 0} tools');
    return _baseProvider.chatWithTools(messages, tools,
        cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    print('   📝 [LOG] Getting memory contents');
    return _baseProvider.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    print('   📝 [LOG] Summarizing ${messages.length} messages');
    return _baseProvider.summarizeHistory(messages);
  }
}

/// Caching wrapper provider
class CachingChatProvider implements ChatCapability, ChatStreamPartsCapability {
  final ChatCapability _baseProvider;
  final Map<String, ChatResponse> _cache = {};

  CachingChatProvider(this._baseProvider);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = _generateCacheKey(messages);

    if (_cache.containsKey(cacheKey)) {
      print('   💾 [CACHE] Cache hit for request');
      return _cache[cacheKey]!;
    }

    print('   💾 [CACHE] Cache miss, calling base provider');
    final response =
        await _baseProvider.chat(messages, cancelToken: cancelToken);
    _cache[cacheKey] = response;

    return response;
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    // For simplicity, streaming bypasses cache
    final partsCap = _baseProvider is ChatStreamPartsCapability
        ? _baseProvider as ChatStreamPartsCapability
        : null;
    if (partsCap == null) {
      throw UnsupportedError(
        'Base provider does not support ChatStreamPartsCapability',
      );
    }
    return partsCap.chatStreamParts(
      messages,
      providerTools: providerTools,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    // Tools bypass cache for safety
    return _baseProvider.chatWithTools(messages, tools,
        cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _baseProvider.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _baseProvider.summarizeHistory(messages);
  }

  String _generateCacheKey(List<ChatMessage> messages) {
    return messages.map((m) => '${m.role}:${m.content}').join('|');
  }
}

/// Custom API provider example
class CustomAPIProvider implements ChatCapability, ChatStreamPartsCapability {
  final String baseUrl;
  final String apiKey;
  final String model;

  CustomAPIProvider({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    // Simulate custom API call
    await Future.delayed(Duration(milliseconds: 300));

    return MockChatResponse(
      text: 'Response from custom API at $baseUrl using model $model',
      usage: MockUsage(promptTokens: 15, completionTokens: 25),
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final response = await chat(messages, cancelToken: cancelToken);
    final text = response.text ?? '';

    yield const LLMStreamStartPart();
    yield const LLMTextStartPart();
    yield LLMTextDeltaPart(text);
    yield LLMTextEndPart(text);
    yield LLMFinishPart(response);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    return chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return 'Custom API summary of ${messages.length} messages';
  }
}

/// Mock implementations for testing
class MockChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final UsageInfo? usage;

  @override
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final Map<String, dynamic>? providerMetadata;

  MockChatResponse({
    required this.text,
    this.usage,
    this.thinking,
    this.toolCalls,
    this.providerMetadata,
  });
}

class MockUsage extends UsageInfo {
  MockUsage({
    required int promptTokens,
    required int completionTokens,
  }) : super(
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          totalTokens: promptTokens + completionTokens,
        );
}

/// 🎯 Key Custom Provider Concepts Summary:
///
/// Provider Interface:
/// - ChatCapability: Core interface to implement
/// - chat(): Single request/response
/// - ChatStreamPartsCapability: Parts-first streaming interface
/// - chatStreamParts(): Streaming responses as structured parts
/// - chatWithTools(): Tool-enabled chat
///
/// Implementation Patterns:
/// - Mock providers: Testing and development
/// - Wrapper providers: Add functionality to existing providers
/// - Custom API providers: Integrate proprietary services
/// - Chained providers: Compose multiple behaviors
///
/// Common Use Cases:
/// - Testing and mocking
/// - Logging and monitoring
/// - Caching and optimization
/// - Custom API integration
/// - Rate limiting and throttling
///
/// Best Practices:
/// 1. Implement all required interface methods
/// 2. Handle errors gracefully
/// 3. Maintain consistent behavior
/// 4. Document custom functionality
/// 5. Test thoroughly with edge cases
///
/// Advanced Patterns:
/// - Provider factories for configuration
/// - Async initialization and cleanup
/// - Health checks and monitoring
/// - Fallback and retry logic
///
/// Next Steps:
/// - performance_optimization.dart: Production optimization
/// - ../02_core_features/error_handling.dart: Robust error handling
/// - ../06_integration/: Production integration patterns
