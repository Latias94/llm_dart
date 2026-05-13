// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

Future<void> main() async {
  final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set DEEPSEEK_API_KEY to run this example.');
    return;
  }

  final model = llm.deepSeek(apiKey: apiKey).chatModel('deepseek-reasoner');

  print('Streaming response:\n');

  final stream = core.streamTextCall(
    model: model,
    messages: [
      core.UserModelMessage.text('Solve 15 * 27 and show your reasoning.'),
    ],
  );

  await for (final event in stream) {
    switch (event) {
      case core.ResponseMetadataEvent(
          :final responseId,
          :final modelId,
        ):
        stdout.writeln('[response=$responseId model=$modelId]');
      case core.ReasoningDeltaEvent(:final delta):
        stderr.write(delta);
      case core.TextDeltaEvent(:final delta):
        stdout.write(delta);
      case core.ToolInputStartEvent(:final toolName):
        stdout.writeln('\n[tool-input-start $toolName]');
      case core.ToolCallEvent(:final toolCall):
        stdout.writeln('\n[tool-call ${toolCall.toolName}]');
      case core.FinishEvent(:final finishReason, :final usage):
        stdout.writeln(
          '\n\n[finish=$finishReason totalTokens=${usage?.totalTokens}]',
        );
      case core.ErrorEvent(:final error):
        stderr.writeln('\n[error] $error');
      default:
        break;
    }
  }

  stderr.writeln('\n[finalText] ${await stream.text}');
}
