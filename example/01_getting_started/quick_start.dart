// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/ai.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  print('Quick Start\n');

  await runOpenAIExample();
  await runAnthropicExample();
  await runGoogleExample();
}

Future<void> runOpenAIExample() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping OpenAI example because OPENAI_API_KEY is not set.\n');
    return;
  }

  final model = llm.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.SystemPromptMessage.text('You are concise.'),
      core.UserPromptMessage.text('Explain Dart in one sentence.'),
    ],
  );

  print('OpenAI');
  print(result.text);
  print('');
}

Future<void> runAnthropicExample() async {
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping Anthropic example because ANTHROPIC_API_KEY is not set.\n');
    return;
  }

  final model = llm.AI.anthropic(apiKey: apiKey).chatModel('claude-sonnet-4-5');
  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Summarize why strong typing helps APIs.'),
    ],
  );

  print('Anthropic');
  print(result.text);
  print('');
}

Future<void> runGoogleExample() async {
  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping Google example because GOOGLE_API_KEY is not set.\n');
    return;
  }

  final model = llm.AI.google(apiKey: apiKey).chatModel('gemini-2.5-flash');
  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Give one sentence about Flutter layouts.'),
    ],
  );

  print('Google');
  print(result.text);
  print('');
}
