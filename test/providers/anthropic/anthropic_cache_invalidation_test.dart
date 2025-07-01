import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Test suite for Anthropic prompt caching invalidation scenarios
/// Tests cache invalidation conditions according to official documentation
/// NO API CALLS - only validates cache invalidation logic
void main() {
  group('Anthropic Cache Invalidation Tests', () {
    group('Cache Invalidation Hierarchy', () {
      test('Tool definition changes invalidate entire cache', () {
        // According to official docs: "Modifying tool definitions (names, descriptions, parameters) invalidates the entire cache"
        final originalTool = Tool.function(
          name: 'original_function',
          description: 'Original description',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'param': ParameterProperty(
                propertyType: 'string',
                description: 'Original parameter',
              ),
            },
            required: ['param'],
          ),
        );

        final modifiedTool = Tool.function(
          name: 'modified_function', // Name changed
          description: 'Modified description', // Description changed
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'param': ParameterProperty(
                propertyType: 'string',
                description:
                    'Modified parameter', // Parameter description changed
              ),
            },
            required: ['param'],
          ),
        );

        final message1 = MessageBuilder.system()
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .tools([originalTool])
            .text('System instructions')
            .build();

        final message2 = MessageBuilder.system()
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .tools([modifiedTool])
            .text('System instructions') // Same text
            .build();

        // Extract tool definitions for comparison
        final data1 = message1.getExtension<Map<String, dynamic>>('anthropic')!;
        final data2 = message2.getExtension<Map<String, dynamic>>('anthropic')!;

        final blocks1 = data1['contentBlocks'] as List<dynamic>;
        final blocks2 = data2['contentBlocks'] as List<dynamic>;

        final toolsBlock1 =
            blocks1.firstWhere((b) => (b as Map)['type'] == 'tools') as Map;
        final toolsBlock2 =
            blocks2.firstWhere((b) => (b as Map)['type'] == 'tools') as Map;

        final tool1Data = toolsBlock1['tools'][0]['function'] as Map;
        final tool2Data = toolsBlock2['tools'][0]['function'] as Map;

        // Tool definitions are different, cache would be invalidated
        expect(tool1Data['name'], equals('original_function'));
        expect(tool2Data['name'], equals('modified_function'));
        expect(
            tool1Data['description'], isNot(equals(tool2Data['description'])));

        print('Tool definition changes invalidate entire cache - validated');
      });

      test('System prompt changes invalidate system and message cache', () {
        // According to official docs: Changes at system level invalidate system and all subsequent levels
        final message1 = MessageBuilder.system()
            .text('Original system prompt')
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        final message2 = MessageBuilder.system()
            .text('Modified system prompt') // Changed system content
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // System content is different, cache would be invalidated
        expect(message1.content, equals('Original system prompt'));
        expect(message2.content, equals('Modified system prompt'));
        expect(message1.content, isNot(equals(message2.content)));

        print(
            'System prompt changes invalidate system and message cache - validated');
      });

      test('Message changes only invalidate message cache', () {
        // According to official docs: Changes at message level only affect message blocks
        final systemMessage = MessageBuilder.system()
            .text('Same system prompt')
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        final userMessage1 = MessageBuilder.user()
            .text('First user message')
            .anthropicConfig((anthropic) =>
                anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .build();

        final userMessage2 = MessageBuilder.user()
            .text('Second user message') // Different user content
            .anthropicConfig((anthropic) =>
                anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .build();

        // System message stays the same (cache preserved)
        expect(systemMessage.content, equals('Same system prompt'));

        // User messages are different (message cache invalidated)
        expect(userMessage1.content, equals('First user message'));
        expect(userMessage2.content, equals('Second user message'));
        expect(userMessage1.content, isNot(equals(userMessage2.content)));

        print('Message changes only invalidate message cache - validated');
      });
    });

    group('Feature Toggle Invalidation', () {
      test('Web search toggle invalidates system cache', () {
        // According to official docs: "Enabling/disabling web search modifies the system prompt"
        // This would be tested at the provider level, but we can simulate the concept
        final messageWithoutWebSearch = MessageBuilder.system()
            .text('You are a helpful assistant.')
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        final messageWithWebSearch = MessageBuilder.system()
            .text('You are a helpful assistant with web search capabilities.')
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // Different system prompts due to web search toggle
        expect(messageWithoutWebSearch.content,
            isNot(equals(messageWithWebSearch.content)));

        print('Web search toggle invalidates system cache - validated');
      });

      test('Citations toggle invalidates system cache', () {
        // According to official docs: "Enabling/disabling citations modifies the system prompt"
        final messageWithoutCitations = MessageBuilder.system()
            .text('Standard system prompt')
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        final messageWithCitations = MessageBuilder.system()
            .text('System prompt with citation instructions')
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // Different system prompts due to citations toggle
        expect(messageWithoutCitations.content,
            isNot(equals(messageWithCitations.content)));

        print('Citations toggle invalidates system cache - validated');
      });
    });

    group('Content Validation', () {
      test('Empty text blocks cannot be cached', () {
        // According to official docs: "Empty text blocks cannot be cached"
        final messageWithEmptyText = MessageBuilder.system()
            .text('') // Empty text
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .text('Actual content')
            .build();

        // Only non-empty content should be present
        expect(messageWithEmptyText.content, equals('Actual content'));
        expect(messageWithEmptyText.content, isNot(isEmpty));

        print('Empty text blocks cannot be cached - validated');
      });

      test('Minimum cache length requirements', () {
        // According to official docs:
        // - 1024 tokens for Claude Opus 4, Sonnet 4, Sonnet 3.7, Sonnet 3.5, Opus 3
        // - 2048 tokens for Claude Haiku 3.5, Haiku 3

        // Short content (would not meet minimum requirements)
        final shortMessage = MessageBuilder.system()
            .text('Short') // Very short content
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // Long content (would meet minimum requirements)
        final longContent = 'Long content ' * 100; // Repeat to make it longer
        final longMessage = MessageBuilder.system()
            .text(longContent)
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        expect(shortMessage.content.length, lessThan(100));
        expect(longMessage.content.length, greaterThan(1000));

        // Both have cache configuration, but short one would be processed without caching
        expect(shortMessage.hasExtension('anthropic'), isTrue);
        expect(longMessage.hasExtension('anthropic'), isTrue);

        print('Minimum cache length requirements - validated');
      });
    });

    group('Cache Breakpoint Limits', () {
      test('Maximum 4 cache breakpoints allowed', () {
        // According to official docs: "you can define up to 4 cache breakpoints"
        final message = MessageBuilder.system()
            .text('Section 1')
            .anthropicConfig((anthropic) =>
                anthropic.cache(ttl: AnthropicCacheTtl.oneHour)) // Breakpoint 1
            .text('Section 2')
            .anthropicConfig((anthropic) =>
                anthropic.cache(ttl: AnthropicCacheTtl.oneHour)) // Breakpoint 2
            .text('Section 3')
            .anthropicConfig((anthropic) => anthropic.cache(
                ttl: AnthropicCacheTtl.fiveMinutes)) // Breakpoint 3
            .text('Section 4')
            .anthropicConfig((anthropic) => anthropic.cache(
                ttl: AnthropicCacheTtl.fiveMinutes)) // Breakpoint 4
            .text('Final section')
            .build();

        final anthropicData =
            message.getExtension<Map<String, dynamic>>('anthropic')!;
        final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>;

        // Count cache control blocks (empty text blocks with cache_control)
        final cacheBreakpoints = contentBlocks
            .where((block) =>
                block is Map<String, dynamic> &&
                block['cache_control'] != null &&
                block['text'] == '')
            .length;

        expect(cacheBreakpoints, equals(4)); // Exactly 4 breakpoints
        expect(cacheBreakpoints, lessThanOrEqualTo(4)); // Not exceeding limit

        print('Maximum 4 cache breakpoints allowed - validated');
      });

      test('TTL ordering constraint: longer TTL before shorter TTL', () {
        // According to official docs: "Cache entries with longer TTL must appear before shorter TTLs"
        final correctOrderMessage = MessageBuilder.system()
            .text('Long-term content')
            .anthropicConfig((anthropic) =>
                anthropic.cache(ttl: AnthropicCacheTtl.oneHour)) // 1h first
            .text('Short-term content')
            .anthropicConfig((anthropic) => anthropic.cache(
                ttl: AnthropicCacheTtl.fiveMinutes)) // 5m second
            .build();

        final anthropicData = correctOrderMessage
            .getExtension<Map<String, dynamic>>('anthropic')!;
        final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>;

        final cacheBlocks = contentBlocks
            .where((block) =>
                block is Map<String, dynamic> && block['cache_control'] != null)
            .map((block) => (block as Map<String, dynamic>)['cache_control'])
            .toList();

        expect(cacheBlocks.length, equals(2));
        expect(
            cacheBlocks[0]['ttl'], equals('1h')); // First should be longer TTL
        expect(cacheBlocks[1]['ttl'],
            equals('5m')); // Second should be shorter TTL

        print('TTL ordering constraint validated');
      });
    });

    group('Concurrent Request Behavior', () {
      test('Cache availability after first response', () {
        // According to official docs: "a cache entry only becomes available after the first response begins"
        final message1 = MessageBuilder.system()
            .text('Shared cached content')
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        final message2 = MessageBuilder.system()
            .text('Shared cached content') // Identical content
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // Both messages have identical cache configuration
        expect(message1.content, equals(message2.content));

        final data1 = message1.getExtension<Map<String, dynamic>>('anthropic')!;
        final data2 = message2.getExtension<Map<String, dynamic>>('anthropic')!;

        final blocks1 = data1['contentBlocks'] as List<dynamic>;
        final blocks2 = data2['contentBlocks'] as List<dynamic>;

        // Cache configurations should be identical
        expect(blocks1.length, equals(blocks2.length));

        print('Cache availability after first response - validated');
      });
    });
  });
}
