// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Anthropic streaming tool calling (Prompt IR + `llm_dart_ai`).
///
/// Demonstrates:
/// - Streaming tool call detection as `LLMStreamPart`s
/// - Aggregating tool call deltas into complete `ToolCall`s
/// - Multiple tool calls and nested tool parameters
///
/// Setup:
/// - `export ANTHROPIC_API_KEY="your-key"`
Future<void> main() async {
  print('Anthropic Streaming Tool Calling\n');

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Error: ANTHROPIC_API_KEY environment variable not set');
    print('Please set it with: export ANTHROPIC_API_KEY="your-key"');
    exit(1);
  }

  registerAnthropic();

  final provider = await LLMBuilder()
      .provider(anthropicProviderId)
      .apiKey(apiKey)
      .model('claude-sonnet-4-20250514')
      .temperature(0.1)
      .maxTokens(1000)
      .build();

  print('Provider created: Claude Sonnet 4\n');

  await demonstrateBasicStreamingTool(provider);
  await demonstrateMultipleToolsStreaming(provider);
  await demonstrateComplexParametersStreaming(provider);

  print('\nAll streaming tool calling examples completed!');
}

/// Demonstrate basic streaming tool call
Future<void> demonstrateBasicStreamingTool(ChatCapability provider) async {
  print('Basic Streaming Tool Call:\n');

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

    final prompt = Prompt(
      messages: [
        PromptMessage.user('What is the weather like in Tokyo? Use celsius.'),
      ],
    );

    print('   User: What is the weather like in Tokyo? Use celsius.');
    print('   Available tools: get_weather');
    print('   Streaming response:\n');

    final toolCallIds = <String>{};
    final aggregator = ToolCallAggregator();
    final textContent = StringBuffer();

    await for (final part in streamChatParts(
      model: provider,
      promptIr: prompt,
      tools: tools,
    )) {
      switch (part) {
        case LLMTextDeltaPart(delta: final delta):
          textContent.write(delta);
          stdout.write(delta);
          break;

        case LLMToolCallStartPart(toolCall: final toolCall):
          toolCallIds.add(toolCall.id);
          aggregator.addDelta(toolCall);
          print('\n   Tool Call Detected!');
          print('      Tool: ${toolCall.function.name}');
          print('      ID: ${toolCall.id}');
          break;

        case LLMToolCallDeltaPart(toolCall: final toolCall):
          aggregator.addDelta(toolCall);
          break;

        case LLMFinishPart():
          print('\n   Stream completed');
          break;

        case LLMErrorPart(error: final error):
          print('\n   Error: $error');
          break;

        default:
          break;
      }
    }

    final completedToolCalls = aggregator.completedCalls;

    print('\n   Results:');
    print('      Tool calls detected: ${toolCallIds.length}');
    if (completedToolCalls.isNotEmpty) {
      print('      Streaming tool call working correctly!');
      for (final toolCall in completedToolCalls) {
        try {
          final args = jsonDecode(toolCall.function.arguments);
          print('      Arguments: $args');
        } catch (_) {
          print('      Arguments (raw): ${toolCall.function.arguments}');
        }
      }
    } else {
      print('      No tool calls detected');
    }
    print('');
  } catch (e) {
    print('   Error: $e\n');
  }
}

/// Demonstrate multiple tools in streaming
Future<void> demonstrateMultipleToolsStreaming(ChatCapability provider) async {
  print('Multiple Tools Streaming:\n');

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

    final prompt = Prompt(
      messages: [
        PromptMessage.user(
          'What is the weather in Paris and what time is it in Tokyo?',
        ),
      ],
    );

    print(
        '   User: What is the weather in Paris and what time is it in Tokyo?');
    print('   Available tools: get_weather, get_time');
    print('   Streaming response:\n');

    final toolCallIds = <String>{};
    final aggregator = ToolCallAggregator();

    await for (final part in streamChatParts(
      model: provider,
      promptIr: prompt,
      tools: tools,
    )) {
      switch (part) {
        case LLMTextDeltaPart(delta: final delta):
          stdout.write(delta);
          break;

        case LLMToolCallStartPart(toolCall: final toolCall):
          toolCallIds.add(toolCall.id);
          aggregator.addDelta(toolCall);
          print('\n   Tool Call #${toolCallIds.length} Detected!');
          print('      Tool: ${toolCall.function.name}');
          break;

        case LLMToolCallDeltaPart(toolCall: final toolCall):
          aggregator.addDelta(toolCall);
          break;

        case LLMFinishPart():
          print('\n   Stream completed');
          break;

        case LLMErrorPart(error: final error):
          print('\n   Error: $error');
          break;

        default:
          break;
      }
    }

    final completedToolCalls = aggregator.completedCalls;

    print('\n   Results:');
    print('      Tool calls detected: ${toolCallIds.length}');
    if (completedToolCalls.length >= 2) {
      print('      Multiple tool calls working correctly!');
      for (final toolCall in completedToolCalls) {
        try {
          final args = jsonDecode(toolCall.function.arguments);
          print('      ${toolCall.function.name} args: $args');
        } catch (_) {
          print(
              '      ${toolCall.function.name} args (raw): ${toolCall.function.arguments}');
        }
      }
    } else {
      print('      Expected 2 tool calls, got ${completedToolCalls.length}');
    }
    print('');
  } catch (e) {
    print('   Error: $e\n');
  }
}

/// Demonstrate complex parameters in streaming
Future<void> demonstrateComplexParametersStreaming(
    ChatCapability provider) async {
  print('Complex Parameters Streaming:\n');

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

    final prompt = Prompt(
      messages: [
        PromptMessage.user(
          'Create a meeting titled "Team Sync" with attendees alice@example.com and bob@example.com at Conference Room A',
        ),
      ],
    );

    print(
        '   User: Create a meeting titled "Team Sync" with attendees alice@example.com and bob@example.com');
    print('   Available tools: create_event');
    print('   Streaming response:\n');

    final toolCallIds = <String>{};
    final aggregator = ToolCallAggregator();

    await for (final part in streamChatParts(
      model: provider,
      promptIr: prompt,
      tools: tools,
    )) {
      switch (part) {
        case LLMTextDeltaPart(delta: final delta):
          stdout.write(delta);
          break;

        case LLMToolCallStartPart(toolCall: final toolCall):
          toolCallIds.add(toolCall.id);
          aggregator.addDelta(toolCall);
          print('\n   Tool Call Detected!');
          print('      Tool: ${toolCall.function.name}');
          break;

        case LLMToolCallDeltaPart(toolCall: final toolCall):
          aggregator.addDelta(toolCall);
          break;

        case LLMFinishPart():
          print('\n   Stream completed');
          break;

        case LLMErrorPart(error: final error):
          print('\n   Error: $error');
          break;

        default:
          break;
      }
    }

    final completedToolCalls = aggregator.completedCalls;

    print('\n   Results:');
    print('      Tool calls detected: ${toolCallIds.length}');
    if (completedToolCalls.isNotEmpty) {
      print('      Complex parameters working correctly!');
      for (final toolCall in completedToolCalls) {
        try {
          final args = jsonDecode(toolCall.function.arguments);
          print('      Arguments (formatted):');
          print('      ${JsonEncoder.withIndent('  ').convert(args)}');
        } catch (_) {
          print('      Arguments (raw): ${toolCall.function.arguments}');
        }
      }
    } else {
      print('      No tool calls detected');
    }
    print('');
  } catch (e) {
    print('   Error: $e\n');
  }
}
