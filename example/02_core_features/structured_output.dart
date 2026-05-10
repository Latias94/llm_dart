// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

Future<void> main() async {
  print('Structured Output\n');

  await runOpenAIObjectExample();
  await runOpenAIStreamingObjectExample();
  await runOpenAIArrayExample();
  await runOpenAIStreamingArrayExample();
  await runGoogleChoiceExample();
}

Future<void> runOpenAIObjectExample() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
        'Skipping OpenAI object example because OPENAI_API_KEY is not set.\n');
    return;
  }

  final model = llm.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
  try {
    final result = await core.generateObject<PersonSummary>(
      model: model,
      prompt: [
        core.SystemPromptMessage.text(
          'Return structured JSON only.',
        ),
        core.UserPromptMessage.text(
          'Summarize Ada Lovelace as a person profile with name, role, and two strengths.',
        ),
      ],
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
    );

    print('OpenAI object output');
    print('Name: ${result.output.name}');
    print('Role: ${result.output.role}');
    print('Strengths: ${result.output.strengths.join(', ')}\n');
  } catch (error) {
    print('OpenAI object example failed: $error\n');
  }
}

Future<void> runOpenAIStreamingObjectExample() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
        'Skipping OpenAI streaming object example because OPENAI_API_KEY is not set.\n');
    return;
  }

  final model = llm.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
  try {
    final streamResult = core.streamObject<PersonSummary>(
      model: model,
      prompt: [
        core.SystemPromptMessage.text('Return structured JSON only.'),
        core.UserPromptMessage.text(
          'Stream a short profile for Grace Hopper with name, role, and two strengths.',
        ),
      ],
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
    );

    print('OpenAI streaming object output');
    await for (final event in streamResult.eventStream) {
      if (event
          case core.OutputPartialEvent<PersonSummary>(
            :final partialOutput,
          )) {
        print('Partial: $partialOutput');
      }
    }
    final output = await streamResult.output;
    print('Final: ${output.name} / ${output.role}\n');
  } catch (error) {
    print('OpenAI streaming object example failed: $error\n');
  }
}

Future<void> runOpenAIArrayExample() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping OpenAI array example because OPENAI_API_KEY is not set.\n');
    return;
  }

  final model = llm.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
  try {
    final result = await core.generateTextCall<List<String>>(
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
  } catch (error) {
    print('OpenAI array example failed: $error\n');
  }
}

Future<void> runOpenAIStreamingArrayExample() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
        'Skipping OpenAI streaming array example because OPENAI_API_KEY is not set.\n');
    return;
  }

  final model = llm.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
  try {
    final streamResult = core.streamTextCall<List<String>>(
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

    print('OpenAI streaming array output');
    await for (final element in streamResult.elementStream<String>()) {
      print('Element: $element');
    }
    final output = await streamResult.output;
    print('Final array length: ${output.length}\n');
  } catch (error) {
    print('OpenAI streaming array example failed: $error\n');
  }
}

Future<void> runGoogleChoiceExample() async {
  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
        'Skipping Google choice example because GOOGLE_API_KEY is not set.\n');
    return;
  }

  final model = llm.google(apiKey: apiKey).chatModel('gemini-2.5-flash');
  try {
    final result = await core.generateTextCall<String>(
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
  } catch (error) {
    print('Google choice example failed: $error\n');
  }
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
