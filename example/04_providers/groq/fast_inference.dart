// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Groq Fast Inference - Ultra-Speed AI Demonstration
///
/// Showcases Groq's low-latency path through the stable model API.
/// For basic chat functionality, see ../../02_core_features/chat_basics.dart
///
/// Before running: export GROQ_API_KEY="your-groq-api-key"
Future<void> main() async {
  print('Groq Fast Inference Demo\n');

  final apiKey = Platform.environment['GROQ_API_KEY'] ?? 'gsk-TESTKEY';

  await demonstrateSpeedBenchmark(apiKey);
  await demonstrateStreamingSpeed(apiKey);
  await demonstrateParallelProcessing(apiKey);

  print('\nGroq speed demonstration completed!');
}

Future<void> demonstrateSpeedBenchmark(String apiKey) async {
  print('Speed Benchmark - Groq\'s Key Advantage\n');

  try {
    final model = _createGroqModel(apiKey);
    final testQuestions = [
      'What is machine learning?',
      'Explain quantum computing.',
      'What is blockchain?',
      'Define artificial intelligence.',
      'What is cloud computing?',
    ];

    print('Running speed benchmark with ${testQuestions.length} questions...');

    final times = <int>[];

    for (var index = 0; index < testQuestions.length; index++) {
      final question = testQuestions[index];
      final stopwatch = Stopwatch()..start();
      await _generateText(
        model,
        question,
        maxOutputTokens: 200,
      );
      stopwatch.stop();

      times.add(stopwatch.elapsedMilliseconds);
      print('${index + 1}. $question - ${stopwatch.elapsedMilliseconds}ms');
    }

    final avgTime = times.reduce((a, b) => a + b) / times.length;
    final minTime = times.reduce((a, b) => a < b ? a : b);
    final maxTime = times.reduce((a, b) => a > b ? a : b);

    print('\nSpeed Statistics:');
    print('• Average: ${avgTime.toStringAsFixed(1)}ms');
    print('• Fastest: ${minTime}ms');
    print('• Slowest: ${maxTime}ms');
    print(
      '• Consistency: ${((maxTime - minTime) / avgTime * 100).toStringAsFixed(1)}% variation',
    );

    print('\nGroq Speed Advantages:');
    print('• Sub-second responses for most queries');
    print('• Consistent low latency');
    print('• Excellent for real-time applications\n');
  } catch (error) {
    print('Speed benchmark failed: $error\n');
  }
}

Future<void> demonstrateStreamingSpeed(String apiKey) async {
  print('Streaming Speed - Real-time Performance\n');

  try {
    final model = _createGroqModel(apiKey);
    const question = 'Write a short story about a robot discovering emotions.';
    print('Question: $question');
    print('Groq (streaming): ');

    final stopwatch = Stopwatch()..start();
    var firstChunkTime = 0;
    var chunkCount = 0;

    final stream = core.streamTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(question),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.7,
        maxOutputTokens: 300,
      ),
    );

    await for (final event in stream) {
      switch (event) {
        case core.TextDeltaEvent(:final delta):
          chunkCount++;
          if (firstChunkTime == 0) {
            firstChunkTime = stopwatch.elapsedMilliseconds;
          }
          stdout.write(delta);
        case core.FinishEvent():
          stopwatch.stop();
          print('\n');
        case core.ErrorEvent(:final error):
          print('\nStreaming error: $error');
          return;
        default:
          break;
      }
    }

    print('\nStreaming Performance:');
    print('• Time to first chunk: ${firstChunkTime}ms');
    print('• Total time: ${stopwatch.elapsedMilliseconds}ms');
    print('• Chunks received: $chunkCount');
    print('• Ultra-fast time to first token\n');
  } catch (error) {
    print('Streaming demonstration failed: $error\n');
  }
}

Future<void> demonstrateParallelProcessing(String apiKey) async {
  print('Parallel Processing - High Throughput\n');

  try {
    final model = _createGroqModel(apiKey);
    final questions = [
      'What is AI?',
      'What is ML?',
      'What is NLP?',
      'What is computer vision?',
      'What is robotics?',
    ];

    print('Processing ${questions.length} questions in parallel...');

    final stopwatch = Stopwatch()..start();
    final responses = await Future.wait(
      questions.map(
        (question) => _generateText(
          model,
          question,
          maxOutputTokens: 100,
        ),
      ),
    );
    stopwatch.stop();

    print('\nResults:');
    for (var index = 0; index < questions.length; index++) {
      final text = responses[index].text;
      final preview = text.length > 80 ? '${text.substring(0, 80)}...' : text;
      print('${index + 1}. ${questions[index]}');
      print('   $preview\n');
    }

    final elapsedMilliseconds = stopwatch.elapsedMilliseconds;
    print('Parallel Processing Performance:');
    print('• Total time: ${elapsedMilliseconds}ms');
    print(
      '• Average per question: ${(elapsedMilliseconds / questions.length).toStringAsFixed(1)}ms',
    );
    print(
      '• Throughput: ${_itemsPerSecond(questions.length, elapsedMilliseconds).toStringAsFixed(1)} requests/sec',
    );

    print('\nGroq Parallel Processing Benefits:');
    print('• High concurrent request handling');
    print('• Consistent performance under load');
    print('• Excellent for batch operations\n');
  } catch (error) {
    print('Parallel processing failed: $error\n');
  }
}

core.LanguageModel _createGroqModel(String apiKey) {
  return openai.groq(apiKey: apiKey).chatModel('llama-3.1-8b-instant');
}

Future<core.GenerateTextCallResult<Never>> _generateText(
  core.LanguageModel model,
  String prompt, {
  int maxOutputTokens = 200,
}) {
  return core.generateTextCall<Never>(
    model: model,
    prompt: [
      core.UserPromptMessage.text(prompt),
    ],
    options: core.GenerateTextOptions(
      temperature: 0.7,
      maxOutputTokens: maxOutputTokens,
    ),
  );
}

double _itemsPerSecond(int count, int elapsedMilliseconds) {
  if (elapsedMilliseconds <= 0) {
    return count.toDouble();
  }

  return count * 1000 / elapsedMilliseconds;
}

/// Groq's Key Advantages:
///
/// Speed: Ultra-fast inference (50-200ms typical)
/// Consistency: Low latency variation
/// Throughput: High concurrent request handling
/// Streaming: Excellent real-time performance
///
/// Best for: Real-time apps, interactive assistants, gaming
/// Models: llama-3.1-8b-instant (fastest), llama-3.1-70b-versatile (quality)
///
/// See ../../02_core_features/ for basic chat functionality
