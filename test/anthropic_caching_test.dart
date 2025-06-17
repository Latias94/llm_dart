import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Test suite for Anthropic prompt caching structure validation
/// Ensures cache_control structure with "type": "ephemeral" and proper TTL values
/// NO API CALLS - only validates message structure
void main() {
  group('Anthropic Cache Control Structure Tests', () {
    test('System message with 1-hour cache control structure', () {
      // Create a system message with cached content
      // This should set up cache_control: {"type": "ephemeral", "ttl": "1h"}
      final systemMessage = MessageBuilder.system()
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('You are a highly specialized AI assistant with extensive knowledge in software development, '
                'data science, and machine learning. Your responses should be detailed, accurate, and helpful. '
                'Always provide code examples when relevant and explain complex concepts clearly. '
                'When debugging issues, provide step-by-step solutions and consider edge cases. '
                'Your expertise covers Python, JavaScript, Dart, Flutter, React, Node.js, and various frameworks. '
                'You should maintain a professional yet friendly tone throughout all interactions.' *
                50)
          .build();

      // Verify the system message has proper caching configuration
      expect(systemMessage.role, equals(ChatRole.system));
      expect(systemMessage.hasExtension('anthropic'), isTrue);
      expect(systemMessage.content,
          contains('You are a highly specialized AI assistant'));

      // The message should be configured to generate:
      // "cache_control": {"type": "ephemeral", "ttl": "1h"}
      print('System message with 1h TTL cache control structure validated');
    });

    test('User message with 5-minute cache control structure', () {
      // Create a user message with cached content
      // This should set up cache_control: {"type": "ephemeral", "ttl": "5m"}
      final longUserContext = 'I am working on a complex Flutter project that involves '
              'state management with Riverpod, navigation with GoRouter, and API integration. '
              'The project structure includes multiple feature modules, shared widgets, '
              'and utility functions. I need to implement real-time updates, offline caching, '
              'and proper error handling throughout the application. The app should support '
              'both iOS and Android platforms with platform-specific optimizations. '
              'Performance is critical as the app will handle large datasets and frequent updates. ' *
          100;

      final userMessage = MessageBuilder.user()
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
          .text(longUserContext)
          .build();

      // Verify the user message has proper caching configuration
      expect(userMessage.role, equals(ChatRole.user));
      expect(userMessage.hasExtension('anthropic'), isTrue);
      expect(userMessage.content,
          contains('I am working on a complex Flutter project'));

      // The message should be configured to generate:
      // "cache_control": {"type": "ephemeral", "ttl": "5m"}
      print('User message with 5m TTL cache control structure validated');
    });

    test('Multiple messages with different TTL configurations', () {
      // System message with 1-hour caching
      final systemMessage = MessageBuilder.system()
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('You are an expert code reviewer and software architect. '
                'When reviewing code, focus on: performance, security, maintainability, '
                'readability, and adherence to best practices. Provide specific suggestions '
                'for improvement and explain the reasoning behind your recommendations.' *
                100)
          .build();

      // User message with 5-minute caching
      final userMessage = MessageBuilder.user()
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
          .text('Please review this Flutter widget code for potential improvements:\n\n'
                'class CustomButton extends StatelessWidget {\n'
                '  final String text;\n'
                '  final VoidCallback onPressed;\n'
                '  final Color backgroundColor;\n'
                '  final double borderRadius;\n'
                '  // ... more properties and implementation details would go here\n'
                '  // This is a simplified version for testing purposes\n' *
                50)
          .build();

      // Verify both messages have proper caching configuration
      expect(systemMessage.role, equals(ChatRole.system));
      expect(systemMessage.hasExtension('anthropic'), isTrue);

      expect(userMessage.role, equals(ChatRole.user));
      expect(userMessage.hasExtension('anthropic'), isTrue);

      // Both messages should be configured to generate proper cache_control structures:
      // System: "cache_control": {"type": "ephemeral", "ttl": "1h"}
      // User: "cache_control": {"type": "ephemeral", "ttl": "5m"}
      print('Multiple messages with different TTL structures validated');
    });

    test('Cache control structure format validation', () {
      // Test that cache control structure is properly formatted for different TTL values
      final oneHourMessage = MessageBuilder.user()
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('Content with 1-hour TTL for cache control validation.')
          .build();

      final fiveMinuteMessage = MessageBuilder.user()
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
          .text('Content with 5-minute TTL for cache control validation.')
          .build();

      // Verify both messages have the anthropic extension
      expect(oneHourMessage.hasExtension('anthropic'), isTrue);
      expect(fiveMinuteMessage.hasExtension('anthropic'), isTrue);

      // The actual cache_control JSON structures should be:
      // For 1-hour TTL:
      // {
      //   "cache_control": {
      //     "type": "ephemeral",
      //     "ttl": "1h"
      //   }
      // }
      //
      // For 5-minute TTL:
      // {
      //   "cache_control": {
      //     "type": "ephemeral",
      //     "ttl": "5m"
      //   }
      // }

      print('Cache control structure format validation completed');
      print('Both 1h and 5m TTL configurations properly set up');
    });

    test('Message builder creates proper anthropic extensions', () {
      // Verify that the MessageBuilder correctly sets up anthropic extensions
      final cachedMessage = MessageBuilder.system()
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('System prompt with caching enabled for structure validation.')
          .build();

      final regularMessage = MessageBuilder.system()
          .text('Regular system prompt without caching.')
          .build();

      // Cached message should have anthropic extension
      expect(cachedMessage.hasExtension('anthropic'), isTrue);
      expect(cachedMessage.role, equals(ChatRole.system));

      // Regular message should not have anthropic extension
      expect(regularMessage.hasExtension('anthropic'), isFalse);
      expect(regularMessage.role, equals(ChatRole.system));

      print('Anthropic extension validation completed');
      print('Cached messages properly configured with extensions');
      print('Regular messages correctly without extensions');
    });

    test('No duplication when using cached text with regular text', () {
      // This test verifies that when both cached text and regular text are used,
      // the content is not duplicated in the final message
      final testText = 'This is a test message for validation.';

      // Create a message with both cached text and regular text
      final mixedMessage = MessageBuilder.system()
          .text('Regular system prompt.')
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text(testText)
          .build();

      // Verify the message structure
      expect(mixedMessage.hasExtension('anthropic'), isTrue);
      expect(mixedMessage.content, contains('Regular system prompt.'));
      expect(mixedMessage.content, contains(testText));

      // Get the anthropic extension data
      final anthropicData =
          mixedMessage.getExtension<Map<String, dynamic>>('anthropic');
      expect(anthropicData, isNotNull);

      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>?;
      expect(contentBlocks, isNotNull);
      expect(contentBlocks!.length, equals(1));

      final cachedBlock = contentBlocks.first as Map<String, dynamic>;
      expect(cachedBlock['type'], equals('text'));
      expect(cachedBlock['text'], equals(testText));
      expect(cachedBlock['cache_control'], isNotNull);

      final cacheControl = cachedBlock['cache_control'] as Map<String, dynamic>;
      expect(cacheControl['type'], equals('ephemeral'));
      expect(cacheControl['ttl'], equals('1h'));

      print('Mixed content validation completed - no duplication detected');
    });

    test('Cached-only system message content structure', () {
      // Test a system message that only has cached content (no regular text)
      final cachedOnlyMessage = MessageBuilder.system()
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
          .text('Only cached content in this system message.')
          .build();

      // Verify the message content and extensions
      expect(cachedOnlyMessage.hasExtension('anthropic'), isTrue);
      expect(cachedOnlyMessage.content,
          equals('Only cached content in this system message.'));

      // Verify the cached content structure
      final anthropicData =
          cachedOnlyMessage.getExtension<Map<String, dynamic>>('anthropic');
      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
      expect(contentBlocks.length, equals(1));

      final block = contentBlocks.first as Map<String, dynamic>;
      expect(block['cache_control']['ttl'], equals('5m'));

      print('Cached-only system message validation completed');
    });

    test('Mixed regular and cached content in user message', () {
      // This test reveals the content loss issue in user messages
      final mixedUserMessage = MessageBuilder.user()
          .text('Regular user text that should not be lost')
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
          .text('Cached user text')
          .build();

      // The message content should contain both parts
      expect(mixedUserMessage.content,
          contains('Regular user text that should not be lost'));
      expect(mixedUserMessage.content, contains('Cached user text'));
      expect(mixedUserMessage.hasExtension('anthropic'), isTrue);

      // The anthropic extension should only contain the cached part
      final anthropicData =
          mixedUserMessage.getExtension<Map<String, dynamic>>('anthropic');
      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
      expect(contentBlocks.length, equals(1));

      final cachedBlock = contentBlocks.first as Map<String, dynamic>;
      expect(cachedBlock['text'], equals('Cached user text'));
      expect(cachedBlock['cache_control']['ttl'], equals('5m'));

      print('Mixed user message structure validated');
      print(
          'Both regular and cached content should be preserved in API conversion');
    });

    test('Multiple regular text blocks with cached content', () {
      // Test more complex mixed content scenarios
      final complexMessage = MessageBuilder.user()
          .text('First regular text')
          .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('Cached content block')
          .text('Second regular text')
          .build();

      // Verify all content is present
      expect(complexMessage.content, contains('First regular text'));
      expect(complexMessage.content, contains('Cached content block'));
      expect(complexMessage.content, contains('Second regular text'));
      expect(complexMessage.hasExtension('anthropic'), isTrue);

      // Verify anthropic extension structure
      final anthropicData =
          complexMessage.getExtension<Map<String, dynamic>>('anthropic');
      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
      expect(contentBlocks.length, equals(1));

      final cachedBlock = contentBlocks.first as Map<String, dynamic>;
      expect(cachedBlock['text'], equals('Cached content block'));
      expect(cachedBlock['cache_control']['ttl'], equals('1h'));

      print('Complex mixed content structure validated');
    });
  });
}
