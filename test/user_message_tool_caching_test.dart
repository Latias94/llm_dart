import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'test_utils/model_message_test_extensions.dart';

/// Test suite for user message tool caching functionality
/// This addresses the issue reported by okandemirofficial
void main() {
  group('User Message Tool Caching Tests', () {
    late Tool testTool;

    setUp(() {
      testTool = Tool.function(
        name: 'get_weather',
        description: 'Get weather information',
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

    test('User message with cached tools should work', () {
      // This is the exact case from the bug report
      final content = "What's the weather like today?";
      final message = MessageBuilder.user()
          .anthropicConfig(
            (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes),
          )
          .text(content)
          .tools([testTool]).build();

      // Verify message structure
      expect(message.content, equals(content));
      expect(message.hasExtension('anthropic'), isTrue);

      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic');
      expect(anthropicData, isNotNull);

      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
      expect(contentBlocks.length, equals(2)); // Cache marker + tools block

      // Find cache marker
      final cacheMarker = contentBlocks.firstWhere((block) =>
          block is Map<String, dynamic> &&
          block['cache_control'] != null &&
          block['text'] == '') as Map<String, dynamic>;

      expect(cacheMarker['cache_control']['type'], equals('ephemeral'));
      expect(cacheMarker['cache_control']['ttl'], equals('5m'));

      // Find tools block
      final toolsBlock = contentBlocks.firstWhere((block) =>
              block is Map<String, dynamic> && block['type'] == 'tools')
          as Map<String, dynamic>;

      expect(toolsBlock['type'], equals('tools'));
      expect(toolsBlock['tools'], isA<List>());
      expect((toolsBlock['tools'] as List).length, equals(1));

      print('User message tool caching structure validated');
    });

    test('Mixed messages with tool caching should work', () {
      // System message with cached tools
      final systemMessage = MessageBuilder.system()
          .text('You are a helpful assistant.')
          .anthropicConfig(
            (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour),
          )
          .tools([testTool]).build();

      // User message with cached tools
      final userMessage = MessageBuilder.user()
          .anthropicConfig(
            (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes),
          )
          .text("What's the weather?")
          .tools([testTool]).build();

      final messages = [systemMessage, userMessage];

      // Simulate _buildRequestBody logic to verify cache control extraction
      Map<String, dynamic>? toolCacheControl;
      var toolsFound = 0;

      for (final message in messages) {
        final anthropicData =
            message.getExtension<Map<String, dynamic>>('anthropic');
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
                    toolsFound += toolsList.length;
                  }
                }
              }
            }
          }
        }
      }

      // Should find cache control and tools
      expect(toolCacheControl, isNotNull);
      expect(toolsFound, greaterThan(0));

      // The last cache control found should be from the user message (5m)
      expect(toolCacheControl!['ttl'], equals('5m'));

      print('Mixed messages tool caching validated');
    });

    test('Tool caching should apply to API request structure', () {
      final message = MessageBuilder.user()
          .anthropicConfig(
            (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes),
          )
          .text("Test message")
          .tools([testTool]).build();

      final messages = [message];

      // Simulate the complete _buildRequestBody logic
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

      // Apply cache control to tools (simulate API request building)
      expect(messageTools.isNotEmpty, isTrue);
      expect(toolCacheControl, isNotNull);

      final convertedTools = messageTools
          .map((t) => {
                'type': t.toolType,
                'function': t.function.toJson(),
              })
          .toList();

      if (toolCacheControl != null && convertedTools.isNotEmpty) {
        convertedTools.last['cache_control'] = toolCacheControl;
      }

      // Verify the final API structure has cache_control
      expect(convertedTools.last.containsKey('cache_control'), isTrue);
      final lastToolCacheControl =
          convertedTools.last['cache_control'] as Map<String, dynamic>;
      expect(lastToolCacheControl['type'], equals('ephemeral'));
      expect(lastToolCacheControl['ttl'], equals('5m'));

      print('API request structure with tool caching validated');
    });
  });
}
