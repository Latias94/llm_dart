// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 🌊 Anthropic Streaming Tool Calling
///
/// This example demonstrates Anthropic's streaming tool use capability:
/// - Real-time tool call detection during streaming
/// - Handling multiple tool calls in one response
/// - Complex tool parameters with nested objects
///
/// Before running, set your API key:
/// export ANTHROPIC_API_KEY="your-key"
void main() async {
  print('🌊 Anthropic Streaming Tool Calling\n');

  // Get API key
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Error: ANTHROPIC_API_KEY environment variable not set');
    print('   Please set it with: export ANTHROPIC_API_KEY="your-key"');
    exit(1);
  }

  // Create Anthropic provider
  final provider = await ai()
      .anthropic()
      .apiKey(apiKey)
      .model('claude-sonnet-4-20250514')
      .temperature(0.1)
      .maxTokens(1000)
      .build();

  print('✅ Provider created: Claude Sonnet 4\n');

  // Demonstrate different streaming tool scenarios
  await demonstrateBasicStreamingTool(provider);
  await demonstrateMultipleToolsStreaming(provider);
  await demonstrateComplexParametersStreaming(provider);

  print('\n✅ All streaming tool calling examples completed!');
}

/// Demonstrate basic streaming tool call
Future<void> demonstrateBasicStreamingTool(ChatCapability provider) async {
  print('🔧 Basic Streaming Tool Call:\n');

  try {
    final tools = [
      Tool.function(
        name: 'get_weather',
        description: 'Get current weather for a location',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'City name',
            ),
            'unit': ParameterProperty(
              propertyType: 'string',
              description: 'Temperature unit (celsius or fahrenheit)',
              enumList: ['celsius', 'fahrenheit'],
            ),
          },
          required: ['location'],
        ),
      ),
    ];

    final messages = [
      ChatMessage.user('What is the weather like in Tokyo? Use celsius.')
    ];

    print('   User: What is the weather like in Tokyo? Use celsius.');
    print('   Available tools: get_weather');
    print('   Streaming response:\n');

    var toolCallsDetected = <ToolCall>[];
    var textContent = StringBuffer();

    await for (final event in provider.chatStream(messages, tools: tools)) {
      switch (event) {
        case TextDeltaEvent(delta: final delta):
          textContent.write(delta);
          stdout.write(delta);
          break;

        case ToolCallDeltaEvent(toolCall: final toolCall):
          toolCallsDetected.add(toolCall);
          print('\n   🔧 Tool Call Detected!');
          print('      Tool: ${toolCall.function.name}');
          print('      ID: ${toolCall.id}');
          final args = jsonDecode(toolCall.function.arguments);
          print('      Arguments: $args');
          break;

        case CompletionEvent():
          print('\n   ✅ Stream completed');
          break;

        case ErrorEvent(error: final error):
          print('\n   ❌ Error: $error');
          break;

        case ThinkingDeltaEvent():
          // Ignore thinking events for this example
          break;
      }
    }

    print('\n   Results:');
    print('      Tool calls detected: ${toolCallsDetected.length}');
    if (toolCallsDetected.isNotEmpty) {
      print('      ✅ Streaming tool call working correctly!');
    } else {
      print('      ⚠️  No tool calls detected');
    }
    print('');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Demonstrate multiple tools in streaming
Future<void> demonstrateMultipleToolsStreaming(ChatCapability provider) async {
  print('🔧 Multiple Tools Streaming:\n');

  try {
    final tools = [
      Tool.function(
        name: 'get_weather',
        description: 'Get current weather for a location',
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
        name: 'get_time',
        description: 'Get current time for a timezone',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'timezone': ParameterProperty(
              propertyType: 'string',
              description: 'Timezone name (e.g., Asia/Tokyo)',
            ),
          },
          required: ['timezone'],
        ),
      ),
    ];

    final messages = [
      ChatMessage.user(
          'What is the weather in Paris and what time is it in Tokyo?')
    ];

    print(
        '   User: What is the weather in Paris and what time is it in Tokyo?');
    print('   Available tools: get_weather, get_time');
    print('   Streaming response:\n');

    var toolCallsDetected = <ToolCall>[];

    await for (final event in provider.chatStream(messages, tools: tools)) {
      switch (event) {
        case TextDeltaEvent(delta: final delta):
          stdout.write(delta);
          break;

        case ToolCallDeltaEvent(toolCall: final toolCall):
          toolCallsDetected.add(toolCall);
          print('\n   🔧 Tool Call #${toolCallsDetected.length} Detected!');
          print('      Tool: ${toolCall.function.name}');
          final args = jsonDecode(toolCall.function.arguments);
          print('      Arguments: $args');
          break;

        case CompletionEvent():
          print('\n   ✅ Stream completed');
          break;

        case ErrorEvent(error: final error):
          print('\n   ❌ Error: $error');
          break;

        case ThinkingDeltaEvent():
          break;
      }
    }

    print('\n   Results:');
    print('      Tool calls detected: ${toolCallsDetected.length}');
    if (toolCallsDetected.length >= 2) {
      print('      ✅ Multiple tool calls working correctly!');
    } else {
      print('      ⚠️  Expected 2 tool calls, got ${toolCallsDetected.length}');
    }
    print('');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Demonstrate complex parameters in streaming
Future<void> demonstrateComplexParametersStreaming(
    ChatCapability provider) async {
  print('🔧 Complex Parameters Streaming:\n');

  try {
    final tools = [
      Tool.function(
        name: 'create_event',
        description: 'Create a calendar event',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'title': ParameterProperty(
              propertyType: 'string',
              description: 'Event title',
            ),
            'attendees': ParameterProperty(
              propertyType: 'array',
              description: 'List of attendee email addresses',
              items: ParameterProperty(
                propertyType: 'string',
                description: 'Email address',
              ),
            ),
            'location': ParameterProperty(
              propertyType: 'object',
              description: 'Event location details',
              properties: {
                'name': ParameterProperty(
                  propertyType: 'string',
                  description: 'Location name',
                ),
                'address': ParameterProperty(
                  propertyType: 'string',
                  description: 'Location address',
                ),
              },
            ),
          },
          required: ['title', 'attendees'],
        ),
      ),
    ];

    final messages = [
      ChatMessage.user(
          'Create a meeting titled "Team Sync" with attendees alice@example.com and bob@example.com at Conference Room A')
    ];

    print(
        '   User: Create a meeting titled "Team Sync" with attendees alice@example.com and bob@example.com');
    print('   Available tools: create_event');
    print('   Streaming response:\n');

    var toolCallsDetected = <ToolCall>[];

    await for (final event in provider.chatStream(messages, tools: tools)) {
      switch (event) {
        case TextDeltaEvent(delta: final delta):
          stdout.write(delta);
          break;

        case ToolCallDeltaEvent(toolCall: final toolCall):
          toolCallsDetected.add(toolCall);
          print('\n   🔧 Tool Call Detected!');
          print('      Tool: ${toolCall.function.name}');
          final args = jsonDecode(toolCall.function.arguments);
          print('      Arguments (formatted):');
          print('      ${JsonEncoder.withIndent('  ').convert(args)}');
          break;

        case CompletionEvent():
          print('\n   ✅ Stream completed');
          break;

        case ErrorEvent(error: final error):
          print('\n   ❌ Error: $error');
          break;

        case ThinkingDeltaEvent():
          break;
      }
    }

    print('\n   Results:');
    print('      Tool calls detected: ${toolCallsDetected.length}');
    if (toolCallsDetected.isNotEmpty) {
      print('      ✅ Complex parameters working correctly!');
    } else {
      print('      ⚠️  No tool calls detected');
    }
    print('');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}
