import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Test suite for unified MessageBuilder tool caching functionality
/// Tests that tools can be cached using the unified anthropicConfig approach
/// NO API CALLS - only validates message structure
void main() {
  group('Anthropic Unified Tool Caching Tests', () {
    late List<Tool> testTools;

    setUp(() {
      testTools = [
        Tool.function(
          name: 'search_docs',
          description: 'Search documentation',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'query': ParameterProperty(
                propertyType: 'string',
                description: 'Search query',
              ),
            },
            required: ['query'],
          ),
        ),
        Tool.function(
          name: 'get_weather',
          description: 'Get current weather',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'location': ParameterProperty(
                propertyType: 'string',
                description: 'City name',
              ),
            },
            required: ['location'],
          ),
        ),
      ];
    });

    test('MessageBuilder with tools but no caching', () {
      final message = MessageBuilder.system()
          .text('You are a helpful assistant.')
          .tools(testTools)
          .text('Use the provided tools to help users.')
          .build();

      // Should have tools in content but no caching extensions
      expect(message.content, contains('[2 tools defined]'));
      expect(message.hasExtension('anthropic'), isFalse);

      print('Message with tools (no caching) validated');
    });

    test('MessageBuilder with cached tools (correct order)', () {
      // Cache configuration BEFORE tools - this should cache the tools
      final message = MessageBuilder.system()
          .text('You are a helpful assistant.')
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .tools(testTools) // These tools should be cached
          .text('Use the provided tools to help users.')
          .build();

      // Should have tools in content AND caching extensions
      expect(message.content, contains('[2 tools defined]'));
      expect(message.hasExtension('anthropic'), isTrue);

      // Verify cache configuration
      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic');
      expect(anthropicData, isNotNull);

      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>?;
      expect(contentBlocks, isNotNull);
      expect(contentBlocks!.length, equals(1)); // Cache marker

      final cacheMarker = contentBlocks.first as Map<String, dynamic>;
      expect(cacheMarker['text'], equals('')); // Empty cache marker
      expect(cacheMarker['cache_control'], isNotNull);

      final cacheControl = cacheMarker['cache_control'] as Map<String, dynamic>;
      expect(cacheControl['type'], equals('ephemeral'));
      expect(cacheControl['ttl'], equals('1h'));

      print('Message with cached tools (correct order) validated');
    });

    test('MessageBuilder with tools then cache (wrong order)', () {
      // Tools BEFORE cache configuration - tools should NOT be cached
      final message = MessageBuilder.system()
          .text('You are a helpful assistant.')
          .tools(testTools) // These tools are added first
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('This text will be cached, not the tools.')
          .build();

      // Should have tools in content AND caching extensions (but cache applies to text)
      expect(message.content, contains('[2 tools defined]'));
      expect(message.content, contains('This text will be cached'));
      expect(message.hasExtension('anthropic'), isTrue);

      print('Message with tools then cache (wrong order) validated');
    });

    test('MessageBuilder with multiple cache configurations', () {
      final message = MessageBuilder.system()
          .text('System instructions')
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .tools(testTools) // Cached with 1h TTL
          .text('Intermediate text')
          .anthropicConfig((anthropic) =>
              anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
          .text('This text cached with 5m TTL')
          .build();

      expect(message.content, contains('[2 tools defined]'));
      expect(message.hasExtension('anthropic'), isTrue);

      // Should have multiple cache markers
      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic');
      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
      expect(contentBlocks.length, equals(2)); // Two cache markers

      // First cache marker (1h TTL for tools)
      final firstCache = contentBlocks[0] as Map<String, dynamic>;
      final firstCacheControl =
          firstCache['cache_control'] as Map<String, dynamic>;
      expect(firstCacheControl['ttl'], equals('1h'));

      // Second cache marker (5m TTL for text)
      final secondCache = contentBlocks[1] as Map<String, dynamic>;
      final secondCacheControl =
          secondCache['cache_control'] as Map<String, dynamic>;
      expect(secondCacheControl['ttl'], equals('5m'));

      print('Message with multiple cache configurations validated');
    });

    test('MessageBuilder tools caching with different TTLs', () {
      // Test 5-minute TTL for tools
      final message = MessageBuilder.system()
          .anthropicConfig((anthropic) =>
              anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
          .tools(testTools)
          .build();

      expect(message.hasExtension('anthropic'), isTrue);

      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic');
      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
      final cacheControl = (contentBlocks.first
          as Map<String, dynamic>)['cache_control'] as Map<String, dynamic>;

      expect(cacheControl['ttl'], equals('5m'));

      print('Tools caching with 5-minute TTL validated');
    });

    test('MessageBuilder tools caching without TTL', () {
      // Test default caching (no TTL specified)
      final message = MessageBuilder.system()
          .anthropicConfig((anthropic) => anthropic.cache())
          .tools(testTools)
          .build();

      expect(message.hasExtension('anthropic'), isTrue);

      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic');
      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
      final cacheControl = (contentBlocks.first
          as Map<String, dynamic>)['cache_control'] as Map<String, dynamic>;

      expect(cacheControl['type'], equals('ephemeral'));
      expect(cacheControl.containsKey('ttl'), isFalse); // No TTL specified

      print('Tools caching without TTL validated');
    });

    test('Complex message with tools, text, and mixed caching', () {
      final message = MessageBuilder.system()
          .text('You are an AI assistant with access to these tools:')
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .tools(testTools) // Tools cached for 1 hour
          .text('Instructions: Use these tools when needed.')
          .anthropicConfig((anthropic) =>
              anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
          .text(
              'Session context: Current user is a developer.') // Text cached for 5 minutes
          .text('How can I help you today?') // Not cached
          .build();

      // Verify content structure
      expect(message.content, contains('You are an AI assistant'));
      expect(message.content, contains('[2 tools defined]'));
      expect(message.content, contains('Instructions: Use these tools'));
      expect(message.content, contains('Session context'));
      expect(message.content, contains('How can I help you today?'));

      // Verify caching structure
      expect(message.hasExtension('anthropic'), isTrue);

      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic');
      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
      expect(contentBlocks.length, equals(2)); // Two cache configurations

      print('Complex message with mixed caching validated');
    });
  });
}
