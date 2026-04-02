// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

/// OpenAI advanced examples centered on the stable chat-model facade, shared
/// text-call helpers, and typed OpenAI provider options.
Future<void> main() async {
  print('🔵 OpenAI Advanced Features - Reasoning and Tools\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    return;
  }

  await demonstrateReasoningModels(apiKey);
  await demonstrateFunctionCalling(apiKey);
  await demonstrateAssistantLikeWorkflows(apiKey);
  await demonstrateAdvancedConfiguration(apiKey);
  await demonstrateStreamingFeatures(apiKey);

  print('✅ OpenAI advanced features completed!');
}

Future<void> demonstrateReasoningModels(String apiKey) async {
  print('🧠 Reasoning Models (GPT-5.1):\n');

  final model = _openAIModel(apiKey, 'gpt-5.1');
  const complexProblem = '''
A farmer has chickens and rabbits. In total, there are 35 heads and 94 legs.
How many chickens and how many rabbits does the farmer have?
Show your reasoning step by step.
''';

  try {
    final stopwatch = Stopwatch()..start();
    final response = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(complexProblem),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 2000,
      ),
      callOptions: const core.CallOptions(
        timeout: Duration(seconds: 120),
        providerOptions: openai.OpenAIGenerateTextOptions(
          reasoningEffort: openai.OpenAIReasoningEffort.medium,
          verbosity: 'high',
        ),
      ),
    );
    stopwatch.stop();

    print('   Model: ${model.modelId}');
    print('   Problem: Chickens and rabbits puzzle');
    print('   Time: ${stopwatch.elapsedMilliseconds}ms');

    if (response.reasoningText case final reasoning?) {
      final previewLength = reasoning.length < 240 ? reasoning.length : 240;
      print('   Reasoning preview: ${reasoning.substring(0, previewLength)}...');
    } else {
      print('   Reasoning preview: <not exposed>');
    }

    print('   Final answer: ${response.text}');
    _printUsage(response);

    print('\n   💡 Reasoning Model Tips:');
    print('      • Use GPT-5.1 for longer multi-step reasoning.');
    print('      • Keep reasoning effort inside OpenAI provider options.');
    print('      • Allow longer timeouts for difficult prompts.');
    print('   ✅ Reasoning models demonstration completed\n');
  } catch (error) {
    print('   ❌ Reasoning models failed: $error\n');
  }
}

Future<void> demonstrateFunctionCalling(String apiKey) async {
  print('🔧 Function Calling:\n');

  final model = _openAIModel(apiKey, 'gpt-5.1');
  final tools = [
    _weatherTool(),
    _calculatorTool(),
  ];
  const question =
      'What is the weather like in Tokyo and calculate 15 * 23? '
      'Use both tools before answering.';

  try {
    final firstTurn = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(question),
      ],
      tools: tools,
      toolChoice: const core.RequiredToolChoice(),
      options: const core.GenerateTextOptions(
        temperature: 0.3,
        maxOutputTokens: 800,
      ),
    );

    final toolCalls = firstTurn.content
        .whereType<core.ToolCallContentPart>()
        .map((part) => part.toolCall)
        .toList(growable: false);

    print('   User: $question');

    if (toolCalls.isEmpty) {
      print('   Response: ${firstTurn.text}');
      print('   ⚠️  No tool calls were produced');
      print('   ✅ Function calling demonstration completed\n');
      return;
    }

    print('   Tool calls:');
    for (final toolCall in toolCalls) {
      print('      • ${toolCall.toolName}: ${_formatJson(toolCall.input)}');
    }

    final replayPrompt = <core.PromptMessage>[
      core.UserPromptMessage.text(question),
      _assistantReplayMessage(
        text: firstTurn.text,
        toolCalls: toolCalls,
      ),
      for (final toolCall in toolCalls)
        core.ToolPromptMessage(
          toolName: toolCall.toolName,
          parts: [
            core.ToolResultPromptPart(
              toolCallId: toolCall.toolCallId,
              toolName: toolCall.toolName,
              output: _mockToolOutput(toolCall),
            ),
          ],
        ),
    ];

    final secondTurn = await core.generateTextCall(
      model: model,
      prompt: replayPrompt,
      options: const core.GenerateTextOptions(
        temperature: 0.2,
        maxOutputTokens: 700,
      ),
    );

    print('   Final response: ${secondTurn.text}');
    _printUsage(secondTurn);
    print('   ✅ Function calling demonstration completed\n');
  } catch (error) {
    print('   ❌ Function calling failed: $error\n');
  }
}

Future<void> demonstrateAssistantLikeWorkflows(String apiKey) async {
  print('🤖 Assistant-Like Workflows:\n');

  final model = _openAIModel(apiKey, 'gpt-5.1');

  try {
    print('   ℹ️  The older Assistants/Threads convenience surfaces are still');
    print('      compatibility-oriented and are not the target architecture.');
    print('   ℹ️  For stable app code, prefer a normal chat model plus system');
    print('      instructions, persisted prompt history, and provider-owned tools.');

    final response = await core.generateTextCall(
      model: model,
      prompt: [
        core.SystemPromptMessage.text('''
You are a patient and helpful math tutor. When solving problems:
1. Break down the problem into steps
2. Explain each step clearly
3. Show all calculations
4. Verify the answer
'''),
        core.UserPromptMessage.text(
          'Solve this quadratic equation: 2x² + 5x - 3 = 0',
        ),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 900,
      ),
      callOptions: const core.CallOptions(
        providerOptions: openai.OpenAIGenerateTextOptions(
          reasoningEffort: openai.OpenAIReasoningEffort.medium,
          verbosity: 'high',
        ),
      ),
    );

    print('   Stable assistant-like response:');
    print('   ${response.text}');
    print('   ✅ Assistant-like workflow demonstration completed\n');
  } catch (error) {
    print('   ❌ Assistant-like workflow failed: $error\n');
  }
}

Future<void> demonstrateAdvancedConfiguration(String apiKey) async {
  print('⚙️  Advanced Configuration:\n');

  final model = _openAIModel(apiKey, 'gpt-5.1');

  print('   Structured Output:');
  try {
    final structured = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('''
Extract information from this text and return it as JSON:
"John Smith, age 30, works as a software engineer at TechCorp.
He lives in San Francisco and has 5 years of experience."
'''),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 500,
      ),
      callOptions: const core.CallOptions(
        providerOptions: openai.OpenAIGenerateTextOptions(
          responseFormat: openai.OpenAIJsonSchemaResponseFormat(
            name: 'person_record',
            strict: true,
            schema: {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'age': {'type': 'number'},
                'job': {'type': 'string'},
                'company': {'type': 'string'},
                'location': {'type': 'string'},
                'experience_years': {'type': 'number'},
              },
              'required': [
                'name',
                'age',
                'job',
                'company',
                'location',
                'experience_years',
              ],
            },
          ),
          metadata: {
            'demo': 'advanced_features',
            'mode': 'structured_output',
          },
        ),
      ),
    );

    print('      Structured response: ${_formatJson(_tryDecodeJson(structured.text))}');
    _printUsage(structured);
  } catch (error) {
    print('      ❌ Structured output error: $error');
  }

  print('\n   Stable OpenAI-Owned Controls:');
  try {
    final creative = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Write a creative short story about an AI lighthouse keeper.',
        ),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.7,
        topP: 0.9,
        maxOutputTokens: 500,
      ),
      callOptions: const core.CallOptions(
        providerOptions: openai.OpenAIGenerateTextOptions(
          serviceTier: 'auto',
          reasoningEffort: openai.OpenAIReasoningEffort.low,
          verbosity: 'high',
          metadata: {
            'demo': 'advanced_features',
            'mode': 'creative',
          },
          user: 'advanced-features-example',
        ),
      ),
    );

    final preview = creative.text.length < 240
        ? creative.text
        : '${creative.text.substring(0, 240)}...';
    print('      Creative response preview: $preview');
    print(
      '      Service tier: '
      '${creative.providerMetadata?.namespace('openai')?['serviceTier'] ?? 'unknown'}',
    );
    _printUsage(creative);
  } catch (error) {
    print('      ❌ Stable OpenAI control error: $error');
  }

  print('\n   💡 Stable Configuration Tips:');
  print('      • Use OpenAIJsonSchemaResponseFormat for provider-owned JSON output.');
  print('      • Keep service tier, reasoning effort, and metadata inside');
  print('        OpenAIGenerateTextOptions.');
  print('      • Treat legacy raw token-bias and compatibility assistants helpers');
  print('        as boundary APIs until they are redesigned.');
  print('   ✅ Advanced configuration demonstration completed\n');
}

Future<void> demonstrateStreamingFeatures(String apiKey) async {
  print('🌊 Advanced Streaming:\n');

  final model = _openAIModel(apiKey, 'gpt-5.1');
  final tools = [_weatherTool()];
  const question =
      'Tell me about the weather in Paris and write a short poem about it. '
      'Use the weather tool first.';

  try {
    print('   Streaming planning + tool calls...');

    final planningStream = core.streamTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(question),
      ],
      tools: tools,
      toolChoice: const core.RequiredToolChoice(),
      options: const core.GenerateTextOptions(
        temperature: 0.7,
        maxOutputTokens: 700,
      ),
    );

    final planningText = StringBuffer();
    final toolCalls = <core.ToolCallContent>[];

    await for (final event in planningStream) {
      switch (event) {
        case core.TextDeltaEvent(:final delta):
          planningText.write(delta);
          stdout.write(delta);
        case core.ToolInputStartEvent(:final toolName):
          print('\n\n🔧 Tool input started: $toolName');
        case core.ToolCallEvent(:final toolCall):
          toolCalls.add(toolCall);
          print('\n   Tool call: ${toolCall.toolName}');
          print('   Input: ${_formatJson(toolCall.input)}');
        case core.FinishEvent(:final usage):
          print('\n✅ First streaming pass completed');
          if (usage != null) {
            print('   Tokens used: ${usage.totalTokens}');
          }
        case core.ErrorEvent(:final error):
          print('\n❌ Stream error: $error');
        default:
          break;
      }
    }

    final planningTextValue = (await planningStream.text).trim();
    print('\n   First pass text length: ${planningTextValue.length} characters');
    print('   Tool calls: ${toolCalls.length}');

    if (toolCalls.isEmpty) {
      print('   ℹ️  Model did not call tools during streaming');
      print('   ✅ Advanced streaming demonstration completed\n');
      return;
    }

    print('\n   Streaming final answer with tool results...');

    final finalStream = core.streamTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(question),
        _assistantReplayMessage(
          text: planningTextValue,
          toolCalls: toolCalls,
        ),
        for (final toolCall in toolCalls)
          core.ToolPromptMessage(
            toolName: toolCall.toolName,
            parts: [
              core.ToolResultPromptPart(
                toolCallId: toolCall.toolCallId,
                toolName: toolCall.toolName,
                output: _mockToolOutput(toolCall),
              ),
            ],
          ),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.7,
        maxOutputTokens: 700,
      ),
    );

    final finalText = StringBuffer();

    await for (final event in finalStream) {
      switch (event) {
        case core.TextDeltaEvent(:final delta):
          finalText.write(delta);
          stdout.write(delta);
        case core.FinishEvent(:final usage):
          print('\n\n✅ Second streaming pass completed');
          if (usage != null) {
            print('   Tokens used: ${usage.totalTokens}');
          }
        case core.ErrorEvent(:final error):
          print('\n❌ Stream error: $error');
        default:
          break;
      }
    }

    print('\n   Final streamed answer length: ${finalText.length} characters');
    print('   ✅ Advanced streaming demonstration completed\n');
  } catch (error) {
    print('   ❌ Advanced streaming failed: $error\n');
  }
}

core.LanguageModel _openAIModel(String apiKey, String modelId) {
  return llm.AI.openai(
    apiKey: apiKey,
  ).chatModel(modelId);
}

core.FunctionToolDefinition _weatherTool() {
  return core.FunctionToolDefinition(
    name: 'get_weather',
    description: 'Get current weather information for a location.',
    inputSchema: core.ToolJsonSchema.object(
      properties: const {
        'location': {
          'type': 'string',
          'description': 'City name or location.',
        },
        'unit': {
          'type': 'string',
          'description': 'Temperature unit.',
          'enum': ['celsius', 'fahrenheit'],
        },
      },
      required: const ['location'],
    ),
  );
}

core.FunctionToolDefinition _calculatorTool() {
  return core.FunctionToolDefinition(
    name: 'calculate',
    description: 'Perform mathematical calculations.',
    inputSchema: core.ToolJsonSchema.object(
      properties: const {
        'expression': {
          'type': 'string',
          'description': 'Mathematical expression to evaluate.',
        },
      },
      required: const ['expression'],
    ),
  );
}

core.AssistantPromptMessage _assistantReplayMessage({
  required String text,
  required List<core.ToolCallContent> toolCalls,
}) {
  return core.AssistantPromptMessage(
    parts: [
      if (text.trim().isNotEmpty) core.TextPromptPart(text),
      for (final toolCall in toolCalls)
        core.ToolCallPromptPart(
          toolCallId: toolCall.toolCallId,
          toolName: toolCall.toolName,
          input: toolCall.input,
          providerExecuted: toolCall.providerExecuted,
          isDynamic: toolCall.isDynamic,
          title: toolCall.title,
        ),
    ],
  );
}

Map<String, Object?> _mockToolOutput(core.ToolCallContent toolCall) {
  final input = _asJsonMap(toolCall.input);

  switch (toolCall.toolName) {
    case 'get_weather':
      return {
        'location': input['location'] ?? 'unknown',
        'temperature': 22,
        'condition': 'sunny',
        'humidity': 65,
      };
    case 'calculate':
      final expression = input['expression']?.toString() ?? '';
      return {
        'expression': expression,
        'result': expression.trim() == '15 * 23' ? 345 : 'not-evaluated',
      };
    default:
      return {
        'error': 'Unknown function',
      };
  }
}

Map<String, Object?> _asJsonMap(Object? value) {
  if (value is! Map) {
    return const {};
  }

  return value.map((key, nestedValue) {
    return MapEntry(key.toString(), nestedValue);
  });
}

Object? _tryDecodeJson(String text) {
  try {
    return jsonDecode(text);
  } catch (_) {
    return text;
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

void _printUsage(core.GenerateTextCallResult<dynamic> result) {
  if (result.usage case final usage?) {
    print(
      '   Usage: total=${usage.totalTokens}, '
      'input=${usage.inputTokens}, '
      'output=${usage.outputTokens}, '
      'reasoning=${usage.reasoningTokens}',
    );
    return;
  }

  print('   Usage: <unavailable>');
}
