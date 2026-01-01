import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Anthropic (Claude) tool use + interleaved thinking example.
///
/// References:
/// - Messages API: https://docs.anthropic.com/en/api/messages
/// - Interleaved thinking: https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
///
/// This demonstrates the recommended "standard surface" path:
/// - Build prompts with `Prompt` IR
/// - Run local tools via `llm_dart_ai` tool loops
/// - Stream output as Vercel-style `LLMStreamPart`s
///
/// Setup:
/// - `export ANTHROPIC_API_KEY=...`
Future<void> main() async {
  registerAnthropic();

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('Missing API key. Set `ANTHROPIC_API_KEY`.');
    exitCode = 1;
    return;
  }

  // Enable "reasoning" + interleaved thinking (best-effort; API may reject).
  final model = await LLMBuilder()
      .provider(anthropicProviderId)
      .apiKey(apiKey)
      .model('claude-sonnet-4-20250514')
      .maxTokens(800)
      .providerOptions(anthropicProviderId, const {
    'reasoning': true,
    'interleavedThinking': true,
    'thinkingBudgetTokens': 1024,
  }).build();

  final toolSet = ToolSet([
    functionTool(
      name: 'get_weather',
      description: 'Get weather for a location.',
      parameters: const ParametersSchema(
        schemaType: 'object',
        properties: {
          'location': ParameterProperty(
            propertyType: 'string',
            description: 'City name (e.g. SF).',
          ),
        },
        required: ['location'],
      ),
      handler: (toolCall, {cancelToken}) async {
        final args = jsonDecode(toolCall.function.arguments);
        if (args is! Map) return {'error': 'invalid args'};
        final location = args['location']?.toString() ?? 'unknown';
        return {
          'location': location,
          'temperatureC': 18,
          'condition': 'Partly cloudy',
        };
      },
    ),
  ]);

  final prompt = Prompt(
    messages: [
      PromptMessage.system(
        'You are a helpful assistant. When you need factual data, call tools.',
        providerOptions: const {
          'anthropic': {
            'cacheControl': {'type': 'ephemeral'},
          },
        },
      ),
      PromptMessage.user(
        'What is the weather in SF? Call get_weather, then answer in 2 bullets.',
        providerOptions: const {
          'anthropic': {
            'cacheControl': {'type': 'ephemeral'},
          },
        },
      ),
    ],
  );

  stdout.writeln('--- streaming tool loop (Prompt IR) ---');

  await for (final part in streamToolLoopPartsWithToolSet(
    model: model,
    promptIr: prompt,
    toolSet: toolSet,
    maxSteps: 5,
  )) {
    switch (part) {
      case LLMTextDeltaPart(:final delta):
        stdout.write(delta);
      case LLMReasoningDeltaPart(:final delta):
        stderr.write(delta);
      case LLMToolCallStartPart(:final toolCall):
        stdout.writeln('\n\n[tool_call] ${toolCall.function.name}');
        stdout.writeln('args: ${toolCall.function.arguments}');
      case LLMToolResultPart(:final result):
        stdout.writeln('\n[tool_result] ${result.toolCallId}');
        stdout.writeln(result.content);
      case LLMFinishPart(:final response):
        stdout.writeln('\n\n--- done ---');
        stdout.writeln('text: ${response.text}');
        stdout.writeln('thinking: ${response.thinking}');
        stdout.writeln('providerMetadata: ${response.providerMetadata}');
      default:
        break;
    }
  }
}
