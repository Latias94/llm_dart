// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  print('Structured Output\n');

  await runOpenAIObjectExample();
  await runOpenAIStreamingObjectExample();
  await runOpenAIArrayExample();
  await runGoogleChoiceExample();
}

Future<void> runOpenAIObjectExample() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
        'Skipping OpenAI object example because OPENAI_API_KEY is not set.\n');
    return;
  }

  final model = llm.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
  final result = await core.generateOutput<PersonSummary>(
    model: model,
    prompt: [
      core.SystemPromptMessage.text(
        'Return structured JSON only.',
      ),
      core.UserPromptMessage.text(
        'Summarize Ada Lovelace as a person profile with name, role, and two strengths.',
      ),
    ],
    outputSpec: core.ObjectOutputSpec<PersonSummary>(
      schema: core.JsonSchema.object(
        properties: const {
          'name': {'type': 'string'},
          'role': {'type': 'string'},
          'strengths': {
            'type': 'array',
            'items': {'type': 'string'},
            'minItems': 2,
            'maxItems': 2,
          },
        },
        required: const ['name', 'role', 'strengths'],
        additionalProperties: false,
      ),
      decode: PersonSummary.fromJson,
    ),
  );

  print('OpenAI object output');
  print('Name: ${result.output.name}');
  print('Role: ${result.output.role}');
  print('Strengths: ${result.output.strengths.join(', ')}\n');
}

Future<void> runOpenAIStreamingObjectExample() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
        'Skipping OpenAI streaming object example because OPENAI_API_KEY is not set.\n');
    return;
  }

  final model = llm.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');

  print('OpenAI streaming object output');
  await for (final event in core.streamOutput<PersonSummary>(
    model: model,
    prompt: [
      core.SystemPromptMessage.text('Return structured JSON only.'),
      core.UserPromptMessage.text(
        'Stream a short profile for Grace Hopper with name, role, and two strengths.',
      ),
    ],
    outputSpec: core.ObjectOutputSpec<PersonSummary>(
      schema: core.JsonSchema.object(
        properties: const {
          'name': {'type': 'string'},
          'role': {'type': 'string'},
          'strengths': {
            'type': 'array',
            'items': {'type': 'string'},
            'minItems': 2,
            'maxItems': 2,
          },
        },
        required: const ['name', 'role', 'strengths'],
        additionalProperties: false,
      ),
      decode: PersonSummary.fromJson,
    ),
  )) {
    switch (event) {
      case core.OutputPartialEvent<PersonSummary>(:final partialOutput):
        print('Partial: $partialOutput');
      case core.OutputResultEvent<PersonSummary>(:final result):
        print('Final: ${result.output.name} / ${result.output.role}\n');
      default:
        break;
    }
  }
}

Future<void> runOpenAIArrayExample() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping OpenAI array example because OPENAI_API_KEY is not set.\n');
    return;
  }

  final model = llm.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
  final result = await core.generateOutput<List<String>>(
    model: model,
    prompt: [
      core.UserPromptMessage.text(
        'Return three short Flutter layout tips as an array of strings.',
      ),
    ],
    outputSpec: core.ArrayOutputSpec<String>(
      elementSchema: core.JsonSchema.string(),
      decodeElement: (json) => json! as String,
      name: 'layout_tips',
      description: 'A short list of Flutter layout tips.',
    ),
  );

  print('OpenAI array output');
  for (final item in result.output) {
    print('- $item');
  }
  print('');
}

Future<void> runGoogleChoiceExample() async {
  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
        'Skipping Google choice example because GOOGLE_API_KEY is not set.\n');
    return;
  }

  final model = llm.AI.google(apiKey: apiKey).chatModel('gemini-2.5-flash');
  final result = await core.generateOutput<String>(
    model: model,
    prompt: [
      core.UserPromptMessage.text(
        'Classify this tone as one of: calm, urgent, playful. Text: "We should fix this today before users notice."',
      ),
    ],
    outputSpec: core.ChoiceOutputSpec<String>(
      options: const ['calm', 'urgent', 'playful'],
      name: 'tone',
      description: 'Tone classification result.',
    ),
  );

  print('Google choice output');
  print('Tone: ${result.output}\n');
}

final class PersonSummary {
  final String name;
  final String role;
  final List<String> strengths;

  const PersonSummary({
    required this.name,
    required this.role,
    required this.strengths,
  });

  factory PersonSummary.fromJson(Map<String, Object?> json) {
    final strengths = json['strengths'];
    return PersonSummary(
      name: json['name']! as String,
      role: json['role']! as String,
      strengths: switch (strengths) {
        final List values => List<String>.unmodifiable(
            values.map((value) => value as String),
          ),
        _ => const [],
      },
    );
  }
}
