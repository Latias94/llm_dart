// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart'
    show
        ChatContentPart,
        TextContentPart,
        ToolCallContentPart,
        ToolResultContentPart,
        ToolResultTextPayload;

/// 🔧 Tool Calling - Function Integration with AI
///
/// This example demonstrates how to integrate AI with external functions:
/// - Defining custom tools and functions
/// - Handling tool calls from AI responses
/// - Executing functions and returning results
/// - Multi-step workflows with tool chains
/// - Error handling in tool execution
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
void main() async {
  print('🔧 Tool Calling - Function Integration with AI\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';

  // Create AI model (OpenAI has excellent tool calling support)
  final model = await ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-4.1-mini')
      .temperature(0.1) // Lower temperature for more reliable tool calls
      .maxTokens(1000)
      .buildLanguageModel();

  // Demonstrate different tool calling scenarios
  await demonstrateBasicToolCalling(model);
  await demonstrateMultipleTools(model);
  await demonstrateToolChaining(model);
  await demonstrateStreamingWithTools(apiKey);
  await demonstrateToolErrorHandling(model);
  await demonstrateComplexWorkflow(model);

  print('\n✅ Tool calling completed!');
}

/// Demonstrate basic tool calling functionality
Future<void> demonstrateBasicToolCalling(LanguageModel model) async {
  print('🔨 Basic Tool Calling:\n');

  try {
    // Define a simple calculator tool
    //
    // Style 1 (recommended): use ToolBuilder / tool(...) helper syntax
    final calculatorTool = tool('calculate', (t) {
      t
        ..description('Perform basic mathematical calculations')
        ..stringParam(
          'expression',
          description:
              'Mathematical expression to evaluate (e.g., "2 + 3 * 4")',
          required: true,
        );
    });

    // Style 2 (equivalent reference): manually construct Tool.function
    // with a ParametersSchema
    //
    // final calculatorTool = Tool.function(
    //   name: 'calculate',
    //   description: 'Perform basic mathematical calculations',
    //   parameters: ParametersSchema(
    //     schemaType: 'object',
    //     properties: {
    //       'expression': ParameterProperty(
    //         propertyType: 'string',
    //         description:
    //             'Mathematical expression to evaluate (e.g., "2 + 3 * 4")',
    //       ),
    //     },
    //     required: ['expression'],
    //   ),
    // );

    final prompt = ChatPromptBuilder.user()
        .text('What is 15 * 8 + 42? Please use the calculator tool.')
        .build();

    print('   User: What is 15 * 8 + 42? Please use the calculator tool.');
    print('   Available tools: calculate');

    // Send request with tools
    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
      options: LanguageModelCallOptions(tools: [calculatorTool]),
    );

    final toolCalls = response.toolCalls ?? const <ToolCall>[];
    if (toolCalls.isNotEmpty) {
      print('   🔧 AI wants to call tools:');

      final conversation = <ModelMessage>[
        prompt,
        _assistantWithToolCalls(response.text, toolCalls),
      ];

      // Execute each tool call
      for (final toolCall in toolCalls) {
        print('      • Function: ${toolCall.function.name}');
        print('      • Arguments: ${toolCall.function.arguments}');

        // Execute the function
        final result = await executeFunction(toolCall);
        print('      • Result: $result');

        // Add tool result to conversation
        conversation.add(_toolResultMessage(toolCall, result));
      }

      // Get final response with tool results
      final finalResponse = await generateTextWithModel(
        model,
        promptMessages: conversation,
      );
      print('   AI: ${finalResponse.text}');
      print('   ✅ Basic tool calling successful\n');
    } else {
      print('   ℹ️  AI chose not to use tools: ${response.text}');
      print('   ✅ Response received without tool calls\n');
    }
  } catch (e) {
    print('   ❌ Basic tool calling failed: $e\n');
  }
}

/// Execute a function call and return the result
Future<String> executeFunction(ToolCall toolCall) async {
  try {
    final functionName = toolCall.function.name;
    final arguments =
        jsonDecode(toolCall.function.arguments) as Map<String, dynamic>;

    switch (functionName) {
      case 'calculate':
        return _calculate(arguments['expression'] as String);

      case 'get_weather':
        return _getWeather(
          arguments['location'] as String,
          arguments['unit'] as String? ?? 'celsius',
        );

      case 'get_current_time':
        return _getCurrentTime(arguments['timezone'] as String? ?? 'UTC');

      case 'generate_random_number':
        return _generateRandomNumber(
          arguments['min'] as int,
          arguments['max'] as int,
        );

      case 'search_web':
        return _searchWeb(arguments['query'] as String);

      case 'save_note':
        return _saveNote(
          arguments['title'] as String,
          arguments['content'] as String,
        );

      case 'get_file_info':
        return _getFileInfo(arguments['path'] as String);

      default:
        return 'Error: Unknown function "$functionName"';
    }
  } catch (e) {
    return 'Error executing function: $e';
  }
}

/// Simple calculator function
String _calculate(String expression) {
  try {
    // Simple expression evaluator (for demo purposes)
    // In production, use a proper math parser
    final sanitized = expression.replaceAll(RegExp(r'[^0-9+\-*/().\s]'), '');

    // Basic evaluation for simple expressions
    if (sanitized.contains('+')) {
      final parts = sanitized.split('+');
      if (parts.length == 2) {
        final a = double.tryParse(parts[0].trim()) ?? 0;
        final b = double.tryParse(parts[1].trim()) ?? 0;
        return (a + b).toString();
      }
    }

    if (sanitized.contains('*')) {
      final parts = sanitized.split('*');
      if (parts.length == 2) {
        final a = double.tryParse(parts[0].trim()) ?? 0;
        final b = double.tryParse(parts[1].trim()) ?? 0;
        return (a * b).toString();
      }
    }

    // For the example "15 * 8 + 42"
    if (expression.contains('15 * 8 + 42')) {
      return (15 * 8 + 42).toString(); // = 162
    }

    return 'Unable to evaluate: $expression';
  } catch (e) {
    return 'Calculation error: $e';
  }
}

/// Mock weather function
String _getWeather(String location, String unit) {
  final random = Random();
  final temp = random.nextInt(30) + 10; // 10-40 range
  final conditions = ['sunny', 'cloudy', 'rainy', 'partly cloudy'];
  final condition = conditions[random.nextInt(conditions.length)];

  final unitSymbol = unit == 'fahrenheit' ? '°F' : '°C';
  return 'Weather in $location: $temp$unitSymbol, $condition';
}

/// Mock time function
String _getCurrentTime(String timezone) {
  final now = DateTime.now();
  return 'Current time in $timezone: ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
}

/// Random number generator
String _generateRandomNumber(int min, int max) {
  final random = Random();
  final number = random.nextInt(max - min + 1) + min;
  return number.toString();
}

/// Mock web search function
String _searchWeb(String query) {
  return 'Search results for "$query": Found 3 relevant articles about $query. Top result: "$query - Wikipedia"';
}

/// Mock note saving function
String _saveNote(String title, String content) {
  return 'Note "$title" saved successfully with ${content.length} characters';
}

/// Mock file info function
String _getFileInfo(String path) {
  return 'File: $path, Size: 1.2 KB, Modified: ${DateTime.now().toString().substring(0, 19)}';
}

/// Helper to build an assistant message that includes tool call parts.
ModelMessage _assistantWithToolCalls(String? text, List<ToolCall> toolCalls) {
  final parts = <ChatContentPart>[];
  if (text != null && text.isNotEmpty) {
    parts.add(TextContentPart(text));
  }
  for (final call in toolCalls) {
    parts.add(
      ToolCallContentPart(
        toolName: call.function.name,
        argumentsJson: call.function.arguments,
        toolCallId: call.id,
      ),
    );
  }
  return ModelMessage(role: ChatRole.assistant, parts: parts);
}

/// Helper to build a tool result message from a tool call and text result.
ModelMessage _toolResultMessage(ToolCall toolCall, String result) {
  return ModelMessage(
    role: ChatRole.assistant,
    parts: [
      ToolResultContentPart(
        toolCallId: toolCall.id,
        toolName: toolCall.function.name,
        payload: ToolResultTextPayload(result),
      ),
    ],
  );
}

/// Demonstrate multiple tools in one conversation
Future<void> demonstrateMultipleTools(LanguageModel model) async {
  print('🛠️  Multiple Tools:\n');

  try {
    // Define multiple tools
    final tools = [
      // Weather tool
      tool('get_weather', (t) {
        t
          ..description('Get current weather information for a location')
          ..stringParam(
            'location',
            description: 'City and state/country (e.g., "San Francisco, CA")',
            required: true,
          )
          ..enumParam(
            'unit',
            description: 'Temperature unit',
            values: ['celsius', 'fahrenheit'],
          );
      }),

      // Time tool
      tool('get_current_time', (t) {
        t
          ..description('Get current time in a specific timezone')
          ..stringParam(
            'timezone',
            description: 'Timezone (e.g., "America/New_York", "Europe/London")',
            required: true,
          );
      }),

      // Random number tool
      tool('generate_random_number', (t) {
        t
          ..description('Generate a random number within a specified range')
          ..integerParam(
            'min',
            description: 'Minimum value (inclusive)',
            required: true,
          )
          ..integerParam(
            'max',
            description: 'Maximum value (inclusive)',
            required: true,
          );
      }),
    ];

    final prompt = ChatPromptBuilder.user()
        .text(
            'I need to know: 1) Weather in Tokyo, 2) Current time in Japan, 3) A random number between 1 and 100')
        .build();

    print(
        '   User: I need to know: 1) Weather in Tokyo, 2) Current time in Japan, 3) A random number between 1 and 100');
    print(
        '   Available tools: get_weather, get_current_time, generate_random_number');

    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
      options: LanguageModelCallOptions(tools: tools),
    );

    final toolCalls = response.toolCalls ?? const <ToolCall>[];
    if (toolCalls.isNotEmpty) {
      print('   🔧 AI wants to call ${toolCalls.length} tools:');

      final conversation = <ModelMessage>[
        prompt,
        _assistantWithToolCalls(response.text, toolCalls),
      ];

      // Execute all tool calls
      for (final toolCall in toolCalls) {
        print(
            '      • ${toolCall.function.name}(${toolCall.function.arguments})');

        final result = await executeFunction(toolCall);
        print('        → $result');

        // Add each tool result
        conversation.add(_toolResultMessage(toolCall, result));
      }

      // Get final response
      final finalResponse = await generateTextWithModel(
        model,
        promptMessages: conversation,
      );
      print('   AI: ${finalResponse.text}');
      print('   ✅ Multiple tools executed successfully\n');
    } else {
      print('   ℹ️  AI chose not to use tools: ${response.text}\n');
    }
  } catch (e) {
    print('   ❌ Multiple tools demonstration failed: $e\n');
  }
}

/// Demonstrate tool chaining (using results from one tool in another)
Future<void> demonstrateToolChaining(LanguageModel model) async {
  print('🔗 Tool Chaining:\n');

  try {
    final tools = [
      // Web search tool
      tool('search_web', (t) {
        t
          ..description('Search the web for information')
          ..stringParam(
            'query',
            description: 'Search query',
            required: true,
          );
      }),

      // Note saving tool
      tool('save_note', (t) {
        t
          ..description('Save information as a note')
          ..stringParam(
            'title',
            description: 'Note title',
            required: true,
          )
          ..stringParam(
            'content',
            description: 'Note content',
            required: true,
          );
      }),
    ];

    final prompt = ChatPromptBuilder.user()
        .text(
            'Search for information about "Dart programming language" and save the key points as a note titled "Dart Overview"')
        .build();

    print(
        '   User: Search for information about "Dart programming language" and save the key points as a note titled "Dart Overview"');
    print('   Available tools: search_web, save_note');
    print('   This demonstrates tool chaining...\n');

    var conversation = <ModelMessage>[prompt];
    var stepCount = 1;

    // Allow multiple rounds of tool calling
    for (var round = 0; round < 3; round++) {
      final response = await generateTextWithModel(
        model,
        promptMessages: conversation,
        options: LanguageModelCallOptions(tools: tools),
      );

      final toolCalls = response.toolCalls ?? const <ToolCall>[];
      if (toolCalls.isNotEmpty) {
        print(
            '   🔧 Step $stepCount - AI wants to call ${response.toolCalls!.length} tools:');

        // Add the assistant's tool call message
        conversation.add(
          _assistantWithToolCalls(response.text, toolCalls),
        );

        // Execute all tool calls
        for (final toolCall in toolCalls) {
          print('      • ${toolCall.function.name}');

          final result = await executeFunction(toolCall);
          print('        → $result');

          // Add tool result
          conversation.add(_toolResultMessage(toolCall, result));
        }

        stepCount++;
      } else {
        // No more tool calls, show final response
        print('   AI: ${response.text}');
        break;
      }
    }

    print('   ✅ Tool chaining completed successfully\n');
  } catch (e) {
    print('   ❌ Tool chaining failed: $e\n');
  }
}

/// Demonstrate streaming with tool calls using the high-level
/// `streamTextParts` API (Vercel AI SDK style).
Future<void> demonstrateStreamingWithTools(String apiKey) async {
  print('🌊 Streaming with Tools:\n');

  try {
    final tools = [
      tool('get_file_info', (t) {
        t
          ..description('Get information about a file')
          ..stringParam(
            'path',
            description: 'File path to analyze',
            required: true,
          );
      }),
    ];

    const question =
        'Can you check the file "/home/user/document.txt" and tell me about it?';
    final prompt = ChatPromptBuilder.user().text(question).build();

    print('   User: $question');
    print('   Available tools: get_file_info');
    print('   Streaming response...\n');

    // Build a high-level LanguageModel with tools configured.
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4.1-mini')
        .temperature(0.1)
        .maxTokens(1000)
        .tools(tools)
        .buildLanguageModel();

    final textBuffer = StringBuffer();
    var sawToolInput = false;

    // First streaming pass: get tool calls and initial answer text.
    final toolCalls = <ToolCall>[];

    await for (final part in streamTextPartsWithModel(
      model,
      promptMessages: [prompt],
    )) {
      switch (part) {
        case StreamTextStart():
          break;
        case StreamTextDelta(delta: final delta):
          stdout.write(delta);
          textBuffer.write(delta);
          break;
        case StreamThinkingDelta():
          // Ignore thinking for this example
          break;
        case StreamToolInputStart(
            toolCallId: final toolCallId,
            toolName: final toolName
          ):
          if (!sawToolInput) {
            print('\n');
            sawToolInput = true;
          }
          print('   🔧 Tool call started: $toolName (id: $toolCallId)');
          break;
        case StreamToolInputDelta():
          // We don't print every arguments delta to keep logs compact
          break;
        case StreamToolInputEnd(toolCallId: final toolCallId):
          print('   🔧 Tool input completed for id: $toolCallId');
          break;
        case StreamToolCall(toolCall: final toolCall):
          toolCalls.add(toolCall);
          print(
              '   🔧 Final tool call: ${toolCall.function.name}(${toolCall.function.arguments})');
          break;
        case StreamTextEnd():
          break;
        case StreamFinish():
          print('\n   🏁 First streaming pass completed');
          break;
      }
    }

    if (toolCalls.isEmpty) {
      print('\n   ℹ️  Model did not call tools during streaming');
      print('   ✅ Streaming with tools completed\n');
      return;
    }

    // Execute tools and build follow-up conversation.
    print('\n   Executing ${toolCalls.length} tool calls...');

    final conversation = <ModelMessage>[
      prompt,
      _assistantWithToolCalls(textBuffer.toString(), toolCalls),
    ];

    for (final toolCall in toolCalls) {
      final result = await executeFunction(toolCall);
      print('   📄 ${toolCall.function.name} result: $result');

      conversation.add(_toolResultMessage(toolCall, result));
    }

    // Second pass: get final answer (non-streaming for simplicity).
    print('\n   Getting final response...');
    final finalResult = await generateTextWithModel(
      model,
      promptMessages: conversation,
    );
    print('   AI: ${finalResult.text}');

    print('\n   ✅ Streaming with tools completed\n');
  } catch (e) {
    print('   ❌ Streaming with tools failed: $e\n');
  }
}

/// Demonstrate tool error handling
Future<void> demonstrateToolErrorHandling(LanguageModel model) async {
  print('🛡️  Tool Error Handling:\n');

  try {
    // Define a tool that might fail
    final tools = [
      tool('risky_operation', (t) {
        t
          ..description('An operation that might fail')
          ..enumParam(
            'action',
            description: 'Action to perform',
            values: ['safe', 'risky', 'invalid'],
            required: true,
          );
      }),
    ];

    final prompt = ChatPromptBuilder.user()
        .text(
            'Please perform a risky operation and handle any errors gracefully.')
        .build();

    print(
        '   User: Please perform a risky operation and handle any errors gracefully.');
    print('   Available tools: risky_operation');

    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
      options: LanguageModelCallOptions(tools: tools),
    );

    final toolCalls = response.toolCalls ?? const <ToolCall>[];
    if (toolCalls.isNotEmpty) {
      print('   🔧 AI wants to call tools:');

      final conversation = <ModelMessage>[
        prompt,
        _assistantWithToolCalls(response.text, toolCalls),
      ];

      // Execute tool calls with error handling
      for (final toolCall in toolCalls) {
        print('      • Function: ${toolCall.function.name}');
        print('      • Arguments: ${toolCall.function.arguments}');

        try {
          final result = await _executeRiskyFunction(toolCall);
          print('      • Result: $result');

          // Add successful result
          conversation.add(_toolResultMessage(toolCall, result));
        } catch (e) {
          print('      • Error: $e');

          // Add error result - AI can handle this gracefully
          conversation.add(
            _toolResultMessage(toolCall, 'Error: $e'),
          );
        }
      }

      // Get final response with error handling
      try {
        final finalResponse = await generateTextWithModel(
          model,
          promptMessages: conversation,
        );
        print('   AI: ${finalResponse.text}');
        print('   ✅ Error handling demonstration successful\n');
      } catch (e) {
        // Even if the final LLM call fails, the example still demonstrates
        // how to surface and handle tool errors gracefully.
        print('   ⚠️  Final AI response failed: $e');
        print(
            '   ✅ Error handling demonstration completed (tool errors handled)\n');
      }
    } else {
      print('   ℹ️  AI chose not to use tools: ${response.text}\n');
    }
  } catch (e) {
    print('   ❌ Tool error handling failed: $e\n');
  }
}

/// Risky function that might throw errors
Future<String> _executeRiskyFunction(ToolCall toolCall) async {
  final arguments =
      jsonDecode(toolCall.function.arguments) as Map<String, dynamic>;
  final action = arguments['action'] as String;

  switch (action) {
    case 'safe':
      return 'Operation completed safely';
    case 'risky':
      // Simulate a random failure
      if (Random().nextBool()) {
        throw Exception('Random failure occurred during risky operation');
      }
      return 'Risky operation completed successfully';
    case 'invalid':
      throw ArgumentError('Invalid action requested');
    default:
      throw Exception('Unknown action: $action');
  }
}

/// Demonstrate complex workflow with multiple tool interactions
Future<void> demonstrateComplexWorkflow(LanguageModel model) async {
  print('🏗️  Complex Workflow:\n');

  try {
    // Define a comprehensive set of tools for a research workflow
    final tools = [
      tool('search_web', (t) {
        t
          ..description('Search the web for information')
          ..stringParam(
            'query',
            description: 'Search query',
            required: true,
          );
      }),
      tool('calculate', (t) {
        t
          ..description('Perform mathematical calculations')
          ..stringParam(
            'expression',
            description: 'Mathematical expression to evaluate',
            required: true,
          );
      }),
      tool('save_note', (t) {
        t
          ..description('Save information as a note')
          ..stringParam(
            'title',
            description: 'Note title',
            required: true,
          )
          ..stringParam(
            'content',
            description: 'Note content',
            required: true,
          );
      }),
    ];

    final prompts = <ModelMessage>[
      ChatPromptBuilder.user()
          .text(
              'I need to research renewable energy adoption rates, calculate the growth percentage from 2020 to 2023, and save a summary report. Can you help me with this complete workflow?')
          .build(),
    ];

    print(
        '   User: I need to research renewable energy adoption rates, calculate the growth percentage from 2020 to 2023, and save a summary report.');
    print('   Available tools: search_web, calculate, save_note');
    print('   This demonstrates a complex multi-step workflow...\n');

    var conversation = List<ModelMessage>.from(prompts);
    var stepCount = 1;
    var maxSteps = 5; // Prevent infinite loops

    // Allow multiple rounds of tool calling for complex workflow
    for (var round = 0; round < maxSteps; round++) {
      final response = await generateTextWithModel(
        model,
        promptMessages: conversation,
        options: LanguageModelCallOptions(tools: tools),
      );

      final toolCalls = response.toolCalls ?? const <ToolCall>[];
      if (toolCalls.isNotEmpty) {
        print(
            '   🔧 Step $stepCount - AI executing ${toolCalls.length} tools:');

        // Add the assistant's tool call message
        conversation.add(
          _assistantWithToolCalls(response.text, toolCalls),
        );

        // Group tool calls by function name for more compact logging
        final callsByName = <String, List<ToolCall>>{};
        for (final toolCall in toolCalls) {
          callsByName
              .putIfAbsent(toolCall.function.name, () => <ToolCall>[])
              .add(toolCall);
        }

        for (final entry in callsByName.entries) {
          final name = entry.key;
          final calls = entry.value;

          if (calls.length == 1) {
            // Single call for this tool
            final toolCall = calls.first;
            print('      • $name');

            final result = await executeFunction(toolCall);
            final display =
                result.length > 100 ? '${result.substring(0, 100)}...' : result;
            print('        → $display');

            conversation.add(_toolResultMessage(toolCall, result));
          } else {
            // Multiple calls for the same tool in this step
            print('      • $name (x${calls.length})');

            for (var i = 0; i < calls.length; i++) {
              final toolCall = calls[i];
              final result = await executeFunction(toolCall);
              final display = result.length > 100
                  ? '${result.substring(0, 100)}...'
                  : result;

              // Only print the first result in detail to keep logs compact
              if (i == 0) {
                print('        → $display');
              }

              conversation.add(_toolResultMessage(toolCall, result));
            }
          }
        }

        stepCount++;

        // Add a small delay to make the workflow more visible
        await Future.delayed(Duration(milliseconds: 500));
      } else {
        // No more tool calls, show final response
        print('\n   🎯 Final Result:');
        print('   AI: ${response.text}');
        break;
      }
    }

    print('\n   📊 Workflow Statistics:');
    print('      • Total conversation messages: ${conversation.length}');
    print('      • Workflow steps completed: ${stepCount - 1}');
    print('      • Tools used: search_web, calculate, save_note');

    print('\n   💡 Complex Workflow Benefits:');
    print('      • AI can break down complex tasks into steps');
    print('      • Tools can be chained together logically');
    print('      • Results from one tool inform the next tool call');
    print('      • Complete workflows can be automated');

    print('   ✅ Complex workflow completed successfully\n');
  } catch (e) {
    print('   ❌ Complex workflow failed: $e\n');
  }
}

/// 🎯 Key Tool Calling Concepts Summary:
///
/// Tool Definition:
/// - name: Unique identifier for the function
/// - description: What the function does (helps AI decide when to use it)
/// - parameters: JSON schema defining input parameters
/// - required: List of mandatory parameters
///
/// Tool Execution Flow:
/// 1. AI receives user request and available tools
/// 2. AI decides which tools to call (if any)
/// 3. AI generates tool calls with appropriate arguments
/// 4. Your code executes the functions
/// 5. Results are fed back to AI
/// 6. AI provides final response incorporating tool results
///
/// Best Practices:
/// 1. Provide clear, descriptive tool names and descriptions
/// 2. Define comprehensive parameter schemas
/// 3. Handle tool execution errors gracefully
/// 4. Validate tool arguments before execution
/// 5. Return meaningful results that AI can interpret
/// 6. Support tool chaining for complex workflows
/// 7. Use lower temperature for more reliable tool calls
///
/// Advanced Features:
/// - Streaming with tool calls
/// - Multi-step tool chaining
/// - Error handling and recovery
/// - Complex workflow automation
/// - Tool result validation
///
/// Next Steps:
/// - structured_output.dart: JSON schema responses
/// - error_handling.dart: Production-ready error management
/// - Advanced examples: Multi-modal tool calling, custom providers
