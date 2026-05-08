// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/llm_dart.dart' as llm;

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

  final model = llm.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
  final result = await llm.generateTextCall(
    model: model,
    prompt: [
      llm.SystemPromptMessage.text('You are concise.'),
      llm.UserPromptMessage.text('Explain Dart in one sentence.'),
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

  final model = llm.anthropic(apiKey: apiKey).chatModel('claude-sonnet-4-5');
  final result = await llm.generateTextCall(
    model: model,
    prompt: [
      llm.UserPromptMessage.text('Summarize why strong typing helps APIs.'),
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

  final model = llm.google(apiKey: apiKey).chatModel('gemini-2.5-flash');
  final result = await llm.generateTextCall(
    model: model,
    prompt: [
      llm.UserPromptMessage.text('Give one sentence about Flutter layouts.'),
    ],
  );

  print('Google');
  print(result.text);
  print('');
}
