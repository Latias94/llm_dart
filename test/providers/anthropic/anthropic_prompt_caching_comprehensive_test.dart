import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Comprehensive test suite for Anthropic prompt caching according to correct design
/// Tests MessageBuilder-level caching where:
/// - One MessageBuilder = One ChatMessage
/// - .cache() applies to ALL content in the MessageBuilder (texts + tools)
/// - Multiple .text() calls are merged with newlines
/// - Users control caching granularity by creating multiple MessageBuilders
/// NO API CALLS - only validates message structure and request building
void main() {
  group('Anthropic Prompt Caching - MessageBuilder Level Caching', () {
    late List<Tool> testTools;

    setUp(() {
      testTools = [
        Tool.function(
          name: 'search_documents',
          description: 'Search through the knowledge base',
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

    group('MessageBuilder Level Caching Tests', () {
      test('Single MessageBuilder with multiple texts should merge and cache all', () {
        // Multiple .text() calls in one MessageBuilder should merge with newlines
        // and ALL content should be cached together
        final message = MessageBuilder.system()
            .text('First line of system instructions')
            .text('Second line of system instructions')
            .text('Third line of system instructions')
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // All text should be merged with newlines
        final expectedContent = 'First line of system instructions\n'
            'Second line of system instructions\n'
            'Third line of system instructions';

        expect(message.content, equals(expectedContent));
        expect(message.hasExtension('anthropic'), isTrue);

        // Should have cache configuration
        final anthropicData = message.getExtension<Map<String, dynamic>>('anthropic');
        expect(anthropicData, isNotNull);

        final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
        expect(contentBlocks.length, equals(1)); // Single cache marker

        final cacheMarker = contentBlocks.first as Map<String, dynamic>;
        expect(cacheMarker['cache_control'], isNotNull);
        expect(cacheMarker['cache_control']['type'], equals('ephemeral'));
        expect(cacheMarker['cache_control']['ttl'], equals('1h'));

        print('Multiple texts in MessageBuilder merge and cache together - validated');
      });

      test('MessageBuilder with tools and text should cache everything together', () {
        // When .cache() is used, ALL content in the MessageBuilder should be cached:
        // - All tools
        // - All text (merged with newlines)
        final message = MessageBuilder.system()
            .text('You are a helpful assistant.')
            .tools(testTools) // Add tools
            .text('Use the provided tools when needed.')
            .text('Always be helpful and accurate.')
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // Text should be merged
        final expectedContent = 'You are a helpful assistant.\n'
            'Use the provided tools when needed.\n'
            'Always be helpful and accurate.';

        expect(message.content, equals(expectedContent));
        expect(message.hasExtension('anthropic'), isTrue);

        final anthropicData = message.getExtension<Map<String, dynamic>>('anthropic');
        final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;

        // Should have cache marker and tools block
        expect(contentBlocks.length, equals(2));

        // Verify cache marker
        final cacheMarker = contentBlocks.firstWhere((block) =>
            block is Map<String, dynamic> &&
            block['cache_control'] != null &&
            block['text'] == '') as Map<String, dynamic>;
        expect(cacheMarker['cache_control']['ttl'], equals('1h'));

        // Verify tools block
        final toolsBlock = contentBlocks.firstWhere((block) =>
            block is Map<String, dynamic> && block['type'] == 'tools') as Map<String, dynamic>;
        expect(toolsBlock['tools'], isA<List>());
        expect((toolsBlock['tools'] as List).length, equals(2));

        print('MessageBuilder with tools and text caches everything together - validated');
      });

      test('Multiple MessageBuilders allow granular caching control', () {
        // Users can control caching granularity by creating separate MessageBuilders

        // Cached system message
        final cachedSystemMessage = MessageBuilder.system()
            .text('Static system instructions that rarely change')
            .text('These instructions will be cached for 1 hour')
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // Non-cached user message
        final regularUserMessage = MessageBuilder.user()
            .text('Dynamic user input that changes frequently')
            .text('This should not be cached')
            .build();

        // Cached context message
        final cachedContextMessage = MessageBuilder.user()
            .text('Large document context that can be reused')
            .text('This context will be cached for 5 minutes')
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .build();

        // Verify caching states
        expect(cachedSystemMessage.hasExtension('anthropic'), isTrue);
        expect(regularUserMessage.hasExtension('anthropic'), isFalse);
        expect(cachedContextMessage.hasExtension('anthropic'), isTrue);

        // Verify content merging
        expect(cachedSystemMessage.content, contains('Static system instructions'));
        expect(cachedSystemMessage.content, contains('These instructions will be cached'));
        expect(regularUserMessage.content, contains('Dynamic user input'));
        expect(regularUserMessage.content, contains('This should not be cached'));

        // Verify cache TTLs
        final systemData = cachedSystemMessage.getExtension<Map<String, dynamic>>('anthropic')!;
        final systemBlocks = systemData['contentBlocks'] as List<dynamic>;
        final systemCache = (systemBlocks.first as Map<String, dynamic>)['cache_control'];
        expect(systemCache['ttl'], equals('1h'));

        final contextData = cachedContextMessage.getExtension<Map<String, dynamic>>('anthropic')!;
        final contextBlocks = contextData['contentBlocks'] as List<dynamic>;
        final contextCache = (contextBlocks.first as Map<String, dynamic>)['cache_control'];
        expect(contextCache['ttl'], equals('5m'));

        print('Multiple MessageBuilders allow granular caching control - validated');
      });
    });

    group('Tools Caching Tests', () {
      test('MessageBuilder with only tools should cache all tools', () {
        // When only tools are added with .cache(), all tools should be cached
        final message = MessageBuilder.system()
            .tools(testTools)
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        expect(message.content, isEmpty); // No text content
        expect(message.hasExtension('anthropic'), isTrue);

        final anthropicData = message.getExtension<Map<String, dynamic>>('anthropic')!;
        final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>;

        // Should have cache marker and tools block
        expect(contentBlocks.length, equals(2));

        // Verify tools block
        final toolsBlock = contentBlocks.firstWhere((block) =>
            block is Map<String, dynamic> && block['type'] == 'tools') as Map<String, dynamic>;
        expect(toolsBlock['tools'], isA<List>());
        expect((toolsBlock['tools'] as List).length, equals(2));

        // Verify cache marker
        final cacheMarker = contentBlocks.firstWhere((block) =>
            block is Map<String, dynamic> &&
            block['cache_control'] != null) as Map<String, dynamic>;
        expect(cacheMarker['cache_control']['ttl'], equals('1h'));

        print('MessageBuilder with only tools caches all tools - validated');
      });

      test('MessageBuilder with tools and different TTLs', () {
        // Test different TTL values for tools caching
        final message5m = MessageBuilder.system()
            .tools(testTools)
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .build();

        final message1h = MessageBuilder.system()
            .tools(testTools)
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        final messageDefault = MessageBuilder.system()
            .tools(testTools)
            .anthropicConfig((anthropic) => anthropic.cache()) // No TTL specified
            .build();

        // Verify TTL values
        final data5m = message5m.getExtension<Map<String, dynamic>>('anthropic')!;
        final blocks5m = data5m['contentBlocks'] as List<dynamic>;
        final cache5m = blocks5m.firstWhere((b) =>
            (b as Map)['cache_control'] != null)['cache_control'];
        expect(cache5m['ttl'], equals('5m'));

        final data1h = message1h.getExtension<Map<String, dynamic>>('anthropic')!;
        final blocks1h = data1h['contentBlocks'] as List<dynamic>;
        final cache1h = blocks1h.firstWhere((b) =>
            (b as Map)['cache_control'] != null)['cache_control'];
        expect(cache1h['ttl'], equals('1h'));

        final dataDefault = messageDefault.getExtension<Map<String, dynamic>>('anthropic')!;
        final blocksDefault = dataDefault['contentBlocks'] as List<dynamic>;
        final cacheDefault = blocksDefault.firstWhere((b) =>
            (b as Map)['cache_control'] != null)['cache_control'];
        expect(cacheDefault.containsKey('ttl'), isFalse); // No TTL for default

        print('MessageBuilder with tools and different TTLs - validated');
      });

      test('Tools caching with mixed content types', () {
        // Test tools caching combined with text content
        final complexMessage = MessageBuilder.system()
            .text('System instructions for the AI assistant')
            .tools(testTools)
            .text('Additional context and guidelines')
            .text('Final instructions')
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // All text should be merged
        final expectedContent = 'System instructions for the AI assistant\n'
            'Additional context and guidelines\n'
            'Final instructions';

        expect(complexMessage.content, equals(expectedContent));
        expect(complexMessage.hasExtension('anthropic'), isTrue);

        final anthropicData = complexMessage.getExtension<Map<String, dynamic>>('anthropic')!;
        final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>;

        // Should have cache marker and tools block
        expect(contentBlocks.length, equals(2));

        // Verify both tools and text are cached together
        final hasToolsBlock = contentBlocks.any((block) =>
            block is Map<String, dynamic> && block['type'] == 'tools');
        final hasCacheMarker = contentBlocks.any((block) =>
            block is Map<String, dynamic> && block['cache_control'] != null);

        expect(hasToolsBlock, isTrue);
        expect(hasCacheMarker, isTrue);

        print('Tools caching with mixed content types - validated');
      });
    });

    group('User Control and Granularity Tests', () {
      test('Users can control caching by creating separate MessageBuilders', () {
        // Demonstrate how users control caching granularity

        // Scenario: Chat application with system prompt, context, and user input

        // 1. Static system prompt - cache for 1 hour
        final systemPrompt = MessageBuilder.system()
            .text('You are a helpful AI assistant.')
            .text('You have access to search and weather tools.')
            .tools(testTools)
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        // 2. Document context - cache for 5 minutes (changes less frequently)
        final documentContext = MessageBuilder.user()
            .text('Context: Here is the document you should reference:')
            .text('[LARGE DOCUMENT CONTENT...]')
            .text('Please use this document to answer questions.')
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .build();

        // 3. User question - no caching (changes every request)
        final userQuestion = MessageBuilder.user()
            .text('What is the main topic of the document?')
            .build();

        // Verify caching states
        expect(systemPrompt.hasExtension('anthropic'), isTrue);
        expect(documentContext.hasExtension('anthropic'), isTrue);
        expect(userQuestion.hasExtension('anthropic'), isFalse);

        // Verify content merging in cached messages
        expect(systemPrompt.content, contains('You are a helpful AI assistant'));
        expect(systemPrompt.content, contains('You have access to search'));
        expect(documentContext.content, contains('Context: Here is the document'));
        expect(documentContext.content, contains('[LARGE DOCUMENT CONTENT...]'));

        print('Users can control caching by creating separate MessageBuilders - validated');
      });

      test('Complex conversation with mixed caching strategies', () {
        // Demonstrate a realistic conversation with different caching needs

        final conversation = <ChatMessage>[];

        // 1. System message with tools - long-term cache
        conversation.add(MessageBuilder.system()
            .text('You are an expert research assistant.')
            .text('Use the provided tools to help users with their research.')
            .tools(testTools)
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build());

        // 2. Large context document - medium-term cache
        conversation.add(MessageBuilder.user()
            .text('Please analyze this research paper:')
            .text('[FULL RESEARCH PAPER CONTENT - 50 pages]')
            .text('Focus on the methodology and conclusions.')
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .build());

        // 3. Assistant response - no cache (generated content)
        conversation.add(MessageBuilder.assistant()
            .text('I\'ve analyzed the research paper. Here are the key findings...')
            .build());

        // 4. Follow-up question - no cache (user-specific)
        conversation.add(MessageBuilder.user()
            .text('Can you explain the statistical methods used?')
            .build());

        // 5. Context for follow-up - short-term cache
        conversation.add(MessageBuilder.user()
            .text('For reference, I\'m particularly interested in:')
            .text('- Sample size calculations')
            .text('- Statistical significance tests')
            .text('- Confidence intervals')
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
            .build());

        // Verify the conversation structure
        expect(conversation.length, equals(5));
        expect(conversation[0].hasExtension('anthropic'), isTrue); // System with tools
        expect(conversation[1].hasExtension('anthropic'), isTrue); // Large document
        expect(conversation[2].hasExtension('anthropic'), isFalse); // Assistant response
        expect(conversation[3].hasExtension('anthropic'), isFalse); // User question
        expect(conversation[4].hasExtension('anthropic'), isTrue); // Context list

        print('Complex conversation with mixed caching strategies - validated');
      });
    });

    group('API Request Structure Validation', () {
      test('Tools caching should apply cache_control to last tool in API request', () {
        // Test that tools caching produces correct API structure
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

        // Convert tools to API format and apply cache control
        final convertedTools = messageTools.map((t) => {
          'type': t.toolType,
          'function': t.function.toJson(),
        }).toList();

        if (toolCacheControl != null && convertedTools.isNotEmpty) {
          convertedTools.last['cache_control'] = toolCacheControl;
        }

        // Verify API structure
        expect(convertedTools.length, equals(2));
        expect(convertedTools.last.containsKey('cache_control'), isTrue);

        final cacheControl = convertedTools.last['cache_control'] as Map<String, dynamic>;
        expect(cacheControl['type'], equals('ephemeral'));
        expect(cacheControl['ttl'], equals('1h'));

        print('Tools caching API structure validated');
      });

      test('System message with cache should produce correct API structure', () {
        final message = MessageBuilder.system()
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .tools(testTools)
            .build();

        final messages = [message];

        // Simulate _buildRequestBody logic for tools
        Map<String, dynamic>? toolCacheControl;
        final messageTools = <Tool>[];

        for (final msg in messages) {
          final anthropicData = msg.getExtension<Map<String, dynamic>>('anthropic');
          if (anthropicData != null) {
            final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
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

        // Convert tools and apply cache control
        final convertedTools = messageTools.map((t) => {
          'type': t.toolType,
          'function': t.function.toJson(),
        }).toList();

        if (toolCacheControl != null && convertedTools.isNotEmpty) {
          convertedTools.last['cache_control'] = toolCacheControl;
        }

        // Verify cache_control is applied to last tool
        expect(convertedTools.isNotEmpty, isTrue);
        expect(convertedTools.last.containsKey('cache_control'), isTrue);
        final lastToolCacheControl = convertedTools.last['cache_control'] as Map<String, dynamic>;
        expect(lastToolCacheControl['type'], equals('ephemeral'));
        expect(lastToolCacheControl['ttl'], equals('1h'));

        print('Tools caching API structure validated');
      });
    });

    group('Edge Cases and Validation', () {
      test('MessageBuilder without cache should not have anthropic extensions', () {
        final message = MessageBuilder.system()
            .text('Regular system message')
            .tools(testTools)
            .text('No caching applied')
            .build();

        expect(message.hasExtension('anthropic'), isFalse);
        expect(message.content, contains('Regular system message'));
        expect(message.content, contains('No caching applied'));

        print('MessageBuilder without cache has no anthropic extensions - validated');
      });

      test('Empty MessageBuilder with cache should handle gracefully', () {
        final message = MessageBuilder.system()
            .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
            .build();

        expect(message.content, isEmpty);
        expect(message.hasExtension('anthropic'), isTrue);

        final anthropicData = message.getExtension<Map<String, dynamic>>('anthropic')!;
        final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>;

        // Should have cache marker even with empty content
        expect(contentBlocks.length, equals(1));
        final cacheMarker = contentBlocks.first as Map<String, dynamic>;
        expect(cacheMarker['cache_control'], isNotNull);

        print('Empty MessageBuilder with cache handled gracefully - validated');
      });

      test('Different TTL values should be preserved correctly', () {
        final messages = [
          MessageBuilder.system()
              .text('5-minute cache')
              .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
              .build(),
          MessageBuilder.user()
              .text('1-hour cache')
              .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
              .build(),
          MessageBuilder.assistant()
              .text('Default cache')
              .anthropicConfig((anthropic) => anthropic.cache())
              .build(),
        ];

        // Verify TTL values
        final data5m = messages[0].getExtension<Map<String, dynamic>>('anthropic')!;
        final blocks5m = data5m['contentBlocks'] as List<dynamic>;
        final cache5m = (blocks5m.first as Map<String, dynamic>)['cache_control'];
        expect(cache5m['ttl'], equals('5m'));

        final data1h = messages[1].getExtension<Map<String, dynamic>>('anthropic')!;
        final blocks1h = data1h['contentBlocks'] as List<dynamic>;
        final cache1h = (blocks1h.first as Map<String, dynamic>)['cache_control'];
        expect(cache1h['ttl'], equals('1h'));

        final dataDefault = messages[2].getExtension<Map<String, dynamic>>('anthropic')!;
        final blocksDefault = dataDefault['contentBlocks'] as List<dynamic>;
        final cacheDefault = (blocksDefault.first as Map<String, dynamic>)['cache_control'];
        expect(cacheDefault.containsKey('ttl'), isFalse);

        print('Different TTL values preserved correctly - validated');
      });
    });
  });
}
