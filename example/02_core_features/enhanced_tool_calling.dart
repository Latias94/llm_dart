// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/provider_authoring.dart' as authoring;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

/// Stable-first advanced tool calling examples.
///
/// This example demonstrates:
/// - local tool-choice validation before any network request
/// - nested JSON-schema tool inputs
/// - tool-call replay using shared prompt parts
/// - structured final answers with `ObjectOutputSpec`
/// - provider-owned OpenAI tool controls through typed provider options
Future<void> main() async {
  print('Enhanced Tool Calling\n');

  await demonstrateLocalToolChoiceValidation();

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run the remote tool examples.');
    return;
  }

  final model = openai.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');

  await demonstrateNestedToolReplay(model);
  await demonstrateProviderOwnedToolControls(model);

  print('Enhanced tool calling completed.');
}

Future<void> demonstrateLocalToolChoiceValidation() async {
  print('=== Local Tool Choice Validation ===\n');

  try {
    await core.generateTextCall(
      model: const _UnusedLanguageModel(),
      messages: [
        core.UserModelMessage.text('Plan a calm evening in Kyoto.'),
      ],
      tools: [
        _tripResearchTool(),
      ],
      toolChoice: const core.SpecificToolChoice('missing_tool'),
    );
    print('Unexpected success.\n');
  } on ArgumentError catch (error) {
    final normalized = core.ModelError.fromUnknown(error);
    print('Original error: ${error.message}');
    print('Normalized kind: ${normalized.kind.name}');
    print('Normalized message: ${normalized.message}\n');
  }
}

Future<void> demonstrateNestedToolReplay(core.LanguageModel model) async {
  print('=== Nested Schema Tool Replay ===\n');

  const question = '''
Plan a relaxed Kyoto evening for two travelers.
Use the build_itinerary_context tool before answering.
Keep the plan walkable and below 180 USD.
''';

  final firstTurn = await core.generateTextCall(
    model: model,
    messages: [
      core.UserModelMessage.text(question),
    ],
    tools: [
      _tripResearchTool(),
    ],
    toolChoice: const core.SpecificToolChoice('build_itinerary_context'),
    options: const core.GenerateTextOptions(
      temperature: 0.2,
      maxOutputTokens: 500,
    ),
  );

  final toolCalls = firstTurn.content
      .whereType<core.ToolCallContentPart>()
      .map((part) => part.toolCall)
      .toList(growable: false);

  if (toolCalls.isEmpty) {
    print('Model did not produce a tool call.');
    print('Text: ${firstTurn.text}\n');
    return;
  }

  print('Requested tool calls: ${toolCalls.length}');
  for (final toolCall in toolCalls) {
    print('Tool: ${toolCall.toolName}');
    print('Input:\n${_formatJson(toolCall.input)}\n');
  }

  final finalTurn = await core.generateTextCall<ItinerarySummary>(
    model: model,
    messages: [
      core.SystemModelMessage.text(
        'Return JSON only. Build the final answer strictly from the provided '
        'tool results.',
      ),
      core.UserModelMessage.text(question),
      _assistantReplayMessage(
        text: firstTurn.text,
        toolCalls: toolCalls,
      ),
      for (final toolCall in toolCalls)
        core.ToolModelMessage.result(
          toolCallId: toolCall.toolCallId,
          toolName: toolCall.toolName,
          toolOutput: core.JsonToolOutput(
            _mockTripResearchOutput(toolCall),
          ),
        ),
    ],
    outputSpec: core.ObjectOutputSpec<ItinerarySummary>(
      schema: core.JsonSchema.object(
        properties: const {
          'headline': {'type': 'string'},
          'summary': {'type': 'string'},
          'stops': {
            'type': 'array',
            'items': {'type': 'string'},
            'minItems': 2,
          },
          'estimated_budget': {'type': 'number'},
          'provider_notes': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        required: const [
          'headline',
          'summary',
          'stops',
          'estimated_budget',
          'provider_notes',
        ],
        additionalProperties: false,
      ),
      decode: ItinerarySummary.fromJson,
    ),
    options: const core.GenerateTextOptions(
      temperature: 0.2,
      maxOutputTokens: 700,
    ),
  );

  print('Structured headline: ${finalTurn.output.headline}');
  print('Structured summary: ${finalTurn.output.summary}');
  print('Stops: ${finalTurn.output.stops.join(' -> ')}');
  print(
      'Estimated budget: ${finalTurn.output.estimatedBudgetUsd.toStringAsFixed(2)} USD');
  print('Provider notes: ${finalTurn.output.providerNotes.join(' | ')}');
  print('');
}

Future<void> demonstrateProviderOwnedToolControls(
  core.LanguageModel model,
) async {
  print('=== Provider-Owned OpenAI Tool Controls ===\n');

  const question = '''
Build a rainy Osaka evening plan.
Use both get_weather and shortlist_venues if helpful before you answer.
''';

  final firstTurn = await core.generateTextCall(
    model: model,
    messages: [
      core.UserModelMessage.text(question),
    ],
    tools: [
      _weatherTool(),
      _venueTool(),
    ],
    toolChoice: const core.RequiredToolChoice(),
    options: const core.GenerateTextOptions(
      temperature: 0.2,
      maxOutputTokens: 500,
    ),
    callOptions: const core.CallOptions(
      providerOptions: openai.OpenAIGenerateTextOptions(
        parallelToolCalls: true,
        maxToolCalls: 2,
        metadata: {
          'example': 'enhanced_tool_calling',
          'mode': 'provider_owned_controls',
        },
      ),
    ),
  );

  final toolCalls = firstTurn.content
      .whereType<core.ToolCallContentPart>()
      .map((part) => part.toolCall)
      .toList(growable: false);

  print('Tool calls requested: ${toolCalls.length}');
  for (final toolCall in toolCalls) {
    print('- ${toolCall.toolName}: ${_compactJson(toolCall.input)}');
  }

  print('');
  print('OpenAI-specific note:');
  print(
    '  `parallelToolCalls` and `maxToolCalls` stay inside '
    '`package:llm_dart/openai.dart` typed options.',
  );
  print(
    '  The shared tool abstraction remains provider-agnostic, while request'
    ' controls that only OpenAI understands remain provider-owned.\n',
  );
}

core.FunctionToolDefinition _tripResearchTool() {
  return core.FunctionToolDefinition(
    name: 'build_itinerary_context',
    description: 'Collect planning context for a city itinerary.',
    inputSchema: core.ToolJsonSchema.object(
      properties: const {
        'destination': {
          'type': 'object',
          'properties': {
            'city': {'type': 'string'},
            'country': {'type': 'string'},
          },
          'required': ['city', 'country'],
          'additionalProperties': false,
        },
        'travelers': {
          'type': 'array',
          'minItems': 1,
          'items': {
            'type': 'object',
            'properties': {
              'label': {'type': 'string'},
              'preferences': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
            'required': ['label'],
            'additionalProperties': false,
          },
        },
        'constraints': {
          'type': 'object',
          'properties': {
            'maxBudget': {'type': 'number'},
            'walkingTolerance': {
              'type': 'string',
              'enum': ['low', 'medium', 'high'],
            },
            'mustAvoid': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
          'required': ['maxBudget'],
          'additionalProperties': false,
        },
        'goal': {'type': 'string'},
      },
      required: const [
        'destination',
        'travelers',
        'constraints',
        'goal',
      ],
      additionalProperties: false,
    ),
  );
}

core.FunctionToolDefinition _weatherTool() {
  return core.FunctionToolDefinition(
    name: 'get_weather',
    description: 'Get current weather conditions for a city.',
    inputSchema: core.ToolJsonSchema.object(
      properties: const {
        'city': {'type': 'string'},
        'unit': {
          'type': 'string',
          'enum': ['celsius', 'fahrenheit'],
        },
      },
      required: const ['city'],
      additionalProperties: false,
    ),
  );
}

core.FunctionToolDefinition _venueTool() {
  return core.FunctionToolDefinition(
    name: 'shortlist_venues',
    description: 'Find indoor venues for a city plan.',
    inputSchema: core.ToolJsonSchema.object(
      properties: const {
        'city': {'type': 'string'},
        'mood': {'type': 'string'},
        'budget': {'type': 'number'},
      },
      required: const ['city', 'mood'],
      additionalProperties: false,
    ),
  );
}

core.AssistantModelMessage _assistantReplayMessage({
  required String text,
  required List<core.ToolCallContent> toolCalls,
}) {
  return core.AssistantModelMessage(
    parts: [
      if (text.trim().isNotEmpty) core.TextModelPart(text),
      for (final toolCall in toolCalls)
        core.ToolCallModelPart(
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

Map<String, Object?> _mockTripResearchOutput(core.ToolCallContent toolCall) {
  final input = _asJsonMap(toolCall.input);
  final destination = _asJsonMap(input['destination']);
  final constraints = _asJsonMap(input['constraints']);
  final travelers = switch (input['travelers']) {
    final List values => values.length,
    _ => 0,
  };

  return {
    'city': destination['city'] ?? 'Kyoto',
    'country': destination['country'] ?? 'Japan',
    'traveler_count': travelers,
    'weather_window': 'Light rain after 20:00, comfortable before then.',
    'recommended_areas': ['Gion', 'Pontocho', 'Kawaramachi'],
    'budget_ceiling': constraints['maxBudget'] ?? 180,
    'notes': [
      'Prefer indoor dining after 20:00.',
      'Keep walking segments under 15 minutes.',
      'Reserve tea-house seating in advance.',
    ],
  };
}

Map<String, Object?> _asJsonMap(Object? value) {
  if (value is! Map) {
    return const {};
  }

  return value.map((key, nestedValue) {
    return MapEntry(key.toString(), nestedValue);
  });
}

String _formatJson(Object? value) {
  if (value == null) {
    return 'null';
  }

  if (value is Map || value is List) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  return value.toString();
}

String _compactJson(Object? value) {
  if (value == null) {
    return 'null';
  }

  if (value is Map || value is List) {
    return jsonEncode(value);
  }

  return value.toString();
}

final class ItinerarySummary {
  final String headline;
  final String summary;
  final List<String> stops;
  final double estimatedBudgetUsd;
  final List<String> providerNotes;

  const ItinerarySummary({
    required this.headline,
    required this.summary,
    required this.stops,
    required this.estimatedBudgetUsd,
    required this.providerNotes,
  });

  factory ItinerarySummary.fromJson(Map<String, Object?> json) {
    final stops = json['stops'];
    final providerNotes = json['provider_notes'];
    final estimatedBudget = json['estimated_budget'];

    return ItinerarySummary(
      headline: json['headline']! as String,
      summary: json['summary']! as String,
      stops: switch (stops) {
        final List values => List<String>.unmodifiable(
            values.map((value) => value as String),
          ),
        _ => const [],
      },
      estimatedBudgetUsd: switch (estimatedBudget) {
        final num value => value.toDouble(),
        _ => 0,
      },
      providerNotes: switch (providerNotes) {
        final List values => List<String>.unmodifiable(
            values.map((value) => value as String),
          ),
        _ => const [],
      },
    );
  }
}

final class _UnusedLanguageModel implements core.LanguageModel {
  const _UnusedLanguageModel();

  @override
  String get providerId => 'example';

  @override
  String get modelId => 'unused';

  @override
  Future<core.GenerateTextResult> doGenerate(
    authoring.GenerateTextRequest request,
  ) {
    throw StateError('This model should never be called.');
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    authoring.GenerateTextRequest request,
  ) {
    return const Stream.empty();
  }
}
