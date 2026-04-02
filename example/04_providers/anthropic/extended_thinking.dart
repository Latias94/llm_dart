// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

/// 🟣 Anthropic Extended Thinking - Access Claude's Reasoning Process
///
/// This example demonstrates Claude's extended-thinking capabilities through
/// the stable `AI.anthropic(...).chatModel(...)` API plus typed Anthropic
/// provider options.
///
/// Before running, set your API key:
/// export ANTHROPIC_API_KEY="your-anthropic-api-key"
Future<void> main() async {
  print('🟣 Anthropic Extended Thinking - Claude\'s Reasoning Process\n');

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'] ?? 'sk-ant-TESTKEY';

  await demonstrateBasicThinking(apiKey);
  await demonstrateComplexReasoning(apiKey);
  await demonstrateStreamingThinking(apiKey);
  await demonstrateEthicalReasoning(apiKey);
  await demonstrateComparativeAnalysis(apiKey);

  print('\n✅ Anthropic extended thinking completed!');
}

Future<void> demonstrateBasicThinking(String apiKey) async {
  print('🧠 Basic Thinking Process:\n');

  try {
    final model = _createAnthropicModel(apiKey);
    final response = await _generateThinkingText(
      model: model,
      prompt: [
        core.UserPromptMessage.text('''
I have a 3-gallon jug and a 5-gallon jug. I need to measure exactly 4 gallons of water.
How can I do this? Please show your thinking process step by step.
'''),
      ],
      maxOutputTokens: 1500,
    );

    print(
      '   Problem: Water jug puzzle (3-gallon and 5-gallon jugs, measure 4 gallons)',
    );
    print('   Model: claude-sonnet-4-5');

    final reasoning = response.reasoningText;
    if (reasoning != null && reasoning.isNotEmpty) {
      print('\n   🧠 Claude\'s Thinking Process:');
      print('   ${'-' * 50}');
      print('   $reasoning');
      print('   ${'-' * 50}');
    }

    print('\n   🎯 Final Answer:');
    print('   ${response.text}');

    if (response.usage != null) {
      print('\n   📊 Usage: ${response.usage!.totalTokens} tokens');
    }

    print('   ✅ Basic thinking demonstration completed\n');
  } catch (error) {
    print('   ❌ Basic thinking failed: $error\n');
  }
}

Future<void> demonstrateComplexReasoning(String apiKey) async {
  print('🔬 Complex Reasoning:\n');

  try {
    final model = _createAnthropicModel(apiKey);
    const complexProblem = '''
A company is considering two investment options:

Option A: Invest \$100,000 now, receive \$15,000 per year for 10 years
Option B: Invest \$80,000 now, receive \$12,000 per year for 8 years,
         then receive a lump sum of \$50,000 at the end

Assuming a discount rate of 8%, which option is better?
Please show all calculations and reasoning.
''';

    final response = await _generateThinkingText(
      model: model,
      prompt: [
        core.UserPromptMessage.text(complexProblem),
      ],
      maxOutputTokens: 2000,
      thinkingBudgetTokens: 3072,
    );

    print('   Problem: Investment analysis with NPV calculations');

    final reasoning = response.reasoningText;
    if (reasoning != null && reasoning.isNotEmpty) {
      print('\n   🧠 Claude\'s Analytical Process:');
      print('   ${'-' * 60}');
      if (reasoning.length > 500) {
        print('   ${reasoning.substring(0, 500)}...');
        print(
          '   [Thinking process continues for ${reasoning.length} total characters]',
        );
      } else {
        print('   $reasoning');
      }
      print('   ${'-' * 60}');
    }

    print('\n   🎯 Final Analysis:');
    print('   ${response.text}');

    print('   ✅ Complex reasoning demonstration completed\n');
  } catch (error) {
    print('   ❌ Complex reasoning failed: $error\n');
  }
}

Future<void> demonstrateStreamingThinking(String apiKey) async {
  print('🌊 Streaming Thinking Process:\n');

  try {
    final model = _createAnthropicModel(apiKey);

    print('   Problem: Logic puzzle with real-time thinking');
    print('   Watching Claude think in real-time...\n');

    final thinkingContent = StringBuffer();
    final responseContent = StringBuffer();
    var isThinking = true;

    final stream = core.streamTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('''
Five friends (Alice, Bob, Carol, David, Eve) are sitting in a row.
- Alice is not at either end
- Bob is somewhere to the left of Carol
- David is next to Eve
- Carol is not next to Alice

What is the seating arrangement? Show your reasoning.
'''),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 1500,
      ),
      callOptions: _thinkingCallOptions(
        thinkingBudgetTokens: 3072,
        interleavedThinking: true,
      ),
    );

    await for (final event in stream) {
      switch (event) {
        case core.ReasoningDeltaEvent(:final delta):
          thinkingContent.write(delta);
          stdout.write('\x1B[90m$delta\x1B[0m');
        case core.TextDeltaEvent(:final delta):
          if (isThinking) {
            print('\n\n   🎯 Claude\'s Final Answer:');
            print('   ${'-' * 40}');
            isThinking = false;
          }
          responseContent.write(delta);
          stdout.write(delta);
        case core.FinishEvent(:final usage):
          print('\n   ${'-' * 40}');
          print('\n   ✅ Streaming thinking completed!');

          if (usage != null) {
            print('   📊 Usage: ${usage.totalTokens} tokens');
          }

          print('   🧠 Thinking length: ${thinkingContent.length} characters');
          print('   📝 Response length: ${responseContent.length} characters');
        case core.ErrorEvent(:final error):
          print('\n   ❌ Stream error: $error');
        default:
          break;
      }
    }

    print('   ✅ Streaming thinking demonstration completed\n');
  } catch (error) {
    print('   ❌ Streaming thinking failed: $error\n');
  }
}

Future<void> demonstrateEthicalReasoning(String apiKey) async {
  print('⚖️  Ethical Reasoning:\n');

  try {
    final model = _createAnthropicModel(apiKey);
    const ethicalDilemma = '''
A self-driving car's AI must make a split-second decision:
- Straight ahead: Hit 3 elderly pedestrians who jaywalked
- Swerve left: Hit 1 child who is legally crossing
- Swerve right: Crash into a wall, likely killing the car's passenger

What should the AI decide? Consider multiple ethical frameworks
and show your reasoning process.
''';

    final response = await _generateThinkingText(
      model: model,
      prompt: [
        core.UserPromptMessage.text(ethicalDilemma),
      ],
      maxOutputTokens: 1500,
      thinkingBudgetTokens: 3072,
    );

    print('   Dilemma: Autonomous vehicle ethical decision making');

    final reasoning = response.reasoningText;
    if (reasoning != null && reasoning.isNotEmpty) {
      print('\n   🧠 Claude\'s Ethical Reasoning:');
      print('   ${'-' * 50}');
      final lines = reasoning.split('\n');
      final importantLines = <String>[];

      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('utilitarian') ||
            lowerLine.contains('deontological') ||
            lowerLine.contains('virtue') ||
            lowerLine.contains('framework') ||
            lowerLine.contains('consider')) {
          importantLines.add(line.trim());
        }
      }

      if (importantLines.isNotEmpty) {
        for (final line in importantLines.take(5)) {
          print('   $line');
        }
        if (importantLines.length > 5) {
          print(
            '   ... [${importantLines.length - 5} more ethical considerations]',
          );
        }
      } else {
        final previewLength = reasoning.length > 400 ? 400 : reasoning.length;
        print('   ${reasoning.substring(0, previewLength)}...');
      }
      print('   ${'-' * 50}');
    }

    print('\n   🎯 Ethical Analysis:');
    print('   ${response.text}');

    print('   ✅ Ethical reasoning demonstration completed\n');
  } catch (error) {
    print('   ❌ Ethical reasoning failed: $error\n');
  }
}

Future<void> demonstrateComparativeAnalysis(String apiKey) async {
  print('📊 Comparative Analysis:\n');

  try {
    final model = _createAnthropicModel(apiKey);
    const analysisTask = '''
Compare and contrast three programming paradigms:
1. Object-Oriented Programming (OOP)
2. Functional Programming (FP)
3. Procedural Programming

For each paradigm, analyze:
- Core principles and concepts
- Advantages and disadvantages
- Best use cases
- Popular languages that implement it

Provide a comprehensive comparison with examples.
''';

    final response = await _generateThinkingText(
      model: model,
      prompt: [
        core.UserPromptMessage.text(analysisTask),
      ],
      maxOutputTokens: 2000,
      thinkingBudgetTokens: 4096,
    );

    print('   Task: Programming paradigms comparative analysis');

    final reasoning = response.reasoningText;
    if (reasoning != null && reasoning.isNotEmpty) {
      print('\n   🧠 Claude\'s Analytical Process:');
      print('   ${'-' * 55}');

      final sections = reasoning.split('\n\n');
      final analyticalSections = <String>[];

      for (final section in sections) {
        final normalized = section.toLowerCase();
        if (normalized.contains('compare') ||
            normalized.contains('contrast') ||
            normalized.contains('analyze') ||
            normalized.contains('consider') ||
            normalized.contains('structure')) {
          analyticalSections.add(section.trim());
        }
      }

      if (analyticalSections.isNotEmpty) {
        for (final section in analyticalSections.take(3)) {
          final previewLength = section.length > 200 ? 200 : section.length;
          print('   ${section.substring(0, previewLength)}...');
          print('');
        }
        if (analyticalSections.length > 3) {
          print(
            '   ... [${analyticalSections.length - 3} more analytical sections]',
          );
        }
      } else {
        final previewLength = reasoning.length > 600 ? 600 : reasoning.length;
        print('   ${reasoning.substring(0, previewLength)}...');
      }
      print('   ${'-' * 55}');
    }

    print('\n   🎯 Comparative Analysis:');
    final analysisText = response.text;
    if (analysisText.length > 800) {
      print('   ${analysisText.substring(0, 800)}...');
      print(
        '   [Analysis continues for ${analysisText.length} total characters]',
      );
    } else {
      print('   $analysisText');
    }

    print('\n   💡 Analysis Quality Indicators:');
    final text = analysisText.toLowerCase();
    print(
      '      • Structured comparison: ${text.contains('compare') ? '✅' : '❌'}',
    );
    print(
      '      • Examples provided: ${text.contains('example') ? '✅' : '❌'}',
    );
    print(
      '      • Pros/cons analysis: ${text.contains('advantage') || text.contains('disadvantage') ? '✅' : '❌'}',
    );
    print(
      '      • Use cases covered: ${text.contains('use case') || text.contains('suitable') ? '✅' : '❌'}',
    );

    print('   ✅ Comparative analysis demonstration completed\n');
  } catch (error) {
    print('   ❌ Comparative analysis failed: $error\n');
  }
}

core.LanguageModel _createAnthropicModel(String apiKey) {
  return llm.AI.anthropic(
    apiKey: apiKey,
  ).chatModel('claude-sonnet-4-5');
}

Future<core.GenerateTextCallResult<Never>> _generateThinkingText({
  required core.LanguageModel model,
  required List<core.PromptMessage> prompt,
  required int maxOutputTokens,
  int thinkingBudgetTokens = 2048,
}) {
  return core.generateTextCall<Never>(
    model: model,
    prompt: prompt,
    options: core.GenerateTextOptions(
      maxOutputTokens: maxOutputTokens,
    ),
    callOptions: _thinkingCallOptions(
      thinkingBudgetTokens: thinkingBudgetTokens,
    ),
  );
}

core.CallOptions _thinkingCallOptions({
  required int thinkingBudgetTokens,
  bool interleavedThinking = false,
}) {
  return core.CallOptions(
    providerOptions: anthropic.AnthropicGenerateTextOptions(
      extendedThinking: true,
      thinkingBudgetTokens: thinkingBudgetTokens,
      interleavedThinking: interleavedThinking ? true : null,
    ),
  );
}

/// 🎯 Key Anthropic Thinking Concepts Summary:
///
/// Thinking Process Access:
/// - Real-time thinking observation via streaming
/// - Complete thinking process in non-streaming mode
/// - Transparent reasoning and decision making
/// - Step-by-step problem breakdown
///
/// Reasoning Capabilities:
/// - Complex mathematical calculations
/// - Logical puzzle solving
/// - Ethical dilemma analysis
/// - Comparative and analytical thinking
///
/// Best Practices:
/// - Allow sufficient token budget for thinking
/// - Stream thinking for real-time insight
/// - Analyze thinking process for quality assessment
/// - Keep extended-thinking controls provider owned
///
/// Unique Strengths:
/// - Transparent reasoning process
/// - Ethical consideration integration
/// - Structured analytical approach
/// - Self-reflection and verification
///
/// Configuration Tips:
/// - claude-sonnet-4-5: Good balance of thinking and performance
/// - Higher `thinkingBudgetTokens`: Allows deeper reasoning
/// - Higher `maxOutputTokens`: Allows a fuller final answer
/// - Interleaved thinking: Real-time reasoning observation
///
/// Next Steps:
/// - file_handling.dart: Document analysis with thinking
/// - mcp_connector.dart: Typed MCP server integration
/// - ../../03_advanced_features/reasoning_models.dart: Cross-provider comparison
