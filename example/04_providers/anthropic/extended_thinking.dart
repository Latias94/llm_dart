// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';

/// 🟣 Anthropic Extended Thinking - Access Claude's Reasoning Process
///
/// This example demonstrates Claude's advanced thinking capabilities:
/// - Accessing the thinking process
/// - Step-by-step reasoning
/// - Complex problem solving
/// - Transparent decision making
///
/// Before running, set your API key:
/// export ANTHROPIC_API_KEY="your-anthropic-api-key"
void main() async {
  print('🟣 Anthropic Extended Thinking - Claude\'s Reasoning Process\n');

  // Get API key
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set ANTHROPIC_API_KEY environment variable');
    exit(1);
  }

  registerAnthropic();

  // Demonstrate Claude's thinking capabilities
  await demonstrateBasicThinking(apiKey);
  await demonstrateComplexReasoning(apiKey);
  await demonstrateStreamingThinking(apiKey);
  await demonstrateEthicalReasoning(apiKey);
  await demonstrateComparativeAnalysis(apiKey);

  print('\n✅ Anthropic extended thinking completed!');
}

/// Demonstrate basic thinking process
Future<void> demonstrateBasicThinking(String apiKey) async {
  print('🧠 Basic Thinking Process:\n');

  try {
    // Use Claude Sonnet 4 for thinking capabilities
    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.3) // Lower for more focused thinking
        .maxTokens(1500)
        .providerOptions(anthropicProviderId, const {
      'reasoning': true,
      'interleavedThinking': true,
      'thinkingBudgetTokens': 1024,
    }).build();

    final result = await generateText(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user('''
I have a 3-gallon jug and a 5-gallon jug. I need to measure exactly 4 gallons of water.
How can I do this? Please show your thinking process step by step.
'''),
        ],
      ),
    );

    print(
        '   Problem: Water jug puzzle (3-gallon and 5-gallon jugs, measure 4 gallons)');
    print('   Model: claude-sonnet-4-20250514');

    // Show the thinking process if available
    if (result.thinking != null && result.thinking!.isNotEmpty) {
      print('\n   🧠 Claude\'s Thinking Process:');
      print('   ${'-' * 50}');
      print('   ${result.thinking}');
      print('   ${'-' * 50}');
    }

    print('\n   🎯 Final Answer:');
    print('   ${result.text}');

    if (result.usage?.totalTokens != null) {
      print('\n   📊 Usage: ${result.usage!.totalTokens} tokens');
    }

    print('   ✅ Basic thinking demonstration completed\n');
  } catch (e) {
    print('   ❌ Basic thinking failed: $e\n');
  }
}

/// Demonstrate complex reasoning
Future<void> demonstrateComplexReasoning(String apiKey) async {
  print('🔬 Complex Reasoning:\n');

  try {
    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.2) // Even lower for analytical tasks
        .maxTokens(2000)
        .providerOptions(anthropicProviderId, const {
      'reasoning': true,
      'interleavedThinking': true,
      'thinkingBudgetTokens': 1536,
    }).build();

    final complexProblem = '''
A company is considering two investment options:

Option A: Invest \$100,000 now, receive \$15,000 per year for 10 years
Option B: Invest \$80,000 now, receive \$12,000 per year for 8 years,
         then receive a lump sum of \$50,000 at the end

Assuming a discount rate of 8%, which option is better?
Please show all calculations and reasoning.
''';

    final result = await generateText(
      model: provider,
      promptIr: Prompt(messages: [PromptMessage.user(complexProblem)]),
    );

    print('   Problem: Investment analysis with NPV calculations');

    if (result.thinking != null && result.thinking!.isNotEmpty) {
      print('\n   🧠 Claude\'s Analytical Process:');
      print('   ${'-' * 60}');
      // Show first part of thinking to avoid too much output
      final thinking = result.thinking!;
      if (thinking.length > 500) {
        print('   ${thinking.substring(0, 500)}...');
        print(
            '   [Thinking process continues for ${thinking.length} total characters]');
      } else {
        print('   $thinking');
      }
      print('   ${'-' * 60}');
    }

    print('\n   🎯 Final Analysis:');
    print('   ${result.text}');

    print('   ✅ Complex reasoning demonstration completed\n');
  } catch (e) {
    print('   ❌ Complex reasoning failed: $e\n');
  }
}

/// Demonstrate streaming thinking
Future<void> demonstrateStreamingThinking(String apiKey) async {
  print('🌊 Streaming Thinking Process:\n');

  try {
    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.4)
        .maxTokens(1500)
        .providerOptions(anthropicProviderId, const {
      'reasoning': true,
      'interleavedThinking': true,
      'thinkingBudgetTokens': 1024,
    }).build();

    print('   Problem: Logic puzzle with real-time thinking');
    print('   Watching Claude think in real-time...\n');

    var thinkingContent = StringBuffer();
    var responseContent = StringBuffer();
    var isThinking = true;

    await for (final part in streamChatParts(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user('''
Five friends (Alice, Bob, Carol, David, Eve) are sitting in a row.
- Alice is not at either end
- Bob is somewhere to the left of Carol
- David is next to Eve
- Carol is not next to Alice

What is the seating arrangement? Show your reasoning.
'''),
        ],
      ),
    )) {
      switch (part) {
        case LLMReasoningDeltaPart(delta: final delta):
          thinkingContent.write(delta);
          // Print thinking in gray color
          stdout.write('\x1B[90m$delta\x1B[0m');
          break;
        case LLMTextDeltaPart(delta: final delta):
          if (isThinking) {
            print('\n\n   🎯 Claude\'s Final Answer:');
            print('   ${'-' * 40}');
            isThinking = false;
          }
          responseContent.write(delta);
          stdout.write(delta);
          break;
        case LLMFinishPart(response: final response):
          print('\n   ${'-' * 40}');
          print('\n   ✅ Streaming thinking completed!');

          final usage = response.usage;
          if (usage?.totalTokens != null) {
            print('   📊 Usage: ${usage!.totalTokens} tokens');
          }

          print('   🧠 Thinking length: ${thinkingContent.length} characters');
          print('   📝 Response length: ${responseContent.length} characters');
          break;
        case LLMErrorPart(error: final error):
          print('\n   ❌ Stream error: $error');
          break;
        default:
          break;
      }
    }

    print('   ✅ Streaming thinking demonstration completed\n');
  } catch (e) {
    print('   ❌ Streaming thinking failed: $e\n');
  }
}

/// Demonstrate ethical reasoning
Future<void> demonstrateEthicalReasoning(String apiKey) async {
  print('⚖️  Ethical Reasoning:\n');

  try {
    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.3)
        .maxTokens(1500)
        .providerOptions(anthropicProviderId, const {
      'reasoning': true,
      'interleavedThinking': true,
      'thinkingBudgetTokens': 1024,
    }).build();

    final ethicalDilemma = '''
A self-driving car's AI must make a split-second decision:
- Straight ahead: Hit 3 elderly pedestrians who jaywalked
- Swerve left: Hit 1 child who is legally crossing
- Swerve right: Crash into a wall, likely killing the car's passenger

What should the AI decide? Consider multiple ethical frameworks
and show your reasoning process.
''';

    final result = await generateText(
      model: provider,
      promptIr: Prompt(messages: [PromptMessage.user(ethicalDilemma)]),
    );

    print('   Dilemma: Autonomous vehicle ethical decision making');

    if (result.thinking != null && result.thinking!.isNotEmpty) {
      print('\n   🧠 Claude\'s Ethical Reasoning:');
      print('   ${'-' * 50}');
      // Show key parts of ethical thinking
      final thinking = result.thinking!;
      final lines = thinking.split('\n');
      var importantLines = <String>[];

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
              '   ... [${importantLines.length - 5} more ethical considerations]');
        }
      } else {
        print('   ${thinking.substring(0, 400)}...');
      }
      print('   ${'-' * 50}');
    }

    print('\n   🎯 Ethical Analysis:');
    print('   ${result.text}');

    print('   ✅ Ethical reasoning demonstration completed\n');
  } catch (e) {
    print('   ❌ Ethical reasoning failed: $e\n');
  }
}

/// Demonstrate comparative analysis
Future<void> demonstrateComparativeAnalysis(String apiKey) async {
  print('📊 Comparative Analysis:\n');

  try {
    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.3)
        .maxTokens(2000)
        .providerOptions(anthropicProviderId, const {
      'reasoning': true,
      'interleavedThinking': true,
      'thinkingBudgetTokens': 1536,
    }).build();

    final analysisTask = '''
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

    final result = await generateText(
      model: provider,
      promptIr: Prompt(messages: [PromptMessage.user(analysisTask)]),
    );

    print('   Task: Programming paradigms comparative analysis');

    if (result.thinking != null && result.thinking!.isNotEmpty) {
      print('\n   🧠 Claude\'s Analytical Process:');
      print('   ${'-' * 55}');

      // Extract key analytical points
      final thinking = result.thinking!;
      final sections = thinking.split('\n\n');
      var analyticalSections = <String>[];

      for (final section in sections) {
        if (section.toLowerCase().contains('compare') ||
            section.toLowerCase().contains('contrast') ||
            section.toLowerCase().contains('analyze') ||
            section.toLowerCase().contains('consider') ||
            section.toLowerCase().contains('structure')) {
          analyticalSections.add(section.trim());
        }
      }

      if (analyticalSections.isNotEmpty) {
        for (final section in analyticalSections.take(3)) {
          print(
              '   ${section.substring(0, section.length > 200 ? 200 : section.length)}...');
          print('');
        }
        if (analyticalSections.length > 3) {
          print(
              '   ... [${analyticalSections.length - 3} more analytical sections]');
        }
      } else {
        print('   ${thinking.substring(0, 600)}...');
      }
      print('   ${'-' * 55}');
    }

    print('\n   🎯 Comparative Analysis:');
    // Show first part of the analysis
    final analysisText = result.text ?? '';
    if (analysisText.length > 800) {
      print('   ${analysisText.substring(0, 800)}...');
      print(
          '   [Analysis continues for ${analysisText.length} total characters]');
    } else {
      print('   $analysisText');
    }

    print('\n   💡 Analysis Quality Indicators:');
    final text = result.text?.toLowerCase() ?? '';
    print(
        '      • Structured comparison: ${text.contains('compare') ? '✅' : '❌'}');
    print('      • Examples provided: ${text.contains('example') ? '✅' : '❌'}');
    print(
        '      • Pros/cons analysis: ${text.contains('advantage') || text.contains('disadvantage') ? '✅' : '❌'}');
    print(
        '      • Use cases covered: ${text.contains('use case') || text.contains('suitable') ? '✅' : '❌'}');

    print('   ✅ Comparative analysis demonstration completed\n');
  } catch (e) {
    print('   ❌ Comparative analysis failed: $e\n');
  }
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
/// - Use lower temperature (0.2-0.4) for analytical tasks
/// - Allow sufficient token budget for thinking
/// - Stream thinking for real-time insight
/// - Analyze thinking process for quality assessment
///
/// Unique Strengths:
/// - Transparent reasoning process
/// - Ethical consideration integration
/// - Structured analytical approach
/// - Self-reflection and verification
///
/// Configuration Tips:
/// - claude-3-5-sonnet: Best balance of thinking and performance
/// - Lower temperature: More focused reasoning
/// - Higher max_tokens: Allow complete thinking process
/// - Streaming: Real-time thinking observation
///
/// Next Steps:
/// - file_handling.dart: Document analysis with thinking
/// - vision_capabilities.dart: Visual reasoning process
/// - ../../03_advanced_features/reasoning_models.dart: Cross-provider comparison
