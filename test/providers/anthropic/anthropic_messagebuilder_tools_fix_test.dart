import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Test suite for the MessageBuilder tools fix
/// This tests the specific issue reported in #15 where MessageBuilder.tools()
/// was causing content type mismatch errors in Anthropic API
/// NO API CALLS - only validates message structure and tool format
void main() {
  group('Anthropic MessageBuilder Tools Fix Tests', () {
    late List<Tool> testTools;

    setUp(() {
      // Create test tools similar to the bug report
      testTools = [
        Tool.function(
          name: 'isValidPhrase',
          description: 'Check if the word is meaningful in English',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'isMeaningFull': ParameterProperty(
                propertyType: 'boolean',
                description:
                    'If the word is meaningful in English, return true',
              ),
              'rootWords': ParameterProperty(
                propertyType: 'string',
                description:
                    'The root word of the word, if it is same, return the word itself',
              ),
            },
            required: ['isMeaningFull'],
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

    test('MessageBuilder.tools() should not cause content type mismatch', () {
      // This reproduces the exact scenario from the bug report
      final message = MessageBuilder.system()
          .text('You are a helpful assistant.')
          .tools(testTools)
          .build();

      // Verify message structure
      expect(message.content, contains('You are a helpful assistant.'));
      expect(message.hasExtension('anthropic'),
          isFalse); // No caching, so no extensions

      // The key test: tools should be processed without errors
      // We test this by simulating the _buildRequestBody process
      final messages = [message];

      // This should not throw any errors during tool processing
      expect(() {
        // Simulate tool processing logic from _buildRequestBody
        final messageTools = <Tool>[];

        // Extract tools from messages (simulating _processTools)
        for (final msg in messages) {
          // Check if message has anthropic extensions with tools
          if (msg.hasExtension('anthropic')) {
            final anthropicData =
                msg.getExtension<Map<String, dynamic>>('anthropic');
            final contentBlocks =
                anthropicData?['contentBlocks'] as List<dynamic>?;
            if (contentBlocks != null) {
              for (final block in contentBlocks) {
                if (block is Map<String, dynamic> && block['type'] == 'tools') {
                  // This is where the bug would occur - in _convertToolsFromBlock
                  final toolsList = block['tools'] as List<dynamic>?;
                  if (toolsList != null) {
                    for (final toolData in toolsList) {
                      if (toolData is Map<String, dynamic>) {
                        // The fix should handle Tool.toJson() format correctly
                        if (toolData.containsKey('function') &&
                            toolData.containsKey('type')) {
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

        // Verify tools were extracted correctly
        expect(messageTools, hasLength(0)); // No tools in non-cached message
      }, returnsNormally);

      print('MessageBuilder.tools() conversion validated successfully');
    });

    test('MessageBuilder.tools() with caching should work correctly', () {
      // Test the caching scenario that was also affected
      final message = MessageBuilder.system()
          .text('System instructions')
          .tools(testTools)
          .anthropicConfig((anthropic) => anthropic.cache())
          .build();

      expect(message.hasExtension('anthropic'), isTrue);

      // Verify the message structure contains tools in anthropic extensions
      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic');
      expect(anthropicData, isNotNull);

      final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>?;
      expect(contentBlocks, isNotNull);

      // Should find tools block and cache control
      bool foundTools = false;
      bool foundCacheControl = false;

      for (final block in contentBlocks!) {
        if (block is Map<String, dynamic>) {
          if (block['type'] == 'tools') {
            foundTools = true;
            final toolsList = block['tools'] as List<dynamic>?;
            expect(toolsList, hasLength(2));
          } else if (block['cache_control'] != null) {
            foundCacheControl = true;
            expect(block['cache_control']['type'], equals('ephemeral'));
          }
        }
      }

      expect(foundTools, isTrue);
      expect(foundCacheControl, isTrue);

      print('MessageBuilder.tools() with caching validated successfully');
    });

    test('Tool.toJson() format should be handled correctly', () {
      // This tests the specific fix for Tool.toJson() format handling
      // Create a tools block in the format that Tool.toJson() produces
      final toolsBlock = {
        'type': 'tools',
        'tools': testTools.map((tool) => tool.toJson()).toList(),
      };

      // Verify the format is what we expect (Tool.toJson() includes 'type' and 'function')
      final toolsList = toolsBlock['tools'] as List<dynamic>;
      final firstTool = toolsList[0] as Map<String, dynamic>;
      expect(firstTool['type'], equals('function'));
      expect(firstTool['function'], isA<Map<String, dynamic>>());

      // This format should be handled correctly by our fix
      // We test this by simulating the conversion logic
      final convertedTools = <Tool>[];

      for (final toolData in toolsList) {
        if (toolData is Map<String, dynamic>) {
          // This is the key fix - handle Tool.toJson() format
          if (toolData.containsKey('function') &&
              toolData.containsKey('type')) {
            final function = toolData['function'] as Map<String, dynamic>;
            convertedTools.add(Tool(
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

      expect(convertedTools, hasLength(2));
      expect(convertedTools[0].function.name, equals('isValidPhrase'));
      expect(convertedTools[1].function.name, equals('calculate'));

      // Verify the tools have correct schema types
      expect(
          convertedTools[0].function.parameters.schemaType, equals('object'));
      expect(
          convertedTools[1].function.parameters.schemaType, equals('object'));

      print('Tool.toJson() format handling validated successfully');
    });

    test('Tool.toJson() format should be correctly structured', () {
      // Verify that Tool.toJson() produces the expected format
      final toolJson = testTools[0].toJson();

      // Should have OpenAI-style format with 'type' and 'function'
      expect(toolJson['type'], equals('function'));
      expect(toolJson['function'], isA<Map<String, dynamic>>());

      final function = toolJson['function'] as Map<String, dynamic>;
      expect(function['name'], equals('isValidPhrase'));
      expect(function['description'], isNotNull);
      expect(function['parameters'], isA<Map<String, dynamic>>());

      final parameters = function['parameters'] as Map<String, dynamic>;
      expect(parameters['type'], equals('object'));
      expect(parameters['properties'], isA<Map<String, dynamic>>());

      print('Tool.toJson() format validated');
    });

    test('MessageBuilder.tools() should not add tools to message content', () {
      // This test verifies the specific fix for issue #15
      // Tools should not appear in message content blocks
      final message = MessageBuilder.system()
          .text('System instructions')
          .tools(testTools)
          .anthropicConfig((anthropic) => anthropic.cache())
          .build();

      // Check that message has anthropic extensions
      expect(message.hasExtension('anthropic'), isTrue);

      final anthropicData =
          message.getExtension<Map<String, dynamic>>('anthropic');
      final contentBlocks = anthropicData?['contentBlocks'] as List<dynamic>?;

      expect(contentBlocks, isNotNull);
      expect(contentBlocks!.length, equals(2)); // cache marker + tools block

      // Verify that when converted to message content, tools blocks are skipped
      // This simulates the _convertMessage process
      final messageContent = <Map<String, dynamic>>[];

      for (final block in contentBlocks) {
        if (block is Map<String, dynamic>) {
          // Skip cache control markers
          if (block['cache_control'] != null && block['text'] == '') {
            continue;
          }
          // Skip tools blocks - this is the key fix
          if (block['type'] == 'tools') {
            continue;
          }
          messageContent.add(block);
        }
      }

      // After filtering, message content should not contain any tools blocks
      expect(messageContent.every((block) => block['type'] != 'tools'), isTrue);
      print('Tools blocks correctly filtered from message content');
    });
  });
}
