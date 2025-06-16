import 'dart:convert';

import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

import 'anthropic_test_helpers.dart';

/// Advanced integration tests for edge cases and performance scenarios
void main() {
  group('Anthropic Advanced Scenarios', () {
    late AnthropicProvider provider;

    setUpAll(() {
      if (!AnthropicTestHelpers.canRunIntegrationTests) {
        AnthropicTestHelpers.printSkipMessage();
        return;
      }

      provider = AnthropicTestHelpers.createTestProvider();
    });

    group('Edge Cases and Error Handling', () {
      test('should handle very long cached content', () async {
        if (!AnthropicTestHelpers.canRunIntegrationTests) return;

        // Create a very long system message to test caching limits
        final longContent = List.generate(100, (i) => 
          'This is paragraph $i of a very long system message that tests the caching '
          'behavior with large content blocks. It contains detailed instructions and '
          'context that should be cached efficiently by the Anthropic API.'
        ).join('\n\n');

        final longCachedMessage = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.cachedText(
                  longContent,
                  ttl: AnthropicCacheTtl.oneHour,
                ))
            .build();

        final userMessage = MessageBuilder.user()
            .text('Summarize the key points from your instructions.')
            .build();

        final response = await AnthropicTestHelpers.measureExecutionTime(
          () => provider.chat([longCachedMessage, userMessage]),
          operationName: 'Long cached content test',
        );

        AnthropicTestHelpers.assertResponseQuality(response);
        expect(response.text!.toLowerCase(), anyOf([
          contains('summarize'),
          contains('summary'),
          contains('key points'),
          contains('points'),
          contains('main'),
          contains('instructions'),
        ]));
        
        print('✅ Long cached content handled successfully');
        print('📏 System message length: ${longContent.length} characters');
      }, timeout: const Timeout(Duration(seconds: 45)));

      test('should handle malformed tool call gracefully', () async {
        if (!AnthropicTestHelpers.canRunIntegrationTests) return;

        final toolProvider = AnthropicTestHelpers.createToolTestProvider();

        final systemMessage = AnthropicTestHelpers.createCachedSystemMessage(
          content: 'You are a calculator assistant. Use the calculate tool for any math.',
        );

        final userMessage = MessageBuilder.user()
            .text('What is 15 × 23?')
            .build();

        final response = await toolProvider.chatWithTools(
          [systemMessage, userMessage],
          [TestTools.calculatorTool],
        );

        if (response.toolCalls?.isNotEmpty == true) {
          final toolCall = response.toolCalls!.first;
          
          // Simulate malformed tool response
          final malformedResult = MessageBuilder.user()
              .anthropic((anthropic) => anthropic.toolResult(
                    toolUseId: toolCall.id,
                    content: '{"error": "malformed_json", "partial_result": 345',
                    isError: true,
                  ))
              .build();

          final errorResponse = await toolProvider.chat([
            systemMessage,
            userMessage,
            _responseToMessage(response),
            malformedResult,
          ]);

          AnthropicTestHelpers.assertResponseQuality(errorResponse);
          expect(errorResponse.text!.toLowerCase(), anyOf([
            contains('error'),
            contains('problem'),
            contains('calculate'),
            contains('15'),
            contains('23'),
          ]));

          print('✅ Malformed tool response handled gracefully');
        }
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should handle empty cache control gracefully', () async {
        if (!AnthropicTestHelpers.canRunIntegrationTests) return;

        final messageWithEmptyCache = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.contentBlocks([
              {
                'type': 'text',
                'text': 'You are a test assistant.',
                'cache_control': {'type': 'ephemeral'} // No TTL specified
              }
            ]))
            .build();

        final userMessage = MessageBuilder.user()
            .text('Hello, can you respond?')
            .build();

        final response = await provider.chat([messageWithEmptyCache, userMessage]);

        AnthropicTestHelpers.assertResponseQuality(response);
        print('✅ Empty cache control handled without issues');
      }, timeout: const Timeout(Duration(seconds: 20)));
    });

    group('Performance and Scalability', () {
      test('should handle rapid sequential requests with caching', () async {
        if (!AnthropicTestHelpers.canRunIntegrationTests) return;

        final cachedSystem = AnthropicTestHelpers.createCachedSystemMessage(
          content: 'You are a quick response assistant. Give brief, one-sentence answers.',
          ttl: AnthropicCacheTtl.oneHour,
        );

        final requests = List.generate(5, (i) => MessageBuilder.user()
            .text('Quick question $i: What is ${i + 1} + ${i + 2}?')
            .build());

        final responses = <ChatResponse>[];

        for (int i = 0; i < requests.length; i++) {
          final result = await AnthropicTestHelpers.measureExecutionTime(
            () => provider.chat([cachedSystem, requests[i]]),
            operationName: 'Sequential request ${i + 1}',
          );
          
          responses.add(result);
          // Note: We can't directly measure API response time, but we can measure total time
        }

        // Verify all responses are valid
        for (final response in responses) {
          AnthropicTestHelpers.assertResponseQuality(response);
        }

        print('✅ Sequential requests with caching completed');
        print('📊 Average response length: ${responses.map((r) => r.text!.length).reduce((a, b) => a + b) ~/ responses.length} chars');
      }, timeout: const Timeout(Duration(seconds: 120)));

      test('should handle concurrent requests efficiently', () async {
        if (!AnthropicTestHelpers.canRunIntegrationTests) return;

        final sharedCachedSystem = AnthropicTestHelpers.createCachedSystemMessage(
          content: 'You are a concurrent processing assistant. Respond concisely.',
          ttl: AnthropicCacheTtl.fiveMinutes,
        );

        // Create multiple concurrent requests
        final futures = List.generate(3, (i) {
          final userMessage = MessageBuilder.user()
              .text('Concurrent request $i: Explain the concept of ${['caching', 'concurrency', 'scalability'][i]}')
              .build();
          
          return AnthropicTestHelpers.measureExecutionTime(
            () => provider.chat([sharedCachedSystem, userMessage]),
            operationName: 'Concurrent request $i',
          );
        });

        final responses = await Future.wait(futures);

        for (final response in responses) {
          AnthropicTestHelpers.assertResponseQuality(response);
        }

        print('✅ Concurrent requests completed successfully');
        print('🔄 Processed ${responses.length} concurrent requests');
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('should demonstrate cache warming and reuse', () async {
        if (!AnthropicTestHelpers.canRunIntegrationTests) return;

        // First, "warm" the cache with a comprehensive system message
        final comprehensiveSystem = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.cachedText(
                  'You are an expert software architect with deep knowledge of:\n'
                  '1. Distributed systems design\n'
                  '2. Microservices architecture\n'
                  '3. Database design and optimization\n'
                  '4. API design best practices\n'
                  '5. Performance optimization techniques\n'
                  '6. Security best practices\n'
                  'Always provide detailed, practical advice with examples.',
                  ttl: AnthropicCacheTtl.oneHour,
                ))
            .build();

        // Warm the cache
        final warmupMessage = MessageBuilder.user()
            .text('What are the key principles of good software architecture?')
            .build();

        final warmupResponse = await AnthropicTestHelpers.measureExecutionTime(
          () => provider.chat([comprehensiveSystem, warmupMessage]),
          operationName: 'Cache warmup',
        );

        AnthropicTestHelpers.assertResponseQuality(warmupResponse);

        // Now reuse the cached system message for different questions
        final reuseQuestions = [
          'How do you design a scalable API?',
          'What are database optimization strategies?',
          'Explain microservices trade-offs.',
        ];

        for (int i = 0; i < reuseQuestions.length; i++) {
          final question = MessageBuilder.user().text(reuseQuestions[i]).build();
          
          final response = await AnthropicTestHelpers.measureExecutionTime(
            () => provider.chat([comprehensiveSystem, question]),
            operationName: 'Cache reuse ${i + 1}',
          );

          AnthropicTestHelpers.assertResponseQuality(response);
        }

        print('✅ Cache warming and reuse demonstration completed');
      }, timeout: const Timeout(Duration(seconds: 150)));
    });

    group('Complex Tool Orchestration', () {
      test('should handle complex multi-tool workflow', () async {
        if (!AnthropicTestHelpers.canRunIntegrationTests) return;

        final toolProvider = AnthropicTestHelpers.createToolTestProvider();

        final workflowSystem = AnthropicTestHelpers.createCachedSystemMessage(
          content: 'You are a workflow automation assistant. You can analyze data, '
                  'perform calculations, search for information, and manage files. '
                  'Use tools in the most efficient order to complete complex tasks.',
          ttl: AnthropicCacheTtl.fiveMinutes,
        );

        final complexTask = MessageBuilder.user()
            .text('I need to analyze quarterly sales data, calculate growth rates, '
                  'research market trends, and generate a summary report.')
            .build();

        var currentMessages = [workflowSystem, complexTask];
        var iterationCount = 0;
        const maxIterations = 5;

        while (iterationCount < maxIterations) {
          final response = await toolProvider.chatWithTools(
            currentMessages,
            TestTools.allTools,
          );

          AnthropicTestHelpers.printResponseDetails(response, prefix: 'Iteration ${iterationCount + 1}');

          if (response.toolCalls?.isEmpty ?? true) {
            // No more tool calls, workflow is complete
            print('✅ Complex workflow completed in ${iterationCount + 1} iterations');
            break;
          }

          // Process tool calls
          currentMessages.add(_responseToMessage(response));

          for (final toolCall in response.toolCalls!) {
            String mockResult = _generateMockToolResult(toolCall.function.name, toolCall.function.arguments);
            
            final toolResult = AnthropicTestHelpers.createToolResultMessage(
              toolUseId: toolCall.id,
              content: mockResult,
            );

            currentMessages.add(toolResult);
          }

          iterationCount++;
        }

        expect(iterationCount, lessThan(maxIterations), 
          reason: 'Workflow should complete within reasonable iterations');
      }, timeout: const Timeout(Duration(seconds: 180)));

      test('should handle tool failure recovery', () async {
        if (!AnthropicTestHelpers.canRunIntegrationTests) return;

        final resilientProvider = AnthropicTestHelpers.createToolTestProvider();

        final resilientSystem = AnthropicTestHelpers.createCachedSystemMessage(
          content: 'You are a resilient assistant. When tools fail, try alternative approaches '
                  'or suggest manual solutions. Always provide helpful responses.',
        );

        final taskMessage = MessageBuilder.user()
            .text('Calculate the ROI for a project with \$50,000 investment and \$15,000 annual returns over 5 years.')
            .build();

        final response = await resilientProvider.chatWithTools(
          [resilientSystem, taskMessage],
          [TestTools.calculatorTool],
        );

        if (response.toolCalls?.isNotEmpty == true) {
          final toolCall = response.toolCalls!.first;
          
          // Simulate tool failure
          final failureResult = AnthropicTestHelpers.createToolResultMessage(
            toolUseId: toolCall.id,
            content: 'Error: Calculator service temporarily unavailable. Network timeout.',
            isError: true,
          );

          final recoveryResponse = await resilientProvider.chat([
            resilientSystem,
            taskMessage,
            _responseToMessage(response),
            failureResult,
          ]);

          AnthropicTestHelpers.assertResponseQuality(recoveryResponse);
          expect(recoveryResponse.text!.toLowerCase(), anyOf([
            contains('roi'),
            contains('calculate'),
            contains('manually'),
            contains('alternative'),
            contains('50000'),
            contains('15000'),
          ]));

          print('✅ Tool failure recovery handled successfully');
          AnthropicTestHelpers.printResponseDetails(recoveryResponse, prefix: 'Recovery');
        }
      }, timeout: const Timeout(Duration(seconds: 45)));
    });

    group('Streaming and Real-time Scenarios', () {
      test('should handle streaming with complex cached system messages', () async {
        if (!AnthropicTestHelpers.canRunIntegrationTests) return;

        final streamingSystem = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.contentBlocks([
              {
                'type': 'text',
                'text': 'You are a streaming storyteller.',
                'cache_control': {'type': 'ephemeral', 'ttl': 300}
              },
              {
                'type': 'text',
                'text': 'Guidelines:\n'
                       '1. Tell engaging stories with vivid descriptions\n'
                       '2. Use progressive narrative structure\n'
                       '3. Include dialogue and action\n'
                       '4. Aim for 200-300 words'
              }
            ]))
            .build();

        final storyPrompt = MessageBuilder.user()
            .text('Tell me a story about a message that gets lost in a complex distributed system.')
            .build();

        var streamedContent = '';
        var eventCount = 0;
        var hasThinkingContent = false;

        await for (final event in provider.chatStream([streamingSystem, storyPrompt])) {
          eventCount++;
          
          switch (event) {
            case TextDeltaEvent():
              streamedContent += event.delta;
              
            case ThinkingDeltaEvent():
              hasThinkingContent = true;
              
            case ToolCallDeltaEvent():
              // Handle tool call events
              break;
              
            case CompletionEvent():
              print('✅ Streaming story completed');
              print('📊 Total events: $eventCount');
              print('📝 Story length: ${streamedContent.length} characters');
              print('🤔 Had thinking content: $hasThinkingContent');
              break;
              
            case ErrorEvent():
              throw event.error;
          }
        }

        expect(streamedContent.length, greaterThan(100));
        expect(eventCount, greaterThan(5));
        expect(streamedContent.toLowerCase(), anyOf([
          contains('message'),
          contains('system'),
          contains('lost'),
          contains('distributed'),
        ]));
      }, timeout: const Timeout(Duration(seconds: 60)));
    });
  });
}

/// Generate mock tool results for testing
String _generateMockToolResult(String toolName, String arguments) {
  try {
    final args = jsonDecode(arguments) as Map<String, dynamic>;
    
    switch (toolName) {
      case 'web_search':
        final query = args['query'] ?? 'unknown';
        return 'Search results for "$query": Found 15 relevant articles. '
               'Top result: Recent market analysis shows positive trends...';
               
      case 'calculate':
        final expression = args['expression'] ?? '0';
        return 'Calculation result for "$expression": 42.75 '
               '(Note: This is a mock result for testing)';
               
      case 'analyze_data':
        final dataType = args['data_type'] ?? 'general';
        final period = args['time_period'] ?? 'unknown period';
        return 'Data analysis for $dataType over $period: '
               'Trend: +15% growth, Key metrics: engagement up 22%, '
               'conversion rate improved by 8%';
               
      case 'file_operations':
        final operation = args['operation'] ?? 'unknown';
        final filePath = args['file_path'] ?? 'unknown_file';
        return 'File operation "$operation" on $filePath: '
               'Operation completed successfully. File size: 2.3MB';
               
      default:
        return 'Tool "$toolName" executed successfully with result: Operation completed.';
    }
  } catch (e) {
    return 'Tool "$toolName" executed with arguments: $arguments. Result: Success (mock)';
  }
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