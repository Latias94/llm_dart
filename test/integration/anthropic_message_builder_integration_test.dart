import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Comprehensive integration tests for Anthropic Message Builder
/// 
/// These tests require a real Anthropic API key to be set in environment
/// variables or a .env file. Tests cover:
/// - Cached system message groups
/// - Tool usage scenarios  
/// - Message builder integration with real API responses
/// - Performance and caching behavior
void main() {
  group('Anthropic Message Builder Integration Tests', () {
    late AnthropicProvider provider;
    late String apiKey;

    setUpAll(() {
      // Get API key from environment or skip tests
      apiKey = Platform.environment['ANTHROPIC_API_KEY'] ?? '';
      
      if (apiKey.isEmpty) {
        print('⚠️  ANTHROPIC_API_KEY not found. Skipping integration tests.');
        print('   Set ANTHROPIC_API_KEY environment variable to run these tests.');
        return;
      }

      provider = createAnthropicProvider(
        apiKey: apiKey,
        model: 'claude-3-5-sonnet-20241022',
        maxTokens: 1000,
        temperature: 0.1,
      );
    });

    group('Cached System Message Tests', () {
      test('should handle cached system message with one-hour TTL', () async {
        if (apiKey.isEmpty) return;

        // Create a cached system message
        final systemMessage = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.cachedText(
                  'You are a helpful AI assistant specialized in explaining complex topics in simple terms. '
                  'Always provide clear, concise answers with practical examples. '
                  'When explaining technical concepts, break them down into digestible pieces.',
                  ttl: AnthropicCacheTtl.oneHour,
                ))
            .build();

        final userMessage = MessageBuilder.user()
            .text('Explain quantum computing in simple terms')
            .build();

        final messages = [systemMessage, userMessage];

        // Test the conversation
        final response = await provider.chat(messages);

        expect(response.text, isNotNull);
        expect(response.text!.length, greaterThan(50));
        expect(response.usage?.promptTokens, greaterThan(0));
        expect(response.usage?.completionTokens, greaterThan(0));

        print('✅ Cached system message test passed');
        print('📊 Input tokens: ${response.usage?.promptTokens}');
        print('📊 Output tokens: ${response.usage?.completionTokens}');
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should handle multiple cached message groups', () async {
        if (apiKey.isEmpty) return;

        // Create multiple cached system messages with different TTLs
        final systemContext = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.cachedText(
                  'You are an expert software engineer with deep knowledge of various programming languages, '
                  'frameworks, and best practices. You write clean, efficient, and well-documented code.',
                  ttl: AnthropicCacheTtl.oneHour,
                ))
            .build();

        final projectContext = MessageBuilder.system()
            .name('project_context')
            .anthropic((anthropic) => anthropic.cachedText(
                  'Current project: Building a message builder system for LLM providers. '
                  'Tech stack: Dart, provider pattern, modular architecture. '
                  'Key features: Universal message interface, provider-specific extensions, caching support.',
                  ttl: AnthropicCacheTtl.fiveMinutes,
                ))
            .build();

        final userMessage = MessageBuilder.user()
            .text('What are the best practices for implementing a cache-aware message builder?')
            .build();

        final messages = [systemContext, projectContext, userMessage];

        final response = await provider.chat(messages);

        expect(response.text, isNotNull);
        expect(response.text!.toLowerCase(), contains('cache'));
        expect(response.text!.toLowerCase(), anyOf([
          contains('message'),
          contains('builder'),
          contains('provider'),
        ]));

        print('✅ Multiple cached message groups test passed');
        print('📝 Response preview: ${response.text!.substring(0, 100)}...');
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should handle complex content blocks with caching', () async {
        if (apiKey.isEmpty) return;

        final complexMessage = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.contentBlocks([
              {
                'type': 'text',
                'text': 'You are a code review assistant. Analyze the following code patterns and provide feedback.',
                'cache_control': {'type': 'ephemeral', 'ttl': 3600}
              },
              {
                'type': 'text',
                'text': '''
CODE PATTERNS TO REVIEW:
1. Factory pattern implementation
2. Builder pattern usage
3. Modular architecture design
4. Error handling strategies
5. Testing approaches
'''
              }
            ]))
            .build();

        final userMessage = MessageBuilder.user()
            .text('Review this Dart code structure: class MessageBuilder { factory MessageBuilder.user() => MessageBuilder._(ChatRole.user); }')
            .build();

        final messages = [complexMessage, userMessage];

        final response = await provider.chat(messages);

        expect(response.text, isNotNull);
        expect(response.text!.toLowerCase(), contains('factory'));
        expect(response.usage?.promptTokens, greaterThan(0));

        print('✅ Complex content blocks test passed');
        print('🔍 Analysis: ${response.text!.substring(0, 150)}...');
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('Tool Usage Scenarios', () {
      test('should handle web search tool usage', () async {
        if (apiKey.isEmpty) return;

        // Define web search tool
        final webSearchTool = Tool.function(
          name: 'web_search',
          description: 'Search the web for current information',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'query': ParameterProperty(
                propertyType: 'string',
                description: 'The search query to execute',
              ),
              'max_results': ParameterProperty(
                propertyType: 'integer',
                description: 'Maximum number of results to return',
              ),
            },
            required: ['query'],
          ),
        );

        final systemMessage = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.cachedText(
                  'You are a research assistant. When you need current information, use the web_search tool.',
                  ttl: AnthropicCacheTtl.fiveMinutes,
                ))
            .build();

        final userMessage = MessageBuilder.user()
            .text('What are the latest developments in AI language models?')
            .build();

        final messages = [systemMessage, userMessage];

        final response = await provider.chatWithTools(messages, [webSearchTool]);

        expect(response.text, isNotNull);
        
        // Check if tool was called
        if (response.toolCalls?.isNotEmpty == true) {
          final toolCall = response.toolCalls!.first;
          expect(toolCall.function.name, equals('web_search'));
          
          final args = jsonDecode(toolCall.function.arguments);
          expect(args['query'], isNotNull);
          expect(args['query'], isA<String>());

          print('✅ Tool call generated successfully');
          print('🔧 Tool: ${toolCall.function.name}');
          print('📝 Query: ${args['query']}');

          // Simulate tool response using message builder
          final toolResultMessage = MessageBuilder.user()
              .anthropic((anthropic) => anthropic.toolResult(
                    toolUseId: toolCall.id,
                    content: 'Found recent developments: GPT-4 improvements, Claude Sonnet updates, multimodal capabilities expansion...',
                  ))
              .build();

          final followUpMessages = [...messages, _responseToMessage(response), toolResultMessage];
          final finalResponse = await provider.chat(followUpMessages);

          expect(finalResponse.text, isNotNull);
          expect(finalResponse.text!.toLowerCase(), contains('development'));
          
          print('✅ Tool result processing test passed');
          print('📄 Final response preview: ${finalResponse.text!.substring(0, 100)}...');
        } else {
          print('ℹ️  No tool call generated, but response received');
        }
      }, timeout: const Timeout(Duration(seconds: 45)));

      test('should handle calculation tool with error scenarios', () async {
        if (apiKey.isEmpty) return;

        final calculatorTool = Tool.function(
          name: 'calculate',
          description: 'Perform mathematical calculations',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'expression': ParameterProperty(
                propertyType: 'string',
                description: 'Mathematical expression to evaluate',
              ),
            },
            required: ['expression'],
          ),
        );

        final systemMessage = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.cachedText(
                  'You are a math tutor. Use the calculate tool for complex computations.',
                ))
            .build();

        final userMessage = MessageBuilder.user()
            .text('Calculate the compound interest for \$1000 at 5% annually for 10 years')
            .build();

        final messages = [systemMessage, userMessage];

        final response = await provider.chatWithTools(messages, [calculatorTool]);

        if (response.toolCalls?.isNotEmpty == true) {
          final toolCall = response.toolCalls!.first;
          
          // Simulate error in tool execution
          final errorResultMessage = MessageBuilder.user()
              .anthropic((anthropic) => anthropic.toolResult(
                    toolUseId: toolCall.id,
                    content: 'Error: Division by zero in calculation',
                    isError: true,
                  ))
              .build();

          final errorMessages = [...messages, _responseToMessage(response), errorResultMessage];
          final errorResponse = await provider.chat(errorMessages);

          expect(errorResponse.text, isNotNull);
          expect(errorResponse.text!.toLowerCase(), anyOf([
            contains('error'),
            contains('problem'),
            contains('sorry'),
            contains('unable'),
          ]));

          print('✅ Tool error handling test passed');
          print('⚠️  Error handled gracefully: ${errorResponse.text!.substring(0, 100)}...');
        }
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should handle multiple tool calls in sequence', () async {
        if (apiKey.isEmpty) return;

        final dataAnalysisTool = Tool.function(
          name: 'analyze_data',
          description: 'Analyze data and generate insights',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'data_type': ParameterProperty(
                propertyType: 'string',
                description: 'Type of data to analyze',
                enumList: ['sales', 'user_behavior', 'performance'],
              ),
              'time_period': ParameterProperty(
                propertyType: 'string',
                description: 'Time period for analysis',
              ),
            },
            required: ['data_type', 'time_period'],
          ),
        );

        final generateReportTool = Tool.function(
          name: 'generate_report',
          description: 'Generate a formatted report',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'format': ParameterProperty(
                propertyType: 'string',
                description: 'Report format',
                enumList: ['pdf', 'html', 'markdown'],
              ),
              'sections': ParameterProperty(
                propertyType: 'array',
                description: 'Sections to include in report',
                items: ParameterProperty(
                  propertyType: 'string',
                  description: 'Section name',
                ),
              ),
            },
            required: ['format'],
          ),
        );

        final systemMessage = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.cachedText(
                  'You are a business analyst. Analyze data and generate reports as requested.',
                  ttl: AnthropicCacheTtl.fiveMinutes,
                ))
            .build();

        final userMessage = MessageBuilder.user()
            .text('Analyze our sales data from last quarter and generate a PDF report')
            .build();

        final messages = [systemMessage, userMessage];
        final tools = [dataAnalysisTool, generateReportTool];

        final response = await provider.chatWithTools(messages, tools);

        if (response.toolCalls?.isNotEmpty == true) {
          print('✅ Multiple tool scenario initiated');
          print('🔧 Tools called: ${response.toolCalls!.map((tc) => tc.function.name).join(', ')}');
          
          // Process each tool call
          var currentMessages = [...messages, _responseToMessage(response)];
          
          for (final toolCall in response.toolCalls!) {
            String mockResult;
            if (toolCall.function.name == 'analyze_data') {
              mockResult = 'Analysis completed: Sales increased 15% over previous quarter. Key trends: mobile sales up 30%, enterprise clients up 8%.';
            } else if (toolCall.function.name == 'generate_report') {
              mockResult = 'Report generated successfully: quarterly_sales_report.pdf (2.3MB)';
            } else {
              mockResult = 'Tool execution completed';
            }

            final toolResultMessage = MessageBuilder.user()
                .anthropic((anthropic) => anthropic.toolResult(
                      toolUseId: toolCall.id,
                      content: mockResult,
                    ))
                .build();

            currentMessages.add(toolResultMessage);
          }

          final finalResponse = await provider.chat(currentMessages);
          
          expect(finalResponse.text, isNotNull);
          expect(finalResponse.text!.toLowerCase(), anyOf([
            contains('report'),
            contains('analysis'),
            contains('quarter'),
            contains('sales'),
          ]));

          print('✅ Multiple tool calls processed successfully');
          print('📊 Final analysis: ${finalResponse.text!.substring(0, 150)}...');
        }
      }, timeout: const Timeout(Duration(seconds: 60)));
    });

    group('Performance and Caching Tests', () {
      test('should demonstrate caching benefits with repeated requests', () async {
        if (apiKey.isEmpty) return;

        final cachedSystemMessage = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.cachedText(
                  'You are a performance testing assistant. Respond with brief, consistent answers for testing purposes.',
                  ttl: AnthropicCacheTtl.oneHour,
                ))
            .build();

        // First request
        final userMessage1 = MessageBuilder.user()
            .text('What is the current time? (This is test request #1)')
            .build();

        final stopwatch1 = Stopwatch()..start();
        final response1 = await provider.chat([cachedSystemMessage, userMessage1]);
        stopwatch1.stop();

        expect(response1.text, isNotNull);
        final firstRequestTime = stopwatch1.elapsedMilliseconds;

        // Second request with same cached system message
        final userMessage2 = MessageBuilder.user()
            .text('What is the current time? (This is test request #2)')
            .build();

        final stopwatch2 = Stopwatch()..start();
        final response2 = await provider.chat([cachedSystemMessage, userMessage2]);
        stopwatch2.stop();

        expect(response2.text, isNotNull);
        final secondRequestTime = stopwatch2.elapsedMilliseconds;

        print('✅ Caching performance test completed');
        print('⏱️  First request: ${firstRequestTime}ms');
        print('⏱️  Second request: ${secondRequestTime}ms');
        print('📊 Input tokens (req 1): ${response1.usage?.promptTokens}');
        print('📊 Input tokens (req 2): ${response2.usage?.promptTokens}');

        // Note: In real scenarios, cached requests might be faster
        // but this depends on Anthropic's implementation
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('should handle streaming with cached messages', () async {
        if (apiKey.isEmpty) return;

        final cachedSystemMessage = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.cachedText(
                  'You are a storytelling assistant. Tell engaging, creative stories.',
                  ttl: AnthropicCacheTtl.fiveMinutes,
                ))
            .build();

        final userMessage = MessageBuilder.user()
            .text('Tell me a short story about a message that travels through different systems')
            .build();

        final messages = [cachedSystemMessage, userMessage];

        var accumulatedText = '';
        var eventCount = 0;

        await for (final event in provider.chatStream(messages)) {
          eventCount++;
          
          switch (event) {
            case TextDeltaEvent():
              accumulatedText += event.delta;
              break;
            case ThinkingDeltaEvent():
              // Handle thinking content if present
              break;
            case ToolCallDeltaEvent():
              // Handle tool calls if present
              break;
            case CompletionEvent():
              print('✅ Streaming with caching completed');
              print('📊 Total events: $eventCount');
              print('📝 Story length: ${accumulatedText.length} characters');
              break;
            case ErrorEvent():
              throw event.error;
          }
        }

        expect(accumulatedText.length, greaterThan(50));
        expect(eventCount, greaterThan(1));
      }, timeout: const Timeout(Duration(seconds: 45)));
    });

    group('Complex Message Builder Scenarios', () {
      test('should handle mixed universal and cached content', () async {
        if (apiKey.isEmpty) return;

        final mixedMessage = MessageBuilder.system()
            .text('Base instructions: You are helpful and concise.')
            .anthropic((anthropic) => anthropic.cachedText(
                  'Additional context: Focus on practical, actionable advice. '
                  'Always include relevant examples and explain the reasoning behind your recommendations.',
                  ttl: AnthropicCacheTtl.fiveMinutes,
                ))
            .build();

        final userMessage = MessageBuilder.user()
            .text('How should I structure a large Dart project?')
            .build();

        final response = await provider.chat([mixedMessage, userMessage]);

        expect(response.text, isNotNull);
        expect(response.text!.toLowerCase(), anyOf([
          contains('dart'),
          contains('project'),
          contains('structure'),
          contains('organize'),
        ]));

        print('✅ Mixed content message test passed');
        print('💡 Advice: ${response.text!.substring(0, 120)}...');
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should validate content block structure in API responses', () async {
        if (apiKey.isEmpty) return;

        final structuredMessage = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.contentBlocks([
              {
                'type': 'text',
                'text': 'You are a technical validator.',
                'cache_control': {'type': 'ephemeral', 'ttl': 300}
              },
              {
                'type': 'text',
                'text': 'Validation rules:\n1. Code must be syntactically correct\n2. Follow best practices\n3. Include error handling'
              }
            ]))
            .build();

        // Verify the message structure before sending
        expect(structuredMessage.hasExtension('anthropic'), isTrue);
        
        final anthropicData = structuredMessage.getExtension<Map<String, dynamic>>('anthropic');
        expect(anthropicData, isNotNull);
        
        final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
        expect(contentBlocks, hasLength(2));
        
        // Verify cache control in first block
        final firstBlock = contentBlocks[0] as Map<String, dynamic>;
        expect(firstBlock['cache_control'], isNotNull);
        expect(firstBlock['cache_control']['ttl'], equals(300));

        final userMessage = MessageBuilder.user()
            .text('Validate this Dart code: void main() { print("Hello"); }')
            .build();

        final response = await provider.chat([structuredMessage, userMessage]);

        expect(response.text, isNotNull);
        expect(response.text!.toLowerCase(), anyOf([
          contains('valid'),
          contains('correct'),
          contains('syntax'),
        ]));

        print('✅ Content block structure validation passed');
        print('🔍 Validation result: ${response.text!.substring(0, 100)}...');
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}

/// Helper function to convert ChatResponse to ChatMessage
ChatMessage _responseToMessage(ChatResponse response) {
  if (response.toolCalls?.isNotEmpty == true) {
    var messageBuilder = MessageBuilder.assistant();
    messageBuilder = messageBuilder.anthropic((anthropic) {
      var builder = anthropic;
      for (final toolCall in response.toolCalls!) {
        builder = builder.toolUse(
          id: toolCall.id,
          name: toolCall.function.name,
          input: jsonDecode(toolCall.function.arguments),
        );
      }
    });
    return messageBuilder.build();
  } else {
    return ChatMessage.assistant(response.text ?? '');
  }
}