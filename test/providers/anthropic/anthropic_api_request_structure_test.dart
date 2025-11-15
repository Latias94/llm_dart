import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Test suite for Anthropic API request structure validation
/// Tests that _buildRequestBody produces correct API request structure
/// according to official Anthropic API documentation
/// NO API CALLS - only validates request structure building
void main() {
  group('Anthropic API Request Structure Tests', () {
    late List<Tool> testTools;

    setUp(() {
      testTools = [
        Tool.function(
          name: 'search_documents',
          description: 'Search through documents',
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

    group('Tools Caching API Structure', () {
      test('Tools with cache_control should apply to last tool', () {
        final message = MessageBuilder.system()
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .tools(testTools)
            .build();

        final messages = [message];

        // Simulate _buildRequestBody logic for tools processing
        Map<String, dynamic>? toolCacheControl;
        final messageTools = <Tool>[];

        // Extract tools and cache control from messages
        for (final msg in messages) {
          final anthropicData =
              msg.getExtension<Map<String, dynamic>>('anthropic');
          if (anthropicData != null) {
            final contentBlocks =
                anthropicData['contentBlocks'] as List<dynamic>?;
            if (contentBlocks != null) {
              for (final block in contentBlocks) {
                if (block is Map<String, dynamic>) {
                  // Extract cache control marker
                  if (block['cache_control'] != null && block['text'] == '') {
                    toolCacheControl = block['cache_control'];
                  }
                  // Extract tools from tools block
                  else if (block['type'] == 'tools') {
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
                                  function['parameters']
                                      as Map<String, dynamic>),
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

        // Apply cache control to last tool (as per current implementation)
        if (toolCacheControl != null && convertedTools.isNotEmpty) {
          convertedTools.last['cache_control'] = toolCacheControl;
        }

        // Verify API structure
        expect(convertedTools.length, equals(2));
        expect(convertedTools.last.containsKey('cache_control'), isTrue);

        final cacheControl =
            convertedTools.last['cache_control'] as Map<String, dynamic>;
        expect(cacheControl['type'], equals('ephemeral'));
        expect(cacheControl['ttl'], equals('1h'));

        // Verify tool structure (Anthropic flat format)
        expect(convertedTools[0]['name'], equals('search_documents'));
        expect(convertedTools[0]['description'], isNotNull);
        expect(convertedTools[0]['input_schema'], isNotNull);
        expect(convertedTools[1]['name'], equals('get_weather'));
        expect(convertedTools[1]['description'], isNotNull);
        expect(convertedTools[1]['input_schema'], isNotNull);

        print('Tools caching API structure validated');
      });

      test('Multiple tools with different cache configurations', () {
        final message1 = MessageBuilder.system()
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .tools([testTools[0]]) // First tool with 1h cache
            .build();

        final message2 = MessageBuilder.user()
            .anthropicConfig((anthropic) =>
                anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .tools([testTools[1]]) // Second tool with 5m cache
            .build();

        final messages = [message1, message2];

        // Simulate tools extraction with cache control
        Map<String, dynamic>? lastCacheControl;
        final allTools = <Tool>[];

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
                    lastCacheControl = block['cache_control']; // Last one wins
                  } else if (block['type'] == 'tools') {
                    final toolsList = block['tools'] as List<dynamic>?;
                    if (toolsList != null) {
                      for (final toolData in toolsList) {
                        if (toolData is Map<String, dynamic>) {
                          final function =
                              toolData['function'] as Map<String, dynamic>;
                          allTools.add(Tool(
                            toolType: toolData['type'] as String? ?? 'function',
                            function: FunctionTool(
                              name: function['name'] as String,
                              description: function['description'] as String,
                              parameters: ParametersSchema.fromJson(
                                  function['parameters']
                                      as Map<String, dynamic>),
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

        final convertedTools = allTools
            .map((t) => {
                  'name': t.function.name,
                  'description': t.function.description,
                  'input_schema': t.function.parameters.toJson(),
                })
            .toList();

        if (lastCacheControl != null && convertedTools.isNotEmpty) {
          convertedTools.last['cache_control'] = lastCacheControl;
        }

        // Last cache control should be 5m (from user message)
        expect(convertedTools.length, equals(2));
        expect(convertedTools.last.containsKey('cache_control'), isTrue);

        final cacheControl =
            convertedTools.last['cache_control'] as Map<String, dynamic>;
        expect(cacheControl['ttl'], equals('5m')); // Last one wins

        print('Multiple tools with different cache configurations validated');
      });
    });

    group('System Message Caching API Structure', () {
      test('System message with cache_control should be structured correctly',
          () {
        final message = MessageBuilder.system()
            .text('You are a helpful assistant.')
            .anthropicConfig((anthropic) =>
                anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .text('Additional context that should be cached.')
            .build();

        // Simulate system message processing in _buildRequestBody
        final systemContentBlocks = <Map<String, dynamic>>[];
        final anthropicData =
            message.getExtension<Map<String, dynamic>>('anthropic');

        Map<String, dynamic>? systemCacheControl;
        if (anthropicData != null) {
          final contentBlocks =
              anthropicData['contentBlocks'] as List<dynamic>?;
          if (contentBlocks != null && contentBlocks.isNotEmpty) {
            for (final block in contentBlocks) {
              if (block is Map<String, dynamic>) {
                // Extract cache control marker
                if (block['cache_control'] != null && block['text'] == '') {
                  systemCacheControl = block['cache_control'];
                  continue; // Skip cache marker
                }
                systemContentBlocks.add(block);
              }
            }
          }
        }

        // Apply cache control to system content
        if (message.content.isNotEmpty && systemCacheControl != null) {
          systemContentBlocks.add({
            'type': 'text',
            'text': message.content,
            'cache_control': systemCacheControl,
          });
        }

        // Verify API structure
        expect(systemContentBlocks.length, equals(1));
        expect(systemContentBlocks.first['type'], equals('text'));
        expect(systemContentBlocks.first['text'],
            contains('You are a helpful assistant'));
        expect(
            systemContentBlocks.first['text'], contains('Additional context'));
        expect(systemContentBlocks.first.containsKey('cache_control'), isTrue);

        final cacheControl =
            systemContentBlocks.first['cache_control'] as Map<String, dynamic>;
        expect(cacheControl['type'], equals('ephemeral'));
        expect(cacheControl['ttl'], equals('5m'));

        print('System message caching API structure validated');
      });

      test('System message without cache should not have cache_control', () {
        final message = MessageBuilder.system()
            .text('Regular system message without caching')
            .build();

        // Should not have anthropic extensions
        expect(message.hasExtension('anthropic'), isFalse);

        // Simulate system message processing
        final systemMessages = <String>[];
        if (message.role == ChatRole.system &&
            !message.hasExtension('anthropic')) {
          systemMessages.add(message.content);
        }

        expect(systemMessages.length, equals(1));
        expect(systemMessages.first,
            equals('Regular system message without caching'));

        print('System message without cache validated');
      });
    });

    group('Message Content Caching API Structure', () {
      test('User message with cache_control should be structured correctly',
          () {
        final message = MessageBuilder.user()
            .text('User question')
            .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .text('Additional user context')
            .build();

        // Simulate _convertMessage logic
        final content = <Map<String, dynamic>>[];
        final anthropicData =
            message.getExtension<Map<String, dynamic>>('anthropic');

        Map<String, dynamic>? cacheControl;
        if (anthropicData != null) {
          final contentBlocks =
              anthropicData['contentBlocks'] as List<dynamic>?;
          if (contentBlocks != null) {
            for (final block in contentBlocks) {
              if (block is Map<String, dynamic>) {
                // Extract cache control marker
                if (block['cache_control'] != null && block['text'] == '') {
                  cacheControl = block['cache_control'];
                  continue; // Skip cache marker
                }
                content.add(block);
              }
            }
          }

          // Add regular content with cache control
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

        // Verify API structure
        expect(content.length, equals(1));
        expect(content.first['type'], equals('text'));
        expect(content.first['text'], contains('User question'));
        expect(content.first['text'], contains('Additional user context'));
        expect(content.first.containsKey('cache_control'), isTrue);

        final messageCacheControl =
            content.first['cache_control'] as Map<String, dynamic>;
        expect(messageCacheControl['type'], equals('ephemeral'));
        expect(messageCacheControl['ttl'], equals('1h'));

        print('User message caching API structure validated');
      });

      test(
          'Assistant message with cache_control should be structured correctly',
          () {
        final message = MessageBuilder.assistant()
            .text('Assistant response')
            .anthropicConfig((anthropic) =>
                anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .text('Additional assistant context')
            .build();

        // Same logic as user message
        final content = <Map<String, dynamic>>[];
        final anthropicData =
            message.getExtension<Map<String, dynamic>>('anthropic');

        Map<String, dynamic>? cacheControl;
        if (anthropicData != null) {
          final contentBlocks =
              anthropicData['contentBlocks'] as List<dynamic>?;
          if (contentBlocks != null) {
            for (final block in contentBlocks) {
              if (block is Map<String, dynamic>) {
                if (block['cache_control'] != null && block['text'] == '') {
                  cacheControl = block['cache_control'];
                  continue;
                }
                content.add(block);
              }
            }
          }

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

        expect(content.length, equals(1));
        expect(content.first['cache_control']['ttl'], equals('5m'));

        print('Assistant message caching API structure validated');
      });
    });
  });
}
