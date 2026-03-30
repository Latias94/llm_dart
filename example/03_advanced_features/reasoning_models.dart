// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;

Future<void> main() async {
  await runAnthropicReasoning();
  await runDeepSeekReasoningStream();
  await runGoogleReasoning();
}

Future<void> runAnthropicReasoning() async {
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping Anthropic reasoning example.\n');
    return;
  }

  final model = llm.AI.anthropic(apiKey: apiKey).chatModel('claude-sonnet-4-5');
  final result = await core.generateText(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Solve 15% of 240 step by step.'),
    ],
  );

  print('Anthropic reasoning');
  print(result.reasoningText ?? '<no reasoning text>');
  print('Answer: ${result.text}\n');
}

Future<void> runDeepSeekReasoningStream() async {
  final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping DeepSeek reasoning stream example.\n');
    return;
  }

  final model = llm.AI.deepSeek(apiKey: apiKey).chatModel('deepseek-reasoner');

  print('DeepSeek reasoning stream');
  await for (final event in core.streamText(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Explain why 8 * 7 = 56.'),
    ],
  )) {
    switch (event) {
      case core.ReasoningDeltaEvent(:final delta):
        stderr.write(delta);
      case core.TextDeltaEvent(:final delta):
        stdout.write(delta);
      case core.FinishEvent():
        stdout.writeln('\n');
      default:
        break;
    }
  }
}

Future<void> runGoogleReasoning() async {
  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping Google reasoning example.\n');
    return;
  }

  final model = llm.AI.google(apiKey: apiKey).chatModel('gemini-2.5-flash');
  final result = await core.generateText(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Think through how layouts work in Flutter.'),
    ],
    callOptions: const core.CallOptions(
      providerOptions: google.GoogleGenerateTextOptions(
        includeThoughts: true,
      ),
    ),
  );

  print('Google reasoning');
  print(result.reasoningText ?? '<no reasoning text>');
  print('Answer: ${result.text}\n');
}
