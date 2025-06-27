import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Test suite for Anthropic GLOBAL caching structure validation
/// Tests that .cache() applies to ALL content in the message
/// NO API CALLS - only validates message structure
void main() {
  group('Anthropic Global Cache Tests', () {
    test('System message with global 1-hour cache', () {
      // Create system message with global cache
      final systemMessage = MessageBuilder.system()
          .text('You are a helpful AI assistant.')
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('Here is additional context that will also be cached.')
          .build();

      // Verify message structure
      expect(systemMessage.role, equals(ChatRole.system));
      expect(systemMessage.hasExtension('anthropic'), isTrue);

      // All content should be combined
      expect(
          systemMessage.content, contains('You are a helpful AI assistant.'));
      expect(systemMessage.content, contains('Here is additional context'));

      // Should have cache flag in extensions
      final anthropicData =
          systemMessage.getExtension<Map<String, dynamic>>('anthropic');
      expect(anthropicData, isNotNull);

      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>?;
      expect(contentBlocks, isNotNull);
      expect(contentBlocks!.length, equals(1)); // Just the cache flag

      final cacheFlag = contentBlocks.first as Map<String, dynamic>;
      expect(cacheFlag['text'], equals('')); // Empty text
      expect(cacheFlag['cache_control'], isNotNull);

      final cacheControl = cacheFlag['cache_control'] as Map<String, dynamic>;
      expect(cacheControl['type'], equals('ephemeral'));
      expect(cacheControl['ttl'], equals('1h'));

      print('Global cache with 1h TTL validated');
    });

    test('User message with global 5-minute cache', () {
      final userMessage = MessageBuilder.user()
          .text('First part of user message')
          .anthropicConfig((anthropic) =>
              anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
          .text('Second part will also be cached')
          .build();

      expect(userMessage.role, equals(ChatRole.user));
      expect(userMessage.hasExtension('anthropic'), isTrue);

      // Verify 5-minute TTL
      final anthropicData =
          userMessage.getExtension<Map<String, dynamic>>('anthropic');
      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
      final cacheFlag = contentBlocks.first as Map<String, dynamic>;
      final cacheControl = cacheFlag['cache_control'] as Map<String, dynamic>;

      expect(cacheControl['ttl'], equals('5m'));

      print('Global cache with 5m TTL validated');
    });

    test('Message without cache should have no extensions', () {
      final regularMessage = MessageBuilder.system()
          .text('Regular system message')
          .text('More regular content')
          .build();

      expect(regularMessage.hasExtension('anthropic'), isFalse);
      expect(regularMessage.content,
          equals('Regular system message\nMore regular content'));

      print('Regular message without cache validated');
    });

    test('API conversion with global cache', () {
      // Test what _convertMessage would produce
      final message = MessageBuilder.system()
          .text('System instructions')
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('Additional cached content')
          .build();

      // Simulate _convertMessage logic
      final content = <Map<String, dynamic>>[];
      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic');

      Map<String, dynamic>? cacheControl;
      if (anthropicData != null) {
        final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
        if (contentBlocks != null) {
          for (final block in contentBlocks) {
            if (block is Map<String, dynamic>) {
              if (block['cache_control'] != null && block['text'] == '') {
                cacheControl = block['cache_control'];
                continue; // Skip flag
              }
              content.add(block);
            }
          }
        }

        // Add regular content with cache
        if (message.content.isNotEmpty) {
          final textBlock = <String, dynamic>{
            'type': 'text',
            'text': message.content
          };
          if (cacheControl != null) {
            textBlock['cache_control'] = cacheControl;
          }
          content.add(textBlock);
        }
      }

      // Verify API conversion
      expect(content.length, equals(1)); // Single cached block

      final apiBlock = content.first;
      expect(apiBlock['type'], equals('text'));
      expect(apiBlock['text'], contains('System instructions'));
      expect(apiBlock['text'], contains('Additional cached content'));
      expect(apiBlock['cache_control'], isNotNull);

      final apiCacheControl = apiBlock['cache_control'] as Map<String, dynamic>;
      expect(apiCacheControl['type'], equals('ephemeral'));
      expect(apiCacheControl['ttl'], equals('1h'));

      print('API conversion with global cache validated');
    });

    test('Multiple messages with different cache settings', () {
      // Message 1: No cache
      final msg1 = MessageBuilder.user().text('Regular user message').build();

      // Message 2: 1h cache
      final msg2 = MessageBuilder.system()
          .text('System prompt')
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('Cached system content')
          .build();

      // Message 3: 5m cache
      final msg3 = MessageBuilder.assistant()
          .text('Assistant response')
          .anthropicConfig((anthropic) =>
              anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
          .build();

      // Verify each message
      expect(msg1.hasExtension('anthropic'), isFalse);
      expect(msg2.hasExtension('anthropic'), isTrue);
      expect(msg3.hasExtension('anthropic'), isTrue);

      // Verify cache TTLs
      final msg2Data = msg2.getExtension<Map<String, dynamic>>('anthropic');
      final msg2Blocks = msg2Data!['contentBlocks'] as List<dynamic>;
      final msg2Cache = (msg2Blocks.first
          as Map<String, dynamic>)['cache_control'] as Map<String, dynamic>;
      expect(msg2Cache['ttl'], equals('1h'));

      final msg3Data = msg3.getExtension<Map<String, dynamic>>('anthropic');
      final msg3Blocks = msg3Data!['contentBlocks'] as List<dynamic>;
      final msg3Cache = (msg3Blocks.first
          as Map<String, dynamic>)['cache_control'] as Map<String, dynamic>;
      expect(msg3Cache['ttl'], equals('5m'));

      print('Multiple messages with different cache settings validated');
    });
  });
}
