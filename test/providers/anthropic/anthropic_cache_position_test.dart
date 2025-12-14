import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import '../../test_utils/model_message_test_extensions.dart';

/// Test suite for Anthropic prompt caching position behavior
/// Tests the specific scenario where cache is applied in the middle of content
/// and whether tools added after cache are included in caching
void main() {
  group('Anthropic Cache Position Tests', () {
    late Tool testTool;

    setUp(() {
      testTool = Tool.function(
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
      );
    });

    test('Cache in middle of MessageBuilder - tools added after cache', () {
      // This is the specific scenario you asked about:
      // .text() -> .cache() -> .text() -> .tools()
      final message = MessageBuilder.system()
          .text('Regular text')
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('Cached text')
          .tools([testTool]).build();

      // According to our current design, ALL content in MessageBuilder should be cached
      // when .cache() is called, regardless of order

      // Text should be merged
      final expectedContent = 'Regular text\nCached text';
      expect(message.content, equals(expectedContent));
      expect(message.hasExtension('anthropic'), isTrue);

      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic')!;
      final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>;

      // Should have cache marker and tools block
      expect(contentBlocks.length, equals(2));

      // Verify cache marker exists
      final hasCacheMarker = contentBlocks.any((block) =>
          block is Map<String, dynamic> &&
          block['cache_control'] != null &&
          block['text'] == '');
      expect(hasCacheMarker, isTrue);

      // Verify tools block exists
      final hasToolsBlock = contentBlocks.any(
          (block) => block is Map<String, dynamic> && block['type'] == 'tools');
      expect(hasToolsBlock, isTrue);

      print('Cache in middle - tools added after cache are included');
    });

    test('Compare with official API structure expectation', () {
      // Based on official docs, let's see what the API structure should look like
      final message = MessageBuilder.system()
          .text('Regular text')
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('Cached text')
          .tools([testTool]).build();

      final messages = [message];

      // Simulate _buildRequestBody logic
      Map<String, dynamic>? toolCacheControl;
      final messageTools = <Tool>[];

      for (final msg in messages) {
        final anthropicData =
            msg.getExtension<Map<String, dynamic>>('anthropic');
        if (anthropicData != null) {
          final contentBlocks =
              anthropicData['contentBlocks'] as List<dynamic>?;
          if (contentBlocks != null) {
            for (final block in contentBlocks) {
              if (block is Map<String, dynamic>) {
                if (block['cache_control'] != null && block['text'] == '') {
                  toolCacheControl = block['cache_control'];
                } else if (block['type'] == 'tools') {
                  final toolsList = block['tools'] as List<dynamic>?;
                  if (toolsList != null) {
                    for (final toolData in toolsList) {
                      if (toolData is Map<String, dynamic>) {
                        final function =
                            toolData['function'] as Map<String, dynamic>;
                        messageTools.add(Tool(
                          toolType: toolData['type'] as String? ?? 'function',
                          function: FunctionTool(
                            name: function['name'] as String,
                            description: function['description'] as String,
                            parameters: ParametersSchema.fromJson(
                                function['parameters'] as Map<String, dynamic>),
                          ),
                        ));
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Convert tools to API format (Anthropic uses flat format)
      final convertedTools = messageTools
          .map((t) => {
                'name': t.function.name,
                'description': t.function.description,
                'input_schema': t.function.parameters.toJson(),
              })
          .toList();

      // Apply cache control to last tool (current implementation)
      if (toolCacheControl != null && convertedTools.isNotEmpty) {
        convertedTools.last['cache_control'] = toolCacheControl;
      }

      // In this case, the tool WILL have cache_control applied
      expect(convertedTools.length, equals(1));
      expect(convertedTools.last.containsKey('cache_control'), isTrue);

      final cacheControl =
          convertedTools.last['cache_control'] as Map<String, dynamic>;
      expect(cacheControl['type'], equals('ephemeral'));
      expect(cacheControl['ttl'], equals('1h'));

      print('Tools added after cache DO get cached in current implementation');
    });

    test('Official API flexibility - separate cache breakpoints', () {
      // According to official docs, you can have multiple cache breakpoints
      // This would be the "official" way to cache text and tools separately

      // If we wanted to cache text but NOT tools, we'd need separate messages:

      // Message 1: Cached text only
      final textMessage = MessageBuilder.system()
          .text('Regular text')
          .text('Cached text')
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .build();

      // Message 2: Tools only (no cache)
      final toolMessage = MessageBuilder.system().tools([testTool]).build();

      expect(textMessage.hasExtension('anthropic'), isTrue);
      expect(toolMessage.hasExtension('anthropic'), isFalse);

      // Or if we wanted both cached but as separate breakpoints:

      // Message with tools cached first, then text cached separately
      final separateBreakpointsMessage = MessageBuilder.system()
          .tools([testTool])
          .anthropicConfig((anthropic) =>
              anthropic.cache(ttl: AnthropicCacheTtl.oneHour)) // Cache tools
          .text('Regular text')
          .text('Additional text')
          .anthropicConfig((anthropic) => anthropic.cache(
              ttl: AnthropicCacheTtl
                  .fiveMinutes)) // Cache text with different TTL
          .build();

      final data = separateBreakpointsMessage
          .getExtension<Map<String, dynamic>>('anthropic')!;
      final blocks = data['contentBlocks'] as List<dynamic>;

      // Should have 2 cache markers + 1 tools block
      expect(blocks.length, equals(3));

      // Count cache markers
      final cacheMarkers = blocks
          .where((block) =>
              block is Map<String, dynamic> &&
              block['cache_control'] != null &&
              block['text'] == '')
          .length;
      expect(cacheMarkers, equals(2));

      print(
          'Official API supports separate cache breakpoints for fine-grained control');
    });

    test('Current implementation behavior summary', () {
      // Test to document current behavior clearly

      final message = MessageBuilder.system()
          .text('Text before cache')
          .anthropicConfig(
              (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
          .text('Text after cache')
          .tools([testTool])
          .text('Text after tools')
          .build();

      // Current behavior: ALL content in MessageBuilder gets cached together
      final expectedContent =
          'Text before cache\nText after cache\nText after tools';
      expect(message.content, equals(expectedContent));

      // Tools are included in the caching
      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic')!;
      final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>;

      final hasTools = contentBlocks.any(
          (block) => block is Map<String, dynamic> && block['type'] == 'tools');
      final hasCache = contentBlocks.any((block) =>
          block is Map<String, dynamic> && block['cache_control'] != null);

      expect(hasTools, isTrue);
      expect(hasCache, isTrue);

      print(
          'Current implementation: MessageBuilder-level caching includes ALL content');
    });
  });
}
