// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// Groq Fast Inference - Ultra-Speed AI Demonstration
///
/// Showcases Groq's unique advantage: ultra-fast inference speeds.
/// For basic chat functionality, see ../../02_core_features/chat_basics.dart
///
/// Before running: export GROQ_API_KEY="your-groq-api-key"
void main() async {
  print('Groq Fast Inference Demo\n');

  final apiKey = Platform.environment['GROQ_API_KEY'] ?? 'gsk-TESTKEY';

  await demonstrateSpeedBenchmark(apiKey);
  await demonstrateStreamingSpeed(apiKey);
  await demonstrateParallelProcessing(apiKey);

  print('\nGroq speed demonstration completed!');
}

/// Demonstrate Groq's ultra-fast inference speeds
Future<void> demonstrateSpeedBenchmark(String apiKey) async {
  print('Speed Benchmark - Groq\'s Key Advantage\n');

  try {
    final model = await ai()
        .groq()
        .apiKey(apiKey)
        .model('llama-3.1-8b-instant') // Fastest model
        .temperature(0.7)
        .maxTokens(200)
        .buildLanguageModel();

    final testQuestions = [
      'What is machine learning?',
      'Explain quantum computing.',
      'What is blockchain?',
      'Define artificial intelligence.',
      'What is cloud computing?',
    ];

    print('Running speed benchmark with ${testQuestions.length} questions...');

    final times = <int>[];

    for (int i = 0; i < testQuestions.length; i++) {
      final stopwatch = Stopwatch()..start();
      final prompt = ChatPromptBuilder.user().text(testQuestions[i]).build();
      await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      stopwatch.stop();

      times.add(stopwatch.elapsedMilliseconds);
      print(
          '${i + 1}. ${testQuestions[i]} - ${stopwatch.elapsedMilliseconds}ms');
    }

    final avgTime = times.reduce((a, b) => a + b) / times.length;
    final minTime = times.reduce((a, b) => a < b ? a : b);
    final maxTime = times.reduce((a, b) => a > b ? a : b);

    print('\nSpeed Statistics:');
    print('• Average: ${avgTime.toStringAsFixed(1)}ms');
    print('• Fastest: ${minTime}ms');
    print('• Slowest: ${maxTime}ms');
    print(
        '• Consistency: ${((maxTime - minTime) / avgTime * 100).toStringAsFixed(1)}% variation');

    print('\nGroq Speed Advantages:');
    print('• Sub-second responses for most queries');
    print('• Consistent low latency');
    print('• Excellent for real-time applications\n');
  } catch (e) {
    print('Speed benchmark failed: $e\n');
  }
}

/// Demonstrate streaming speed performance
Future<void> demonstrateStreamingSpeed(String apiKey) async {
  print('Streaming Speed - Real-time Performance\n');

  try {
    final model = await ai()
        .groq()
        .apiKey(apiKey)
        .model('llama-3.1-8b-instant')
        .temperature(0.7)
        .maxTokens(300)
        .buildLanguageModel();

    final question = 'Write a short story about a robot discovering emotions.';
    print('Question: $question');
    print('Groq (streaming): ');

    final stopwatch = Stopwatch()..start();
    var firstChunkTime = 0;
    var chunkCount = 0;

    final prompt = ChatPromptBuilder.user().text(question).build();

    await for (final event in streamTextWithModel(
      model,
      promptMessages: [prompt],
    )) {
      switch (event) {
        case TextDeltaEvent(delta: final delta):
          chunkCount++;
          if (firstChunkTime == 0) {
            firstChunkTime = stopwatch.elapsedMilliseconds;
          }
          stdout.write(delta);
          break;

        case CompletionEvent():
          stopwatch.stop();
          print('\n');
          break;

        case ErrorEvent(error: final error):
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
  } catch (e) {
    print('Streaming demonstration failed: $e\n');
  }
}

/// Demonstrate parallel processing for high throughput
Future<void> demonstrateParallelProcessing(String apiKey) async {
  print('Parallel Processing - High Throughput\n');

  try {
    final model = await ai()
        .groq()
        .apiKey(apiKey)
        .model('llama-3.1-8b-instant')
        .temperature(0.7)
        .maxTokens(100)
        .buildLanguageModel();

    final questions = [
      'What is AI?',
      'What is ML?',
      'What is NLP?',
      'What is computer vision?',
      'What is robotics?',
    ];

    print('Processing ${questions.length} questions in parallel...');

    final stopwatch = Stopwatch()..start();

    // Process all questions simultaneously
    final futures = questions.map((q) {
      final prompt = ChatPromptBuilder.user().text(q).build();
      return generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
    }).toList();
    final responses = await Future.wait(futures);

    stopwatch.stop();

    print('\nResults:');
    for (int i = 0; i < questions.length; i++) {
      final text = responses[i].text ?? '';
      final preview = text.length > 80 ? '${text.substring(0, 80)}...' : text;
      print('${i + 1}. ${questions[i]}');
      print('   $preview\n');
    }

    print('Parallel Processing Performance:');
    print('• Total time: ${stopwatch.elapsedMilliseconds}ms');
    print(
        '• Average per question: ${(stopwatch.elapsedMilliseconds / questions.length).toStringAsFixed(1)}ms');
    print(
        '• Throughput: ${(questions.length * 1000 / stopwatch.elapsedMilliseconds).toStringAsFixed(1)} requests/sec');

    print('\nGroq Parallel Processing Benefits:');
    print('• High concurrent request handling');
    print('• Consistent performance under load');
    print('• Excellent for batch operations\n');
  } catch (e) {
    print('Parallel processing failed: $e\n');
  }
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
