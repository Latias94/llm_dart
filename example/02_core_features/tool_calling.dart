// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

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
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  registerOpenAI();

  // Create AI provider (OpenAI has excellent tool calling support)
  final provider = await LLMBuilder()
      .provider(openaiProviderId)
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

    final prompt = Prompt(messages: [
      PromptMessage.user(
        'What is 15 * 8 + 42? Please use the calculator tool.',
      ),
    ]);

    print('   User: What is 15 * 8 + 42? Please use the calculator tool.');
    print('   Available tools: calculate');

    final result = await runToolLoop(
      model: provider,
      promptIr: prompt,
      tools: [calculatorTool],
      toolHandlers: {
        'calculate': (toolCall, {cancelToken}) => executeFunction(toolCall),
      },
      maxSteps: 5,
    );

    print('   AI: ${result.finalResult.text}');
    print('   ✅ Basic tool loop completed (steps: ${result.steps.length})\n');
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

    final prompt = Prompt(messages: [
      PromptMessage.user(
        'I need to know: 1) Weather in Tokyo, 2) Current time in Japan, 3) A random number between 1 and 100',
      ),
    ]);

    print(
        '   User: I need to know: 1) Weather in Tokyo, 2) Current time in Japan, 3) A random number between 1 and 100');
    print(
        '   Available tools: get_weather, get_current_time, generate_random_number');

    final result = await runToolLoop(
      model: provider,
      promptIr: prompt,
      tools: tools,
      toolHandlers: {
        'get_weather': (toolCall, {cancelToken}) => executeFunction(toolCall),
        'get_current_time': (toolCall, {cancelToken}) =>
            executeFunction(toolCall),
        'generate_random_number': (toolCall, {cancelToken}) =>
            executeFunction(toolCall),
      },
      maxSteps: 5,
    );

    print('   AI: ${result.finalResult.text}');
    print(
      '   ✅ Multiple tools tool loop completed (steps: ${result.steps.length})\n',
    );
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

    final prompt = Prompt(messages: [
      PromptMessage.user(
        'Search for information about "Dart programming language" and save the key points as a note titled "Dart Overview"',
      ),
    ]);

    print(
        '   User: Search for information about "Dart programming language" and save the key points as a note titled "Dart Overview"');
    print('   Available tools: search_web, save_note');
    print('   This demonstrates tool chaining...\n');

    final result = await runToolLoop(
      model: provider,
      promptIr: prompt,
      tools: tools,
      toolHandlers: {
        'search_web': (toolCall, {cancelToken}) => executeFunction(toolCall),
        'save_note': (toolCall, {cancelToken}) => executeFunction(toolCall),
      },
      maxSteps: 5,
    );

    print('\n   🎯 Final Result:');
    print('   AI: ${result.finalResult.text}');
    print(
      '   ✅ Tool chaining completed successfully (steps: ${result.steps.length})\n',
    );
  } catch (e) {
    print('   ❌ Tool chaining failed: $e\n');
  }
}

/// Demonstrate streaming with tool calls
Future<void> demonstrateStreamingWithTools(ChatCapability provider) async {
  print('🌊 Streaming with Tools:\n');

  try {
    final toolSet = ToolSet([
      functionTool(
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
        handler: (toolCall, {cancelToken}) => executeFunction(toolCall),
      ),
    ]);

    final prompt = Prompt(messages: [
      PromptMessage.user(
        'Can you check the file "/home/user/document.txt" and tell me about it?',
      ),
    ]);

    print(
        '   User: Can you check the file "/home/user/document.txt" and tell me about it?');
    print('   Available tools: get_file_info');
    print('   Streaming response (recommended: tool loop parts)...\n');

    await for (final part in streamToolLoopPartsWithToolSet(
      model: provider,
      promptIr: prompt,
      toolSet: toolSet,
    )) {
      switch (part) {
        case LLMTextDeltaPart(:final delta):
          stdout.write(delta);
          break;

        case LLMToolCallStartPart(:final toolCall):
          final name = toolCall.function.name.isNotEmpty
              ? toolCall.function.name
              : 'tool';
          print('\n   🔧 Tool call detected: $name (id: ${toolCall.id})');
          break;

        case LLMToolResultPart(:final result):
          print(
            '   📄 Tool result for ${result.toolCallId}: ${result.content}',
          );
          break;

        case LLMFinishPart(:final response):
          print('\n   🏁 Stream completed');
          if (response.usage != null) {
            print('   📊 Usage: ${response.usage!.totalTokens} tokens');
          }
          break;

        case LLMErrorPart(:final error):
          print('\n   ❌ Stream error: $error');
          break;

        case LLMTextStartPart():
        case LLMTextEndPart():
        case LLMReasoningStartPart():
        case LLMReasoningDeltaPart():
        case LLMReasoningEndPart():
        case LLMToolCallDeltaPart():
        case LLMToolCallEndPart():
        case LLMProviderMetadataPart():
          // Ignore for this demo.
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

    final prompt = Prompt(messages: [
      PromptMessage.user(
        'Please perform a risky operation and handle any errors gracefully.',
      ),
    ]);

    print(
        '   User: Please perform a risky operation and handle any errors gracefully.');
    print('   Available tools: risky_operation');

    final result = await runToolLoop(
      model: provider,
      promptIr: prompt,
      tools: tools,
      toolHandlers: {
        'risky_operation': (toolCall, {cancelToken}) =>
            _executeRiskyFunction(toolCall),
      },
      maxSteps: 3,
      continueOnToolError: true,
    );

    print('   AI: ${result.finalResult.text}');
    print(
      '   ✅ Error handling tool loop completed (steps: ${result.steps.length})\n',
    );
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

    final prompt = Prompt(messages: [
      PromptMessage.user(
        'I need to research renewable energy adoption rates, calculate the growth percentage from 2020 to 2023, and save a summary report. Can you help me with this complete workflow?',
      ),
    ]);

    print(
        '   User: I need to research renewable energy adoption rates, calculate the growth percentage from 2020 to 2023, and save a summary report.');
    print('   Available tools: search_web, calculate, save_note');
    print('   This demonstrates a complex multi-step workflow...\n');

    final result = await runToolLoop(
      model: provider,
      promptIr: prompt,
      tools: tools,
      toolHandlers: {
        'search_web': (toolCall, {cancelToken}) => executeFunction(toolCall),
        'calculate': (toolCall, {cancelToken}) => executeFunction(toolCall),
        'save_note': (toolCall, {cancelToken}) => executeFunction(toolCall),
      },
      maxSteps: 5,
    );

    print('\n   📊 Workflow Statistics:');
    print('      • Workflow steps completed: ${result.steps.length}');
    print('      • Tools used: search_web, calculate, save_note');

    print('\n   💡 Complex Workflow Benefits:');
    print('      • AI can break down complex tasks into steps');
    print('      • Tools can be chained together logically');
    print('      • Results from one tool inform the next tool call');
    print('      • Complete workflows can be automated');

    print('\n   🎯 Final Result:');
    print('   AI: ${result.finalResult.text}');
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
