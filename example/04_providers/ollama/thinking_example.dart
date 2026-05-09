// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama_pkg;

/// Local Ollama reasoning on the modern Ollama package surface.
///
/// This example keeps the stable shared chat contract while preserving
/// Ollama-specific local runtime controls through
/// `ollama_pkg.OllamaGenerateTextOptions`.
Future<void> main() async {
  final baseUrl = Platform.environment['OLLAMA_BASE_URL'] ??
      ollama_pkg.Ollama.defaultBaseUrl;

  print('Ollama Thinking - Local Reasoning With Open Models\n');

  await demonstrateBasicThinking(baseUrl);
  await demonstrateMathematicalReasoning(baseUrl);
  await demonstrateStreamingThinking(baseUrl);
  await demonstrateLogicalPuzzle(baseUrl);
  await demonstrateModelComparison(baseUrl);

  print('Ollama thinking demonstrations completed.');
}

Future<void> demonstrateBasicThinking(String baseUrl) async {
  print('=== Basic Thinking Process ===\n');

  try {
    final result = await _runReasonedCall(
      baseUrl: baseUrl,
      modelId: 'gpt-oss:latest',
      prompt: '''
I have 3 red balls, 2 blue balls, and 5 green balls in a bag.
If I randomly pick 3 balls without replacement, what is the probability
that I get exactly one ball of each color?
''',
      options: const core.GenerateTextOptions(
        temperature: 0.3,
        maxOutputTokens: 1000,
      ),
      providerOptions: const ollama_pkg.OllamaGenerateTextOptions(
        reasoning: true,
        numCtx: 4096,
        keepAlive: '5m',
      ),
    );

    print('Problem: probability calculation with colored balls');
    print('Model: gpt-oss:latest');

    final reasoning = result.reasoningText;
    if (reasoning != null && reasoning.isNotEmpty) {
      print('\nReasoning:');
      print(_truncate(reasoning, maxLength: 700));
    }

    print('\nFinal answer:');
    print(result.text);

    if (result.usage case final usage?) {
      print('\nUsage: ${usage.totalTokens} tokens');
    }

    print('Basic thinking demonstration completed.\n');
  } catch (error) {
    _printModelError(error);
    print('');
  }
}

Future<void> demonstrateMathematicalReasoning(String baseUrl) async {
  print('=== Mathematical Reasoning ===\n');

  try {
    final result = await _runReasonedCall(
      baseUrl: baseUrl,
      modelId: 'gpt-oss:latest',
      prompt: '''
A company's revenue follows this pattern:
- Month 1: \$10,000
- Month 2: \$12,000
- Month 3: \$14,400
- Month 4: \$17,280

What is the growth pattern, and what will be the revenue in Month 6?
Show your work step by step.
''',
      options: const core.GenerateTextOptions(
        temperature: 0.1,
        maxOutputTokens: 1500,
      ),
      providerOptions: const ollama_pkg.OllamaGenerateTextOptions(
        reasoning: true,
        numCtx: 6144,
        keepAlive: '5m',
      ),
    );

    print('Problem: revenue pattern analysis and prediction');

    final reasoning = result.reasoningText;
    if (reasoning != null && reasoning.isNotEmpty) {
      print('\nReasoning excerpt:');
      print(_truncate(reasoning, maxLength: 500));
    }

    print('\nAnalysis:');
    print(result.text);
    print('Mathematical reasoning demonstration completed.\n');
  } catch (error) {
    print('Mathematical reasoning failed: $error\n');
  }
}

Future<void> demonstrateStreamingThinking(String baseUrl) async {
  print('=== Streaming Thinking Process ===\n');

  try {
    final model = ollama_pkg.Ollama(
      baseUrl: baseUrl,
    ).chatModel('gpt-oss:latest');

    final stream = core.streamTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('''
Four people need to cross a bridge at night. They have one flashlight.
The bridge can hold only two people at a time. They must walk together
when crossing. Person A takes 1 minute, B takes 2 minutes, C takes 5 minutes,
and D takes 10 minutes. When two people cross together, they walk at the
slower person's pace. What is the minimum time to get everyone across?
'''),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.4,
        maxOutputTokens: 1200,
      ),
      callOptions: const core.CallOptions(
        providerOptions: ollama_pkg.OllamaGenerateTextOptions(
          reasoning: true,
          numCtx: 6144,
          keepAlive: '5m',
        ),
      ),
    );

    final reasoningBuffer = StringBuffer();
    final textBuffer = StringBuffer();
    var printedAnswerHeader = false;

    await for (final event in stream) {
      switch (event) {
        case core.ReasoningDeltaEvent(:final delta):
          reasoningBuffer.write(delta);
          stdout.write(delta);
        case core.TextDeltaEvent(:final delta):
          if (!printedAnswerHeader) {
            printedAnswerHeader = true;
            print('\n\nFinal answer:');
          }
          textBuffer.write(delta);
          stdout.write(delta);
        case core.ToolCallEvent(:final toolCall):
          print('\n[tool-call ${toolCall.toolName}]');
        case core.FinishEvent(:final usage):
          print('\n\nStreaming completed.');
          print('Reasoning length: ${reasoningBuffer.length} characters');
          print('Answer length: ${textBuffer.length} characters');
          if (usage != null) {
            print('Usage: ${usage.totalTokens} tokens');
          }
        case core.ErrorEvent(:final error):
          print('\nStream error: $error');
        default:
          break;
      }
    }

    print('\n');
  } catch (error) {
    print('Streaming thinking failed: $error\n');
  }
}

Future<void> demonstrateLogicalPuzzle(String baseUrl) async {
  print('=== Logical Puzzle Solving ===\n');

  try {
    final result = await _runReasonedCall(
      baseUrl: baseUrl,
      modelId: 'gpt-oss:latest',
      prompt: '''
You have 12 coins, one of which is fake (lighter than the others).
You have a balance scale and can use it exactly 3 times.
How do you identify the fake coin? Describe your strategy step by step.
''',
      options: const core.GenerateTextOptions(
        temperature: 0.3,
        maxOutputTokens: 1500,
      ),
      providerOptions: const ollama_pkg.OllamaGenerateTextOptions(
        reasoning: true,
        numCtx: 6144,
        keepAlive: '5m',
      ),
    );

    print('Puzzle: classic 12-coin balance-scale problem');

    final reasoning = result.reasoningText;
    if (reasoning != null && reasoning.isNotEmpty) {
      print('\nReasoning excerpt:');
      print(_truncate(reasoning, maxLength: 450));
    }

    print('\nSolution:');
    print(result.text);
    print('Logical puzzle demonstration completed.\n');
  } catch (error) {
    print('Logical puzzle failed: $error\n');
  }
}

Future<void> demonstrateModelComparison(String baseUrl) async {
  print('=== Model Comparison ===\n');

  const testProblem = '''
If you flip a fair coin 10 times and get 8 heads, what is the probability
of getting heads on the 11th flip? Explain your reasoning.
''';

  const models = ['gpt-oss:latest', 'qwen2.5:latest', 'llama3.2:latest'];

  for (final modelId in models) {
    print('Testing model: $modelId');

    try {
      final result = await _runReasonedCall(
        baseUrl: baseUrl,
        modelId: modelId,
        prompt: testProblem,
        options: const core.GenerateTextOptions(
          temperature: 0.2,
          maxOutputTokens: 800,
        ),
        providerOptions: const ollama_pkg.OllamaGenerateTextOptions(
          reasoning: true,
          numCtx: 4096,
          keepAlive: '3m',
        ),
      );

      final reasoning = result.reasoningText;
      if (reasoning != null && reasoning.isNotEmpty) {
        print('  reasoning: available (${reasoning.length} chars)');
      } else {
        print('  reasoning: not returned');
      }

      print('  answer length: ${result.text.length}');
      if (result.usage case final usage?) {
        print('  tokens: ${usage.totalTokens}');
      }
    } catch (error) {
      _printModelError(error, prefix: '  ');
    }

    print('');
  }

  print('Recommendations:');
  print('  - gpt-oss:latest: strong local reasoning baseline');
  print('  - qwen2.5:latest: balanced speed and quality');
  print('  - llama3.2:latest: lighter local option');
  print('');
}

Future<core.GenerateTextCallResult<void>> _runReasonedCall({
  required String baseUrl,
  required String modelId,
  required String prompt,
  required core.GenerateTextOptions options,
  required ollama_pkg.OllamaGenerateTextOptions providerOptions,
}) {
  final model = ollama_pkg.Ollama(
    baseUrl: baseUrl,
  ).chatModel(modelId);

  return core.generateTextCall<void>(
    model: model,
    prompt: [
      core.UserPromptMessage.text(prompt),
    ],
    options: options,
    callOptions: core.CallOptions(
      providerOptions: providerOptions,
    ),
  );
}

void _printModelError(Object error, {String prefix = ''}) {
  final message = error.toString();
  if (message.contains('404') ||
      message.contains('model') ||
      message.contains('not found')) {
    print(
        '${prefix}Model not available. Pull it first with `ollama pull ...`.');
    return;
  }

  print('${prefix}Thinking request failed: $error');
}

String _truncate(String text, {required int maxLength}) {
  if (text.length <= maxLength) {
    return text;
  }

  return '${text.substring(0, maxLength)}...';
}
