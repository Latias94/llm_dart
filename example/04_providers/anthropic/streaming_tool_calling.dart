// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;

/// Anthropic streaming tool-calling examples built on the stable shared stream
/// API plus Anthropic's stable chat model facade.
Future<void> main() async {
  print('🌊 Anthropic Streaming Tool Calling\n');

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Error: ANTHROPIC_API_KEY environment variable not set');
    print('   Please set it before running this example.');
    return;
  }

  final model = anthropic
      .anthropic(
        apiKey: apiKey,
      )
      .chatModel('claude-sonnet-4-5');

  print('✅ Stable model created: ${model.providerId}/${model.modelId}\n');

  await demonstrateBasicStreamingTool(model);
  await demonstrateMultipleToolsStreaming(model);
  await demonstrateComplexParametersStreaming(model);

  print('✅ All streaming tool calling examples completed!');
}

Future<void> demonstrateBasicStreamingTool(core.LanguageModel model) async {
  print('🔧 Basic Streaming Tool Call:\n');

  final tools = [
    core.FunctionToolDefinition(
      name: 'get_weather',
      description: 'Get the current weather for a city.',
      inputSchema: core.ToolJsonSchema.object(
        properties: const {
          'location': {
            'type': 'string',
            'description': 'City name to look up.',
          },
          'unit': {
            'type': 'string',
            'description': 'Temperature unit.',
            'enum': ['celsius', 'fahrenheit'],
          },
        },
        required: const ['location'],
      ),
    ),
  ];

  print('   User: What is the weather like in Tokyo? Use celsius.');
  print('   Available tools: get_weather');
  print('   Streaming response:\n');

  await _streamToolScenario(
    model: model,
    prompt: [
      core.UserPromptMessage.text(
        'What is the weather like in Tokyo? Use celsius.',
      ),
    ],
    tools: tools,
    expectedMinimumToolCalls: 1,
  );
}

Future<void> demonstrateMultipleToolsStreaming(core.LanguageModel model) async {
  print('🔧 Multiple Tools Streaming:\n');

  final tools = [
    core.FunctionToolDefinition(
      name: 'get_weather',
      description: 'Get the current weather for a city.',
      inputSchema: core.ToolJsonSchema.object(
        properties: const {
          'location': {
            'type': 'string',
            'description': 'City name to look up.',
          },
        },
        required: const ['location'],
      ),
    ),
    core.FunctionToolDefinition(
      name: 'get_time',
      description: 'Get the current time for a timezone.',
      inputSchema: core.ToolJsonSchema.object(
        properties: const {
          'timezone': {
            'type': 'string',
            'description': 'Timezone like Asia/Tokyo.',
          },
        },
        required: const ['timezone'],
      ),
    ),
  ];

  print('   User: What is the weather in Paris and what time is it in Tokyo?');
  print('   Available tools: get_weather, get_time');
  print('   Streaming response:\n');

  await _streamToolScenario(
    model: model,
    prompt: [
      core.UserPromptMessage.text(
        'What is the weather in Paris and what time is it in Tokyo?',
      ),
    ],
    tools: tools,
    expectedMinimumToolCalls: 2,
  );
}

Future<void> demonstrateComplexParametersStreaming(
  core.LanguageModel model,
) async {
  print('🔧 Complex Parameters Streaming:\n');

  final tools = [
    core.FunctionToolDefinition(
      name: 'create_event',
      description: 'Create a calendar event.',
      inputSchema: core.ToolJsonSchema.object(
        properties: const {
          'title': {
            'type': 'string',
            'description': 'Event title.',
          },
          'attendees': {
            'type': 'array',
            'description': 'List of attendee email addresses.',
            'items': {
              'type': 'string',
            },
          },
          'location': {
            'type': 'object',
            'description': 'Event location details.',
            'properties': {
              'name': {
                'type': 'string',
                'description': 'Location name.',
              },
              'address': {
                'type': 'string',
                'description': 'Location address.',
              },
            },
          },
        },
        required: const ['title', 'attendees'],
      ),
    ),
  ];

  print(
    '   User: Create a meeting titled "Team Sync" with attendees '
    'alice@example.com and bob@example.com at Conference Room A.',
  );
  print('   Available tools: create_event');
  print('   Streaming response:\n');

  await _streamToolScenario(
    model: model,
    prompt: [
      core.UserPromptMessage.text(
        'Create a meeting titled "Team Sync" with attendees '
        'alice@example.com and bob@example.com at Conference Room A.',
      ),
    ],
    tools: tools,
    expectedMinimumToolCalls: 1,
  );
}

Future<void> _streamToolScenario({
  required core.LanguageModel model,
  required List<core.PromptMessage> prompt,
  required List<core.FunctionToolDefinition> tools,
  required int expectedMinimumToolCalls,
}) async {
  final stream = core.streamTextCall(
    model: model,
    prompt: prompt,
    tools: tools,
    toolChoice: const core.RequiredToolChoice(),
    options: const core.GenerateTextOptions(
      temperature: 0.1,
      maxOutputTokens: 1000,
    ),
  );

  final toolInputs = <String, StringBuffer>{};
  final toolNames = <String, String>{};
  final toolCalls = <core.ToolCallContent>[];
  final responseText = StringBuffer();

  await for (final event in stream) {
    switch (event) {
      case core.ResponseMetadataEvent(:final responseId, :final modelId):
        print('   [response=$responseId model=$modelId]');
      case core.TextDeltaEvent(:final delta):
        responseText.write(delta);
        stdout.write(delta);
      case core.ToolInputStartEvent(
          :final toolCallId,
          :final toolName,
          :final providerExecuted,
          :final isDynamic,
          :final title,
        ):
        toolInputs[toolCallId] = StringBuffer();
        toolNames[toolCallId] = toolName;
        print('\n   🔧 Tool input started: $toolName');
        print('      Call ID: $toolCallId');
        print('      Provider executed: $providerExecuted');
        print('      Dynamic tool: $isDynamic');
        if (title != null && title.isNotEmpty) {
          print('      Title: $title');
        }
      case core.ToolInputDeltaEvent(:final toolCallId, :final delta):
        toolInputs.putIfAbsent(toolCallId, StringBuffer.new).write(delta);
      case core.ToolInputEndEvent(:final toolCallId):
        final encodedInput = toolInputs[toolCallId]?.toString() ?? '{}';
        final decodedInput = _decodeJsonSafely(encodedInput);
        print(
            '      Input assembled for ${toolNames[toolCallId] ?? toolCallId}:');
        print('      ${_formatJson(decodedInput)}');
      case core.ToolCallEvent(:final toolCall):
        toolCalls.add(toolCall);
        print('   ✅ Tool call emitted: ${toolCall.toolName}');
        print('      Tool Call ID: ${toolCall.toolCallId}');
        print('      Input: ${_formatJson(toolCall.input)}');
      case core.FinishEvent(:final finishReason, :final usage):
        print('\n   ✅ Stream completed');
        print('      Finish reason: $finishReason');
        if (usage != null) {
          print('      Total tokens: ${usage.totalTokens}');
        }
      case core.ErrorEvent(:final error):
        print('\n   ❌ Error: $error');
      default:
        break;
    }
  }

  final finalText = (await stream.text).trim();

  print('\n   Results:');
  print('      Tool calls detected: ${toolCalls.length}');
  print(
    '      Tool streaming status: '
    '${toolCalls.length >= expectedMinimumToolCalls ? '✅ expected activity observed' : '⚠️ fewer tool calls than expected'}',
  );
  print(
    '      Final text length: '
    '${finalText.isNotEmpty ? finalText.length : responseText.length} characters',
  );
  print('');
}

Object? _decodeJsonSafely(String input) {
  try {
    return jsonDecode(input);
  } catch (_) {
    return input;
  }
}

String _formatJson(Object? value) {
  if (value == null) {
    return 'null';
  }

  if (value is Map || value is List) {
    return JsonEncoder.withIndent('  ').convert(value);
  }

  return value.toString();
}
