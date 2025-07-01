import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Test suite for Anthropic tools caching API structure validation
/// Tests that tools caching produces correct API request structure
/// according to the current implementation design
/// NO API CALLS - only validates API request building logic
void main() {
  group('Anthropic Tools Caching API Structure Tests', () {
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
        Tool.function(
          name: 'calculate',
          description: 'Perform calculations',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'expression': ParameterProperty(
                propertyType: 'string',
                description: 'Mathematical expression',
              ),
            },
            required: ['expression'],
          ),
        ),
      ];
    });

    group('Single MessageBuilder Tools Caching', () {
      test('Tools only with cache should apply cache_control to last tool', () {
        final message = MessageBuilder.system()
            .tools(testTools)
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        final messages = [message];
        
        // Simulate _buildRequestBody logic for tools processing
        Map<String, dynamic>? toolCacheControl;
        final messageTools = <Tool>[];

        // Extract tools and cache control from messages
        for (final msg in messages) {
          final anthropicData = msg.getExtension<Map<String, dynamic>>('anthropic');
          if (anthropicData != null) {
            final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
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
                          final function = toolData['function'] as Map<String, dynamic>;
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

        // Convert tools to API format
        final convertedTools = messageTools.map((t) => {
          'type': t.toolType,
          'function': t.function.toJson(),
        }).toList();

        // Apply cache control to last tool (as per current implementation)
        if (toolCacheControl != null && convertedTools.isNotEmpty) {
          convertedTools.last['cache_control'] = toolCacheControl;
        }

        // Verify API structure
        expect(convertedTools.length, equals(3)); // All 3 tools
        expect(convertedTools.last.containsKey('cache_control'), isTrue);
        
        final cacheControl = convertedTools.last['cache_control'] as Map<String, dynamic>;
        expect(cacheControl['type'], equals('ephemeral'));
        expect(cacheControl['ttl'], equals('1h'));

        // Verify tool structure
        final tool0Function = (convertedTools[0]['function'] as Map<String, dynamic>);
        final tool1Function = (convertedTools[1]['function'] as Map<String, dynamic>);
        final tool2Function = (convertedTools[2]['function'] as Map<String, dynamic>);
        expect(tool0Function['name'], equals('search_documents'));
        expect(tool1Function['name'], equals('get_weather'));
        expect(tool2Function['name'], equals('calculate'));

        // Only last tool should have cache_control
        expect(convertedTools[0].containsKey('cache_control'), isFalse);
        expect(convertedTools[1].containsKey('cache_control'), isFalse);
        expect(convertedTools[2].containsKey('cache_control'), isTrue);

        print('Tools only with cache - cache_control applied to last tool');
      });

      test('Tools with text and cache should cache everything', () {
        final message = MessageBuilder.system()
            .text('System instructions')
            .tools(testTools)
            .text('Additional context')
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .build();

        // Text should be merged
        final expectedContent = 'System instructions\nAdditional context';
        expect(message.content, equals(expectedContent));
        expect(message.hasExtension('anthropic'), isTrue);

        // Extract tools and cache control
        final anthropicData = message.getExtension<Map<String, dynamic>>('anthropic')!;
        final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>;
        
        // Should have cache marker and tools block
        expect(contentBlocks.length, equals(2));
        
        // Verify cache marker
        final cacheMarker = contentBlocks.firstWhere((block) =>
            block is Map<String, dynamic> && 
            block['cache_control'] != null &&
            block['text'] == '') as Map<String, dynamic>;
        expect(cacheMarker['cache_control']['ttl'], equals('5m'));
        
        // Verify tools block
        final toolsBlock = contentBlocks.firstWhere((block) =>
            block is Map<String, dynamic> && block['type'] == 'tools') as Map<String, dynamic>;
        expect(toolsBlock['tools'], isA<List>());
        expect((toolsBlock['tools'] as List).length, equals(3));

        print('Tools with text and cache - everything cached together');
      });
    });

    group('Multiple MessageBuilders Tools Caching', () {
      test('Different MessageBuilders with different tool caching', () {
        // First MessageBuilder: Tools with 1-hour cache
        final systemMessage = MessageBuilder.system()
            .text('You are a helpful assistant.')
            .tools([testTools[0], testTools[1]]) // First 2 tools
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // Second MessageBuilder: Different tools with 5-minute cache
        final userMessage = MessageBuilder.user()
            .text('Please use the calculation tool.')
            .tools([testTools[2]]) // Last tool
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .build();

        final messages = [systemMessage, userMessage];
        
        // Simulate tools extraction with cache control
        Map<String, dynamic>? lastCacheControl;
        final allTools = <Tool>[];

        for (final msg in messages) {
          final anthropicData = msg.getExtension<Map<String, dynamic>>('anthropic');
          if (anthropicData != null) {
            final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
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
                          final function = toolData['function'] as Map<String, dynamic>;
                          allTools.add(Tool(
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

        final convertedTools = allTools.map((t) => {
          'type': t.toolType,
          'function': t.function.toJson(),
        }).toList();

        if (lastCacheControl != null && convertedTools.isNotEmpty) {
          convertedTools.last['cache_control'] = lastCacheControl;
        }

        // Should have all 3 tools
        expect(convertedTools.length, equals(3));
        expect(convertedTools.last.containsKey('cache_control'), isTrue);
        
        // Last cache control should be 5m (from user message)
        final cacheControl = convertedTools.last['cache_control'] as Map<String, dynamic>;
        expect(cacheControl['ttl'], equals('5m')); // Last one wins

        // Verify tool names
        final func0 = (convertedTools[0]['function'] as Map<String, dynamic>);
        final func1 = (convertedTools[1]['function'] as Map<String, dynamic>);
        final func2 = (convertedTools[2]['function'] as Map<String, dynamic>);
        expect(func0['name'], equals('search_documents'));
        expect(func1['name'], equals('get_weather'));
        expect(func2['name'], equals('calculate'));

        print('Multiple MessageBuilders with different tool caching - last cache wins');
      });

      test('Mixed cached and non-cached MessageBuilders with tools', () {
        // Cached MessageBuilder with tools
        final cachedMessage = MessageBuilder.system()
            .text('System with cached tools')
            .tools([testTools[0]])
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // Non-cached MessageBuilder with tools
        final nonCachedMessage = MessageBuilder.user()
            .text('User with non-cached tools')
            .tools([testTools[1]])
            .build();

        // Another cached MessageBuilder with tools
        final anotherCachedMessage = MessageBuilder.assistant()
            .text('Assistant with cached tools')
            .tools([testTools[2]])
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .build();

        final messages = [cachedMessage, nonCachedMessage, anotherCachedMessage];

        // Verify caching states
        expect(cachedMessage.hasExtension('anthropic'), isTrue);
        expect(nonCachedMessage.hasExtension('anthropic'), isFalse);
        expect(anotherCachedMessage.hasExtension('anthropic'), isTrue);

        // Extract all tools and cache control
        Map<String, dynamic>? lastCacheControl;
        final allTools = <Tool>[];

        for (final msg in messages) {
          final anthropicData = msg.getExtension<Map<String, dynamic>>('anthropic');
          if (anthropicData != null) {
            final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
            if (contentBlocks != null) {
              for (final block in contentBlocks) {
                if (block is Map<String, dynamic>) {
                  if (block['cache_control'] != null && block['text'] == '') {
                    lastCacheControl = block['cache_control'];
                  } else if (block['type'] == 'tools') {
                    final toolsList = block['tools'] as List<dynamic>?;
                    if (toolsList != null) {
                      for (final toolData in toolsList) {
                        if (toolData is Map<String, dynamic>) {
                          final function = toolData['function'] as Map<String, dynamic>;
                          allTools.add(Tool(
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

        // Should have cache control from last cached message
        expect(lastCacheControl, isNotNull);
        expect(lastCacheControl!['ttl'], equals('5m')); // From assistant message

        print('Mixed cached and non-cached MessageBuilders with tools - validated');
      });
    });
  });
}
