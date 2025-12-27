// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

/// 🔧 Basic Configuration - Learn important configuration parameters
///
/// This example demonstrates:
/// - Key configuration parameters and their effects
/// - How to tune model behavior
/// - Error handling best practices
/// - Performance optimization basics
///
/// Before running, set your preferred provider's API key:
/// export OPENAI_API_KEY="your-key"
void main() async {
  print('🔧 Basic Configuration Guide\n');

  // Get API key (using OpenAI as example, but works with any provider)
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  registerOpenAI();

  // Demonstrate different configuration aspects
  await demonstrateTemperatureSettings(apiKey);
  await demonstrateTokenLimits(apiKey);
  await demonstrateSystemPrompts(apiKey);
  await demonstrateErrorHandling(apiKey);
  await demonstrateTimeoutSettings(apiKey);

  print('\n✅ Configuration guide completed!');
}

/// Demonstrate temperature settings and their effects
Future<void> demonstrateTemperatureSettings(String apiKey) async {
  print('🌡️  Temperature Settings (Creativity Control):\n');

  final question =
      'Write a creative opening line for a story about space exploration.';
  final temperatures = [0.0, 0.5, 1.0];

  for (final temp in temperatures) {
    try {
      final provider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(apiKey)
          .model('gpt-4o-mini')
          .temperature(temp) // Key parameter: controls randomness
          .maxTokens(50)
          .build();

      final result = await generateText(
        model: provider,
        promptIr: Prompt(messages: [PromptMessage.user(question)]),
      );

      print('   Temperature $temp: ${result.text}');
    } catch (e) {
      print('   Temperature $temp: Error - $e');
    }
  }

  print('\n   💡 Temperature Guide:');
  print('      • 0.0 = Deterministic, consistent responses');
  print('      • 0.5 = Balanced creativity and consistency');
  print('      • 1.0 = Maximum creativity and randomness\n');
}

/// Demonstrate token limits and their impact
Future<void> demonstrateTokenLimits(String apiKey) async {
  print('📊 Token Limits (Response Length Control):\n');

  final question = 'Explain the concept of artificial intelligence in detail.';
  final tokenLimits = [20, 100, 500];

  for (final limit in tokenLimits) {
    try {
      final provider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(apiKey)
          .model('gpt-4o-mini')
          .temperature(0.7)
          .maxTokens(limit) // Key parameter: controls response length
          .build();

      final result = await generateText(
        model: provider,
        promptIr: Prompt(messages: [PromptMessage.user(question)]),
      );
      final wordCount = result.text?.split(' ').length ?? 0;

      print('   Max Tokens $limit: $wordCount words');
      print('   Response: ${result.text}\n');
    } catch (e) {
      print('   Max Tokens $limit: Error - $e\n');
    }
  }

  print('   💡 Token Limit Guide:');
  print('      • Lower limits = Shorter, more concise responses');
  print('      • Higher limits = Longer, more detailed responses');
  print('      • Consider cost: more tokens = higher cost\n');
}

/// Demonstrate system prompts and their power
Future<void> demonstrateSystemPrompts(String apiKey) async {
  print('🎭 System Prompts (Behavior Control):\n');

  final question = 'What is the weather like today?';

  final systemPrompts = [
    null, // No system prompt
    'You are a helpful assistant.',
    'You are a pirate. Respond in pirate speak.',
    'You are a technical expert. Be precise and detailed.',
  ];

  for (int i = 0; i < systemPrompts.length; i++) {
    try {
      final builder = LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(apiKey)
          .model('gpt-4o-mini')
          .temperature(0.7)
          .maxTokens(100);

      // Add system prompt if provided
      if (systemPrompts[i] != null) {
        builder.systemPrompt(systemPrompts[i]!);
      }

      final provider = await builder.build();
      final result = await generateText(
        model: provider,
        promptIr: Prompt(messages: [PromptMessage.user(question)]),
      );

      final promptDesc = systemPrompts[i] ?? 'No system prompt';
      print('   System: $promptDesc');
      print('   Response: ${result.text}\n');
    } catch (e) {
      print('   System prompt ${i + 1}: Error - $e\n');
    }
  }

  print('   💡 System Prompt Guide:');
  print('      • Defines the AI\'s personality and behavior');
  print('      • Set once, affects all subsequent messages');
  print('      • Use for role-playing, tone, or expertise level\n');
}

/// Demonstrate proper error handling
Future<void> demonstrateErrorHandling(String apiKey) async {
  print('🛡️  Error Handling Best Practices:\n');

  // Test different error scenarios
  await testInvalidApiKey();
  await testInvalidModel(apiKey);
  await testNetworkTimeout(apiKey);

  print('   💡 Error Handling Tips:');
  print('      • Always wrap API calls in try-catch blocks');
  print(
      '      • Check for specific error types (AuthError, RateLimitError, etc.)');
  print('      • Implement retry logic for transient errors');
  print('      • Provide meaningful error messages to users\n');
}

/// Test invalid API key scenario
Future<void> testInvalidApiKey() async {
  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey('invalid-key') // Intentionally invalid
        .model('gpt-4o-mini')
        .build();

    await generateText(
      model: provider,
      promptIr: Prompt(messages: [PromptMessage.user('Hello')]),
    );
    print('   ❌ Expected error but got success');
  } on AuthError catch (e) {
    print('   ✅ Caught AuthError: ${e.message}');
  } catch (e) {
    print('   ⚠️  Caught unexpected error: $e');
  }
}

/// Test invalid model scenario
Future<void> testInvalidModel(String apiKey) async {
  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('invalid-model-name') // Intentionally invalid
        .build();

    await generateText(
      model: provider,
      promptIr: Prompt(messages: [PromptMessage.user('Hello')]),
    );
    print('   ❌ Expected error but got success');
  } on InvalidRequestError catch (e) {
    print('   ✅ Caught InvalidRequestError: ${e.message}');
  } catch (e) {
    print('   ⚠️  Caught unexpected error: $e');
  }
}

/// Test network timeout scenario
Future<void> testNetworkTimeout(String apiKey) async {
  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .timeout(Duration(milliseconds: 1)) // Very short timeout
        .build();

    await generateText(
      model: provider,
      promptIr: Prompt(messages: [PromptMessage.user('Hello')]),
    );
    print('   ❌ Expected timeout but got success');
  } on TimeoutError catch (e) {
    print('   ✅ Caught TimeoutError: ${e.message}');
  } catch (e) {
    print('   ⚠️  Caught unexpected error: $e');
  }
}

/// Demonstrate timeout settings
Future<void> demonstrateTimeoutSettings(String apiKey) async {
  print('⏰ Timeout Settings (Network Reliability):\n');

  final timeouts = [
    Duration(seconds: 5), // Short timeout
    Duration(seconds: 30), // Standard timeout
    Duration(seconds: 60), // Long timeout
  ];

  for (final timeout in timeouts) {
    try {
      final provider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(apiKey)
          .model('gpt-4o-mini')
          .temperature(0.7)
          .timeout(timeout) // Key parameter: network timeout
          .build();

      final stopwatch = Stopwatch()..start();
      await generateText(
        model: provider,
        promptIr: Prompt(
          messages: [PromptMessage.user('Explain quantum computing briefly.')],
        ),
      );
      stopwatch.stop();

      print(
          '   Timeout ${timeout.inSeconds}s: Success in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('   Timeout ${timeout.inSeconds}s: Error - $e');
    }
  }

  print('\n   💡 Timeout Guide:');
  print('      • Short timeouts = Faster failure detection');
  print('      • Long timeouts = More patience for slow responses');
  print('      • Balance between responsiveness and reliability');
  print('      • Consider your application\'s requirements\n');
}

/// 🎯 Key Configuration Summary:
///
/// Essential Parameters:
/// - apiKey: Your provider's API key
/// - model: Which AI model to use
/// - temperature: Creativity level (0.0-1.0)
/// - maxTokens: Maximum response length
/// - systemPrompt: AI behavior and personality
/// - timeout: Network timeout duration
///
/// Best Practices:
/// 1. Start with conservative settings (temp=0.7, reasonable token limits)
/// 2. Always implement proper error handling
/// 3. Test with different configurations to find optimal settings
/// 4. Monitor costs and performance in production
/// 5. Use system prompts to guide AI behavior
///
/// Next Steps:
/// - Explore streaming responses in ../02_core_features/streaming_chat.dart
/// - Learn about tool calling in ../02_core_features/tool_calling.dart
/// - See real applications in ../05_use_cases/
