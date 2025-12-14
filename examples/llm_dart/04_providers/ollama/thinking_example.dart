// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 🦙 Ollama Thinking - Local Reasoning with Open Models
///
/// This example demonstrates Ollama's thinking capabilities with reasoning models:
/// - Local inference with thinking models
/// - Step-by-step reasoning process
/// - Streaming thinking observations
/// - Various reasoning model comparisons
///
/// Prerequisites:
/// 1. Install Ollama: https://ollama.ai/
/// 2. Pull a reasoning model: ollama pull gpt-oss:latest
/// 3. Start Ollama server: ollama serve
void main() async {
  print('🦙 Ollama Thinking - Local Reasoning with Open Models\n');

  // Demonstrate various Ollama thinking capabilities
  await demonstrateBasicThinking();
  await demonstrateMathematicalReasoning();
  await demonstrateStreamingThinking();
  await demonstrateLogicalPuzzle();
  await demonstrateModelComparison();

  print('\n✅ Ollama thinking demonstrations completed!');
}

/// Demonstrate basic thinking process with Ollama
Future<void> demonstrateBasicThinking() async {
  print('🧠 Basic Thinking Process:\n');

  try {
    final model = await ai()
        .ollama()
        .baseUrl('http://localhost:11434')
        .model('gpt-oss:latest')
        .reasoning(true)
        .temperature(0.3)
        .maxTokens(1000)
        .buildLanguageModel();

    final prompt = ChatPromptBuilder.user().text('''
I have 3 red balls, 2 blue balls, and 5 green balls in a bag.
If I randomly pick 3 balls without replacement, what's the probability
that I get exactly one ball of each color?
''').build();

    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('   Problem: Probability calculation with colored balls');
    print('   Model: gpt-oss:latest (local reasoning model)');

    // Show the thinking process if available
    if (response.thinking != null && response.thinking!.isNotEmpty) {
      print('\n   🧠 Ollama\'s Thinking Process:');
      print('   ${'-' * 50}');
      print('   ${response.thinking}');
      print('   ${'-' * 50}');
    }

    print('\n   🎯 Final Answer:');
    print('   ${response.text}');

    if (response.usage != null) {
      print('\n   📊 Usage: ${response.usage!.totalTokens} tokens');
    }

    print('   ✅ Basic thinking demonstration completed\n');
  } catch (e) {
    if (e.toString().contains('404') ||
        e.toString().contains('model') ||
        e.toString().contains('not found')) {
      print(
          '   ❌ Model not available. Try running: ollama pull gpt-oss:latest');
      print('   📋 Alternative models: qwen2.5:latest, llama3.2:latest');
    } else {
      print('   ❌ Basic thinking failed: $e');
    }
    print('\n');
  }
}

/// Demonstrate mathematical reasoning
Future<void> demonstrateMathematicalReasoning() async {
  print('🔢 Mathematical Reasoning:\n');

  try {
    final model = await ai()
        .ollama()
        .baseUrl('http://localhost:11434')
        .model('gpt-oss:latest')
        .reasoning(true)
        .temperature(0.1) // Lower for precise calculations
        .maxTokens(1500)
        .buildLanguageModel();

    final mathProblem = '''
A company's revenue follows this pattern:
- Month 1: \$10,000
- Month 2: \$12,000
- Month 3: \$14,400
- Month 4: \$17,280

What is the growth pattern, and what will be the revenue in Month 6?
Show your work step by step.
''';

    final prompt = ChatPromptBuilder.user().text(mathProblem).build();
    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('   Problem: Revenue pattern analysis and prediction');

    if (response.thinking != null && response.thinking!.isNotEmpty) {
      print('\n   🧠 Ollama\'s Mathematical Process:');
      print('   ${'-' * 60}');
      // Show first part of thinking to avoid too much output
      final thinking = response.thinking!;
      if (thinking.length > 500) {
        print('   ${thinking.substring(0, 500)}...');
        print(
            '   [Thinking process continues for ${thinking.length} total characters]');
      } else {
        print('   $thinking');
      }
      print('   ${'-' * 60}');
    }

    print('\n   🎯 Mathematical Analysis:');
    print('   ${response.text}');

    print('   ✅ Mathematical reasoning demonstration completed\n');
  } catch (e) {
    print('   ❌ Mathematical reasoning failed: $e\n');
  }
}

/// Demonstrate streaming thinking
Future<void> demonstrateStreamingThinking() async {
  print('🌊 Streaming Thinking Process:\n');

  try {
    final model = await ai()
        .ollama()
        .baseUrl('http://localhost:11434')
        .model('gpt-oss:latest')
        .reasoning(true)
        .temperature(0.4)
        .maxTokens(1200)
        .buildLanguageModel();

    print('   Problem: Logic puzzle with real-time thinking');
    print('   Watching Ollama think in real-time...\n');

    var thinkingContent = StringBuffer();
    var responseContent = StringBuffer();
    var isThinking = true;

    final prompt = ChatPromptBuilder.user().text('''
Four people need to cross a bridge at night. They have one flashlight.
The bridge can hold only two people at a time. They must walk together
when crossing. Person A takes 1 minute, B takes 2 minutes, C takes 5 minutes,
and D takes 10 minutes. When two people cross together, they walk at the
slower person's pace. What's the minimum time to get everyone across?
''').build();

    await for (final event in streamTextWithModel(
      model,
      promptMessages: [prompt],
    )) {
      switch (event) {
        case ThinkingDeltaEvent(delta: final delta):
          thinkingContent.write(delta);
          // Print thinking in gray color
          stdout.write('\x1B[90m$delta\x1B[0m');
          break;
        case TextDeltaEvent(delta: final delta):
          if (isThinking) {
            print('\n\n   🎯 Ollama\'s Final Answer:');
            print('   ${'-' * 40}');
            isThinking = false;
          }
          responseContent.write(delta);
          stdout.write(delta);
          break;
        case CompletionEvent(response: final response):
          print('\n   ${'-' * 40}');
          print('\n   ✅ Streaming thinking completed!');

          if (response.usage != null) {
            print('   📊 Usage: ${response.usage!.totalTokens} tokens');
          }

          print('   🧠 Thinking length: ${thinkingContent.length} characters');
          print('   📝 Response length: ${responseContent.length} characters');
          break;
        case ErrorEvent(error: final error):
          print('\n   ❌ Stream error: $error');
          break;
        case ToolCallDeltaEvent():
          // Handle tool call events if needed
          break;
      }
    }

    print('   ✅ Streaming thinking demonstration completed\n');
  } catch (e) {
    print('   ❌ Streaming thinking failed: $e\n');
  }
}

/// Demonstrate logical puzzle solving
Future<void> demonstrateLogicalPuzzle() async {
  print('🧩 Logical Puzzle Solving:\n');

  try {
    final model = await ai()
        .ollama()
        .baseUrl('http://localhost:11434')
        .model('gpt-oss:latest')
        .reasoning(true)
        .temperature(0.3)
        .maxTokens(1500)
        .buildLanguageModel();

    final logicPuzzle = '''
You have 12 coins, one of which is fake (lighter than the others).
You have a balance scale and can use it exactly 3 times.
How do you identify the fake coin? Describe your strategy step by step.
''';

    final prompt = ChatPromptBuilder.user().text(logicPuzzle).build();
    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('   Puzzle: Classic 12-coin balance scale problem');

    if (response.thinking != null && response.thinking!.isNotEmpty) {
      print('\n   🧠 Ollama\'s Logic Process:');
      print('   ${'-' * 50}');
      // Show key parts of logical thinking
      final thinking = response.thinking!;
      final lines = thinking.split('\n');
      var importantLines = <String>[];

      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('step') ||
            lowerLine.contains('weigh') ||
            lowerLine.contains('divide') ||
            lowerLine.contains('strategy')) {
          importantLines.add(line.trim());
        }
      }

      if (importantLines.isNotEmpty) {
        for (final line in importantLines.take(5)) {
          print('   $line');
        }
        if (importantLines.length > 5) {
          print('   ... [${importantLines.length - 5} more logical steps]');
        }
      } else {
        print('   ${thinking.substring(0, 400)}...');
      }
      print('   ${'-' * 50}');
    }

    print('\n   🎯 Logical Solution:');
    print('   ${response.text}');

    print('   ✅ Logical puzzle demonstration completed\n');
  } catch (e) {
    print('   ❌ Logical puzzle failed: $e\n');
  }
}

/// Demonstrate model comparison
Future<void> demonstrateModelComparison() async {
  print('📊 Model Comparison:\n');

  final testProblem = '''
If you flip a fair coin 10 times and get 8 heads, what's the probability
of getting heads on the 11th flip? Explain your reasoning.
''';

  final models = ['gpt-oss:latest', 'qwen2.5:latest', 'llama3.2:latest'];

  for (final modelId in models) {
    print('   Testing model: $modelId');

    try {
      final model = await ai()
          .ollama()
          .baseUrl('http://localhost:11434')
          .model(modelId)
          .reasoning(true)
          .temperature(0.2)
          .maxTokens(800)
          .buildLanguageModel();

      final prompt = ChatPromptBuilder.user().text(testProblem).build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );

      if (response.thinking != null && response.thinking!.isNotEmpty) {
        print('   ✅ Thinking capability: Available');
        print('   🧠 Thinking length: ${response.thinking!.length} characters');
      } else {
        print('   ⚠️  Thinking capability: Not available');
      }

      print('   📝 Response quality: ${response.text?.length ?? 0} characters');

      if (response.usage != null) {
        print('   📊 Token usage: ${response.usage!.totalTokens}');
      }

      print('   ${'-' * 30}');
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        print('   ❌ Model not available (not pulled)');
      } else {
        print('   ❌ Model test failed: $e');
      }
      print('   ${'-' * 30}');
    }
  }

  print('   💡 Model Recommendations:');
  print('      • gpt-oss:latest: Best for reasoning tasks');
  print('      • qwen2.5:latest: Good balance of speed and quality');
  print('      • llama3.2:latest: Lightweight option');

  print('   ✅ Model comparison demonstration completed\n');
}

/// 🎯 Key Ollama Thinking Concepts Summary:
///
/// Local Reasoning Benefits:
/// - Complete privacy and data control
/// - No API costs or rate limits
/// - Offline capability
/// - Custom model fine-tuning possible
///
/// Thinking Process Features:
/// - Step-by-step reasoning observation
/// - Mathematical calculation verification
/// - Logical puzzle breakdown
/// - Real-time thinking via streaming
///
/// Best Practices:
/// - Use lower temperature (0.1-0.3) for analytical tasks
/// - Allow sufficient token budget for thinking
/// - Test multiple models for best results
/// - Stream thinking for real-time insight
///
/// Model Selection:
/// - gpt-oss: Specialized reasoning model
/// - qwen2.5: Good general-purpose option
/// - llama3.2: Lightweight alternative
///
/// Configuration Tips:
/// - Ensure Ollama server is running
/// - Pre-pull models before use
/// - Monitor system resources for large models
/// - Use reasoning=true flag for thinking
///
/// Limitations:
/// - Requires local computational resources
/// - Model availability depends on local pulls
/// - Thinking quality varies by model
/// - Slower than cloud-based solutions
///
/// Next Steps:
/// - ../anthropic/extended_thinking.dart: Compare with cloud reasoning
/// - ../../03_advanced_features/reasoning_models.dart: Cross-provider comparison
/// - vision_capabilities.dart: Visual reasoning with local models
