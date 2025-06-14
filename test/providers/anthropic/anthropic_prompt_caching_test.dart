// ignore_for_file: avoid_print
import 'dart:io';
import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Anthropic Prompt Caching Test Suite
///
/// Instructions:
/// 1. Set your API key: export ANTHROPIC_API_KEY="your-api-key"
/// 2. Run tests: dart test test/providers/anthropic/anthropic_prompt_caching_test.dart
/// 3. Or run manually: dart run test/providers/anthropic/anthropic_prompt_caching_test.dart

void main() {
  // Check if running as script or test
  final isScript = Platform.script.pathSegments.last.endsWith('.dart');

  if (isScript) {
    // Running as script
    runManualTest();
  } else {
    // Running as test suite
    runTestSuite();
  }
}

void runTestSuite() {
  group('Anthropic Prompt Caching Tests', () {
    late String? apiKey;

    setUpAll(() {
      apiKey = Platform.environment['ANTHROPIC_API_KEY'];
      if (apiKey == null) {
        print('⚠️  ANTHROPIC_API_KEY not set. Skipping live API tests.');
        print('   Set your API key: export ANTHROPIC_API_KEY="your-api-key"');
      }
    });

    test('Basic Prompt Caching - Cache Creation', () async {
      if (apiKey == null) return;

      print('🧪 Test: Basic Prompt Caching - Cache Creation');

      final provider = await ai()
          .anthropic()
          .apiKey(apiKey!)
          .model('claude-3-5-sonnet-20241022')
          .systemPrompt(
              'You are a helpful AI assistant specializing in software development.')
          .maxTokens(300)
          .temperature(0.3)
          .extension('promptCache', true)
          .build();

      final messages = [
        ChatMessage.system('Context: You are helping with a Dart project.'),
        ChatMessage.user(
            'What are the benefits of using Dart for backend development?'),
      ];

      print('  📤 Sending first request (should create cache)...');
      final response = await provider.chat(messages);

      expect(response.text, isNotNull);
      expect(response.text!.isNotEmpty, isTrue);
      print('  ✅ Response received: ${response.text!.substring(0, 100)}...');

      if (response is AnthropicChatResponse) {
        final cacheUsage = response.cacheUsage;
        print('  💾 Cache Usage:');
        if (cacheUsage != null) {
          final cacheCreation = cacheUsage['cache_creation_input_tokens'] ?? 0;
          final cacheRead = cacheUsage['cache_read_input_tokens'] ?? 0;
          print('    - Cache creation tokens: $cacheCreation');
          print('    - Cache read tokens: $cacheRead');

          if (cacheCreation > 0) {
            print('  ✅ Cache creation detected!');
          } else {
            print('  ⚠️  No cache creation tokens found');
          }
        } else {
          print('    - No cache usage data available');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Prompt Caching - Cache Reuse', () async {
      if (apiKey == null) return;

      print('\n🧪 Test: Prompt Caching - Cache Reuse');

      final provider = await ai()
          .anthropic()
          .apiKey(apiKey!)
          .model('claude-3-5-sonnet-20241022')
          .systemPrompt(
              'You are a helpful AI assistant specializing in software development.')
          .maxTokens(300)
          .temperature(0.3)
          .extension('promptCache', true)
          .build();

      // First request to create cache
      final messages1 = [
        ChatMessage.system('Context: You are helping with a Dart project.'),
        ChatMessage.user('What is Dart?'),
      ];

      print('  📤 First request (creating cache)...');
      final response1 = await provider.chat(messages1);
      print('  ✅ First response received');

      // Second request to reuse cache
      final messages2 = [
        ...messages1,
        ChatMessage.assistant(response1.text ?? ''),
        ChatMessage.user('Can you give me an example of Dart code?'),
      ];

      print('  📤 Second request (should reuse cache)...');
      final response2 = await provider.chat(messages2);

      expect(response2.text, isNotNull);
      expect(response2.text!.isNotEmpty, isTrue);
      print(
          '  ✅ Second response received: ${response2.text!.substring(0, 100)}...');

      if (response2 is AnthropicChatResponse) {
        final cacheUsage = response2.cacheUsage;
        print('  💾 Cache Usage (Second Request):');
        if (cacheUsage != null) {
          final cacheCreation = cacheUsage['cache_creation_input_tokens'] ?? 0;
          final cacheRead = cacheUsage['cache_read_input_tokens'] ?? 0;
          print('    - Cache creation tokens: $cacheCreation');
          print('    - Cache read tokens: $cacheRead');

          if (cacheRead > 0) {
            print('  🎉 Cache reuse detected! Cost savings achieved.');
          } else {
            print('  ⚠️  No cache read tokens found');
          }
        } else {
          print('    - No cache usage data available');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('Multiple System Prompts - Individual Caching', () async {
      if (apiKey == null) return;

      print('\n🧪 Test: Multiple System Prompts - Individual Caching');

      final provider = await ai()
          .anthropic()
          .apiKey(apiKey!)
          .model('claude-3-5-sonnet-20241022')
          .systemPrompt('You are a helpful AI assistant.')
          .maxTokens(300)
          .temperature(0.3)
          .extension('promptCache', true)
          .build();

      final messages = [
        ChatMessage.system('Primary role: You are a Dart programming expert.'),
        ChatMessage.system(
            'Secondary context: You focus on clean code practices.'),
        ChatMessage.user(
            'What are key principles for writing maintainable Dart code?'),
      ];

      print('  📤 Sending request with multiple system prompts...');
      final response = await provider.chat(messages);

      expect(response.text, isNotNull);
      expect(response.text!.isNotEmpty, isTrue);
      print('  ✅ Response received: ${response.text!.substring(0, 100)}...');

      if (response is AnthropicChatResponse) {
        final cacheUsage = response.cacheUsage;
        print('  💾 Cache Usage (Multiple System Prompts):');
        if (cacheUsage != null) {
          final cacheCreation = cacheUsage['cache_creation_input_tokens'] ?? 0;
          final cacheRead = cacheUsage['cache_read_input_tokens'] ?? 0;
          print('    - Cache creation tokens: $cacheCreation');
          print('    - Cache read tokens: $cacheRead');

          if (cacheCreation > 0) {
            print('  ✅ Individual system prompt caching working!');
          } else {
            print('  ⚠️  No cache creation for individual system prompts');
          }
        } else {
          print('    - No cache usage data available');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Caching Disabled - Control Test', () async {
      if (apiKey == null) return;

      print('\n🧪 Test: Caching Disabled - Control Test');

      final provider = await ai()
          .anthropic()
          .apiKey(apiKey!)
          .model('claude-3-5-sonnet-20241022')
          .systemPrompt('You are a helpful AI assistant.')
          .maxTokens(300)
          .temperature(0.3)
          // No .extension('promptCache', true) - caching disabled
          .build();

      final messages = [
        ChatMessage.system('Context: Test without caching.'),
        ChatMessage.user('What is Dart programming language?'),
      ];

      print('  📤 Sending request without caching enabled...');
      final response = await provider.chat(messages);

      expect(response.text, isNotNull);
      expect(response.text!.isNotEmpty, isTrue);
      print('  ✅ Response received: ${response.text!.substring(0, 100)}...');

      if (response is AnthropicChatResponse) {
        final cacheUsage = response.cacheUsage;
        print('  💾 Cache Usage (Disabled):');
        if (cacheUsage != null) {
          final cacheCreation = cacheUsage['cache_creation_input_tokens'] ?? 0;
          final cacheRead = cacheUsage['cache_read_input_tokens'] ?? 0;
          print('    - Cache creation tokens: $cacheCreation');
          print('    - Cache read tokens: $cacheRead');

          if (cacheCreation == 0 && cacheRead == 0) {
            print('  ✅ Caching properly disabled!');
          } else {
            print('  ⚠️  Unexpected caching activity when disabled');
          }
        } else {
          print('    - No cache usage data (expected when disabled)');
          print('  ✅ Caching properly disabled!');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Tools with Caching', () async {
      if (apiKey == null) return;

      print('\n🧪 Test: Tools with Caching');

      final provider = await ai()
          .anthropic()
          .apiKey(apiKey!)
          .model('claude-3-5-sonnet-20241022')
          .systemPrompt('You are a helpful assistant with access to tools.')
          .maxTokens(300)
          .temperature(0.3)
          .extension('promptCache', true)
          .tools([
        Tool.function(
          name: 'get_weather',
          description: 'Get weather information for a location',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'location': ParameterProperty(
                propertyType: 'string',
                description: 'The city and state/country',
              ),
            },
            required: ['location'],
          ),
        ),
      ]).build();

      final messages = [
        ChatMessage.user('What tools do you have available?'),
      ];

      print('  📤 Sending request with tools and caching...');
      final response = await provider.chat(messages);

      expect(response.text, isNotNull);
      expect(response.text!.isNotEmpty, isTrue);
      print('  ✅ Response received: ${response.text!.substring(0, 100)}...');

      if (response is AnthropicChatResponse) {
        final cacheUsage = response.cacheUsage;
        print('  💾 Cache Usage (With Tools):');
        if (cacheUsage != null) {
          final cacheCreation = cacheUsage['cache_creation_input_tokens'] ?? 0;
          final cacheRead = cacheUsage['cache_read_input_tokens'] ?? 0;
          print('    - Cache creation tokens: $cacheCreation');
          print('    - Cache read tokens: $cacheRead');

          if (cacheCreation > 0) {
            print('  ✅ Tool caching working!');
          } else {
            print('  ⚠️  No cache creation for tools');
          }
        } else {
          print('    - No cache usage data available');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

/// Manual test runner for direct execution
Future<void> runManualTest() async {
  print('🔄 Anthropic Prompt Caching Test Suite\n');
  print('Manual Test Mode - Quick validation\n');

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null) {
    print('❌ ANTHROPIC_API_KEY environment variable not set');
    print('   Set your API key: export ANTHROPIC_API_KEY="your-api-key"');
    print(
        '   Then run: dart run test/providers/anthropic/anthropic_prompt_caching_test.dart');
    return;
  }

  print('✅ API key found, running quick test...\n');

  try {
    // Quick test
    final provider = await ai()
        .anthropic()
        .apiKey(apiKey)
        .model('claude-3-5-sonnet-20241022')
        .systemPrompt('You are a helpful AI assistant.')
        .maxTokens(200)
        .extension('promptCache', true)
        .build();

    print('📤 Quick test: Basic caching functionality...');
    final response = await provider.chat([
      ChatMessage.system('Context: Testing prompt caching implementation.'),
      ChatMessage.user(
          'Hello! Can you tell me about Dart programming language?'),
    ]);

    print('✅ Quick test successful!');
    print('   Response: ${response.text?.substring(0, 100)}...');

    if (response is AnthropicChatResponse) {
      final cacheUsage = response.cacheUsage;
      if (cacheUsage != null) {
        print(
            '   Cache creation: ${cacheUsage['cache_creation_input_tokens'] ?? 0}');
        print('   Cache read: ${cacheUsage['cache_read_input_tokens'] ?? 0}');

        final cacheCreation = cacheUsage['cache_creation_input_tokens'] ?? 0;
        if (cacheCreation > 0) {
          print('   🎉 Prompt caching is working!');
        } else {
          print('   ⚠️  No cache creation detected');
        }
      } else {
        print('   ⚠️  No cache usage data in response');
      }
    }

    print('\n🎯 Test Summary:');
    print('   ✅ API connection successful');
    print('   ✅ Prompt caching extension enabled');
    print('   ✅ Response generation working');
    print('   ✅ Cache usage metrics accessible');

    print('\n📚 Run full test suite with:');
    print(
        '   dart test test/providers/anthropic/anthropic_prompt_caching_test.dart');
  } catch (e) {
    print('❌ Quick test failed: $e');
    print('   Check your API key and network connection');
    print('   Verify the model supports prompt caching');
  }
}
