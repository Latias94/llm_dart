// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:llm_dart/llm_dart.dart';

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

  // Create AI provider (OpenAI has excellent tool calling support)
  final provider = await ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-4.1-mini')
      .temperature(0.1) // Lower temperature for more reliable tool calls
      .maxTokens(1000)
      .build();

  // Demonstrate different tool calling scenarios
  await demonstrateBasicToolCalling(provider);
  await demonstrateMultipleTools(provider);
  await demonstrateToolChaining(provider);
  await demonstrateStreamingWithTools(provider);
  await demonstrateToolErrorHandling(provider);
  await demonstrateComplexWorkflow(provider);

  print('\n✅ Tool calling completed!');
  print('📖 Next: Try structured_output.dart for JSON schema responses');
}

/// Demonstrate basic tool calling functionality
Future<void> demonstrateBasicToolCalling(ChatCapability provider) async {
  print('🔨 Basic Tool Calling:\n');

  try {
    // Define a simple calculator tool
    final calculatorTool = Tool.function(
      name: 'calculate',
      description: 'Perform basic mathematical calculations',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'expression': ParameterProperty(
            propertyType: 'string',
            description:
                'Mathematical expression to evaluate (e.g., "2 + 3 * 4")',
          ),
        },
        required: ['expression'],
      ),
    );

    final messages = [
      ChatMessage.user('What is 15 * 8 + 42? Please use the calculator tool.')
    ];

    print('   User: What is 15 * 8 + 42? Please use the calculator tool.');
    print('   Available tools: calculate');

    // Send request with tools
    final response = await provider.chatWithTools(messages, [calculatorTool]);

    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      print('   🔧 AI wants to call tools:');

      final conversation = List<ChatMessage>.from(messages);

      // Add the assistant's tool call message
      conversation.add(ChatMessage.toolUse(
        toolCalls: response.toolCalls!,
        content: response.text ?? '',
      ));

      // Execute each tool call
      for (final toolCall in response.toolCalls!) {
        print('      • Function: ${toolCall.function.name}');
        print('      • Arguments: ${toolCall.function.arguments}');

        // Execute the function
        final result = await executeFunction(toolCall);
        print('      • Result: $result');

        // Add tool result to conversation
        conversation.add(ChatMessage.toolResult(
          results: [toolCall],
          content: result,
        ));
      }

      // Get final response with tool results
      final finalResponse = await provider.chat(conversation);
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

/// Demonstrate multiple tools in one conversation
Future<void> demonstrateMultipleTools(ChatCapability provider) async {
  print('🛠️  Multiple Tools:\n');

  try {
    // Define multiple tools
    final tools = [
      // Weather tool
      Tool.function(
        name: 'get_weather',
        description: 'Get current weather information for a location',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'City and state/country (e.g., "San Francisco, CA")',
            ),
            'unit': ParameterProperty(
              propertyType: 'string',
              description: 'Temperature unit',
              enumList: ['celsius', 'fahrenheit'],
            ),
          },
          required: ['location'],
        ),
      ),

      // Time tool
      Tool.function(
        name: 'get_current_time',
        description: 'Get current time in a specific timezone',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'timezone': ParameterProperty(
              propertyType: 'string',
              description:
                  'Timezone (e.g., "America/New_York", "Europe/London")',
            ),
          },
          required: ['timezone'],
        ),
      ),

      // Random number tool
      Tool.function(
        name: 'generate_random_number',
        description: 'Generate a random number within a specified range',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'min': ParameterProperty(
              propertyType: 'integer',
              description: 'Minimum value (inclusive)',
            ),
            'max': ParameterProperty(
              propertyType: 'integer',
              description: 'Maximum value (inclusive)',
            ),
          },
          required: ['min', 'max'],
        ),
      ),
    ];

    final messages = [
      ChatMessage.user(
          'I need to know: 1) Weather in Tokyo, 2) Current time in Japan, 3) A random number between 1 and 100')
    ];

    print(
        '   User: I need to know: 1) Weather in Tokyo, 2) Current time in Japan, 3) A random number between 1 and 100');
    print(
        '   Available tools: get_weather, get_current_time, generate_random_number');

    final response = await provider.chatWithTools(messages, tools);

    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      print('   🔧 AI wants to call ${response.toolCalls!.length} tools:');

      final conversation = List<ChatMessage>.from(messages);

      // Add the assistant's tool call message
      conversation.add(ChatMessage.toolUse(
        toolCalls: response.toolCalls!,
        content: response.text ?? '',
      ));

      // Execute all tool calls
      for (final toolCall in response.toolCalls!) {
        print(
            '      • ${toolCall.function.name}(${toolCall.function.arguments})');

        final result = await executeFunction(toolCall);
        print('        → $result');

        // Add each tool result
        conversation.add(ChatMessage.toolResult(
          results: [toolCall],
          content: result,
        ));
      }

      // Get final response
      final finalResponse = await provider.chat(conversation);
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
Future<void> demonstrateToolChaining(ChatCapability provider) async {
  print('🔗 Tool Chaining:\n');

  try {
    final tools = [
      // Web search tool
      Tool.function(
        name: 'search_web',
        description: 'Search the web for information',
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

      // Note saving tool
      Tool.function(
        name: 'save_note',
        description: 'Save information as a note',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'title': ParameterProperty(
              propertyType: 'string',
              description: 'Note title',
            ),
            'content': ParameterProperty(
              propertyType: 'string',
              description: 'Note content',
            ),
          },
          required: ['title', 'content'],
        ),
      ),
    ];

    final messages = [
      ChatMessage.user(
          'Search for information about "Dart programming language" and save the key points as a note titled "Dart Overview"')
    ];

    print(
        '   User: Search for information about "Dart programming language" and save the key points as a note titled "Dart Overview"');
    print('   Available tools: search_web, save_note');
    print('   This demonstrates tool chaining...\n');

    var conversation = List<ChatMessage>.from(messages);
    var stepCount = 1;

    // Allow multiple rounds of tool calling
    for (var round = 0; round < 3; round++) {
      final response = await provider.chatWithTools(conversation, tools);

      if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
        print(
            '   🔧 Step $stepCount - AI wants to call ${response.toolCalls!.length} tools:');

        // Add the assistant's tool call message
        conversation.add(ChatMessage.toolUse(
          toolCalls: response.toolCalls!,
          content: response.text ?? '',
        ));

        // Execute all tool calls
        for (final toolCall in response.toolCalls!) {
          print('      • ${toolCall.function.name}');

          final result = await executeFunction(toolCall);
          print('        → $result');

          // Add tool result
          conversation.add(ChatMessage.toolResult(
            results: [toolCall],
            content: result,
          ));
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

/// Demonstrate streaming with tool calls
Future<void> demonstrateStreamingWithTools(ChatCapability provider) async {
  print('🌊 Streaming with Tools:\n');

  try {
    final tools = [
      Tool.function(
        name: 'get_file_info',
        description: 'Get information about a file',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'path': ParameterProperty(
              propertyType: 'string',
              description: 'File path to analyze',
            ),
          },
          required: ['path'],
        ),
      ),
    ];

    final messages = [
      ChatMessage.user(
          'Can you check the file "/home/user/document.txt" and tell me about it?')
    ];

    print(
        '   User: Can you check the file "/home/user/document.txt" and tell me about it?');
    print('   Available tools: get_file_info');
    print('   Streaming response...\n');

    var conversation = List<ChatMessage>.from(messages);
    var toolCallsCollected = <ToolCall>[];

    await for (final event in provider.chatStream(conversation, tools: tools)) {
      switch (event) {
        case TextDeltaEvent(delta: final delta):
          stdout.write(delta);
          break;

        case ToolCallDeltaEvent(toolCall: final toolCall):
          print('\n   🔧 Tool call detected: ${toolCall.function.name}');
          toolCallsCollected.add(toolCall);
          break;

        case CompletionEvent(response: final response):
          print('\n   🏁 Stream completed');

          // If there were tool calls, execute them and continue
          if (toolCallsCollected.isNotEmpty) {
            print('   Executing ${toolCallsCollected.length} tool calls...');

            // Add assistant message with tool calls
            conversation.add(ChatMessage.toolUse(
              toolCalls: toolCallsCollected,
              content: response.text ?? '',
            ));

            // Execute tools and add results
            for (final toolCall in toolCallsCollected) {
              final result = await executeFunction(toolCall);
              print('   📄 ${toolCall.function.name} result: $result');

              conversation.add(ChatMessage.toolResult(
                results: [toolCall],
                content: result,
              ));
            }

            // Get final response
            print('\n   Getting final response...');
            final finalResponse = await provider.chat(conversation);
            print('   AI: ${finalResponse.text}');
          }
          break;

        case ErrorEvent(error: final error):
          print('\n   ❌ Stream error: $error');
          break;

        case ThinkingDeltaEvent():
          // Handle thinking if needed
          break;
      }
    }

    print('\n   ✅ Streaming with tools completed\n');
  } catch (e) {
    print('   ❌ Streaming with tools failed: $e\n');
  }
}

/// Demonstrate tool error handling
Future<void> demonstrateToolErrorHandling(ChatCapability provider) async {
  print('🛡️  Tool Error Handling:\n');

  try {
    // Define a tool that might fail
    final tools = [
      Tool.function(
        name: 'risky_operation',
        description: 'An operation that might fail',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'action': ParameterProperty(
              propertyType: 'string',
              description: 'Action to perform',
              enumList: ['safe', 'risky', 'invalid'],
            ),
          },
          required: ['action'],
        ),
      ),
    ];

    final messages = [
      ChatMessage.user(
          'Please perform a risky operation and handle any errors gracefully.')
    ];

    print(
        '   User: Please perform a risky operation and handle any errors gracefully.');
    print('   Available tools: risky_operation');

    final response = await provider.chatWithTools(messages, tools);

    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      print('   🔧 AI wants to call tools:');

      final conversation = List<ChatMessage>.from(messages);

      // Add the assistant's tool call message
      conversation.add(ChatMessage.toolUse(
        toolCalls: response.toolCalls!,
        content: response.text ?? '',
      ));

      // Execute tool calls with error handling
      for (final toolCall in response.toolCalls!) {
        print('      • Function: ${toolCall.function.name}');
        print('      • Arguments: ${toolCall.function.arguments}');

        try {
          final result = await _executeRiskyFunction(toolCall);
          print('      • Result: $result');

          // Add successful result
          conversation.add(ChatMessage.toolResult(
            results: [toolCall],
            content: result,
          ));
        } catch (e) {
          print('      • Error: $e');

          // Add error result - AI can handle this gracefully
          conversation.add(ChatMessage.toolResult(
            results: [toolCall],
            content: 'Error: $e',
          ));
        }
      }

      // Get final response with error handling
      final finalResponse = await provider.chat(conversation);
      print('   AI: ${finalResponse.text}');
      print('   ✅ Error handling demonstration successful\n');
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
Future<void> demonstrateComplexWorkflow(ChatCapability provider) async {
  print('🏗️  Complex Workflow:\n');

  try {
    // Define a comprehensive set of tools for a research workflow
    final tools = [
      Tool.function(
        name: 'search_web',
        description: 'Search the web for information',
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
      ),
      Tool.function(
        name: 'save_note',
        description: 'Save information as a note',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'title': ParameterProperty(
              propertyType: 'string',
              description: 'Note title',
            ),
            'content': ParameterProperty(
              propertyType: 'string',
              description: 'Note content',
            ),
          },
          required: ['title', 'content'],
        ),
      ),
    ];

    final messages = [
      ChatMessage.user(
          'I need to research renewable energy adoption rates, calculate the growth percentage from 2020 to 2023, and save a summary report. Can you help me with this complete workflow?')
    ];

    print(
        '   User: I need to research renewable energy adoption rates, calculate the growth percentage from 2020 to 2023, and save a summary report.');
    print('   Available tools: search_web, calculate, save_note');
    print('   This demonstrates a complex multi-step workflow...\n');

    var conversation = List<ChatMessage>.from(messages);
    var stepCount = 1;
    var maxSteps = 5; // Prevent infinite loops

    // Allow multiple rounds of tool calling for complex workflow
    for (var round = 0; round < maxSteps; round++) {
      final response = await provider.chatWithTools(conversation, tools);

      if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
        print(
            '   🔧 Step $stepCount - AI executing ${response.toolCalls!.length} tools:');

        // Add the assistant's tool call message
        conversation.add(ChatMessage.toolUse(
          toolCalls: response.toolCalls!,
          content: response.text ?? '',
        ));

        // Execute all tool calls in this step
        for (final toolCall in response.toolCalls!) {
          print('      • ${toolCall.function.name}');

          final result = await executeFunction(toolCall);
          print(
              '        → ${result.length > 100 ? '${result.substring(0, 100)}...' : result}');

          // Add tool result
          conversation.add(ChatMessage.toolResult(
            results: [toolCall],
            content: result,
          ));
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
