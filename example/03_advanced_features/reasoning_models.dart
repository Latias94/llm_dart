// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

/// 🧠 Reasoning Models - AI Thinking Processes
///
/// This example demonstrates how to use reasoning models that show their thinking:
/// - Understanding reasoning vs standard models
/// - Accessing AI thinking processes with DeepSeek R1
/// - Optimizing for complex problems
/// - Comparing different reasoning approaches
///
/// Before running, set your API key:
/// export DEEPSEEK_API_KEY="your-key"
/// export OPENAI_API_KEY="your-key"
/// export ANTHROPIC_API_KEY="your-key"
void main() async {
  print('🧠 Reasoning Models - AI Thinking Processes\n');

  registerDeepSeek();
  registerOpenAI();
  registerAnthropic();

  // Get API keys
  final deepseekKey = Platform.environment['DEEPSEEK_API_KEY'];
  final openaiKey = Platform.environment['OPENAI_API_KEY'];
  final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];

  if (deepseekKey == null || deepseekKey.isEmpty) {
    print('❌ Please set DEEPSEEK_API_KEY environment variable');
    return;
  }

  // Demonstrate different reasoning scenarios using DeepSeek
  await demonstrateBasicReasoning(deepseekKey);
  await demonstrateComplexProblemSolving(deepseekKey);
  await demonstrateStreamingReasoning(deepseekKey);
  await demonstrateReasoningComparison(deepseekKey, openaiKey, anthropicKey);
  await demonstrateThinkingProcessAnalysis(deepseekKey);

  print('\n✅ Reasoning models completed!');
}

/// Demonstrate basic reasoning capabilities with DeepSeek R1
Future<void> demonstrateBasicReasoning(String apiKey) async {
  print('🔍 Basic Reasoning with DeepSeek R1:\n');

  try {
    // Create DeepSeek reasoning model
    final reasoningProvider = await LLMBuilder()
        .provider(deepseekProviderId)
        .apiKey(apiKey)
        .model('deepseek-reasoner') // DeepSeek reasoning model
        .temperature(0.7)
        .maxTokens(2000)
        .timeout(const Duration(seconds: 300)) // Reasoning can take longer
        .build();

    final problem = '''
A farmer has chickens and rabbits. In total, there are 35 heads and 94 legs.
How many chickens and how many rabbits does the farmer have?
Show your reasoning step by step.
''';

    print('   Problem: $problem');

    final response = await generateText(
      model: reasoningProvider,
      messages: [ChatMessage.user(problem)],
    );

    print('   🤖 AI Response: ${response.text}');

    // Check if thinking process is available
    if (response.thinking != null && response.thinking!.isNotEmpty) {
      print(
          '\n   🧠 Thinking Process Available: ${response.thinking!.length} characters');
      print('   First 200 chars of thinking:');
      final thinkingPreview = response.thinking!.length > 200
          ? '${response.thinking!.substring(0, 200)}...'
          : response.thinking!;
      print('   \x1B[90m$thinkingPreview\x1B[0m'); // Gray color for thinking
    } else {
      print('\n   ℹ️  No thinking process available for this model');
    }

    print('   ✅ Basic reasoning successful\n');
  } catch (e, stackTrace) {
    print('   ❌ Basic reasoning failed!');
    print('   Error type: ${e.runtimeType}');
    print('   Error message: $e');
    if (e.toString().contains('API') || e.toString().contains('HTTP')) {
      print('   💡 Tip: Check your DEEPSEEK_API_KEY and network connection');
    }
    print(
        '   Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    print('');
  }
}

/// Demonstrate complex problem solving with DeepSeek R1
Future<void> demonstrateComplexProblemSolving(String apiKey) async {
  print('🧩 Complex Problem Solving with DeepSeek R1:\n');

  try {
    // Create DeepSeek reasoning model for complex problems
    final reasoningProvider = await LLMBuilder()
        .provider(deepseekProviderId)
        .apiKey(apiKey)
        .model('deepseek-reasoner')
        .temperature(0.8)
        .maxTokens(3000)
        .timeout(const Duration(seconds: 300)) // Reasoning can take longer
        .build();

    final complexProblem = '''
You are planning a dinner party for 8 people. You have the following constraints:
1. 2 people are vegetarian
2. 1 person is allergic to nuts
3. 1 person doesn't eat spicy food
4. Your budget is \$120
5. You want to serve 3 courses: appetizer, main, dessert

Plan a complete menu that satisfies all constraints and stays within budget.
Include estimated costs and explain your reasoning.
''';

    print(
        '   Complex Problem: Planning a dinner party with multiple constraints');

    final response = await generateText(
      model: reasoningProvider,
      messages: [ChatMessage.user(complexProblem)],
    );

    print('   🤖 AI Solution: ${response.text}');

    // Analyze the thinking process
    if (response.thinking != null && response.thinking!.isNotEmpty) {
      print('\n   🧠 Thinking Process Analysis:');
      final thinking = response.thinking!;
      print('      • Total thinking length: ${thinking.length} characters');
      print(
          '      • Estimated thinking time: ${(thinking.length / 100).round()} seconds');

      // Look for key reasoning patterns
      final patterns = [
        'constraint',
        'budget',
        'vegetarian',
        'allergic',
        'cost',
        'total',
      ];

      for (final pattern in patterns) {
        final count =
            RegExp(pattern, caseSensitive: false).allMatches(thinking).length;
        if (count > 0) {
          print('      • Mentions "$pattern": $count times');
        }
      }

      // Show a sample of the thinking process
      print('\n      • Sample thinking process:');
      final thinkingSample =
          thinking.length > 300 ? '${thinking.substring(0, 300)}...' : thinking;
      print('        \x1B[90m$thinkingSample\x1B[0m'); // Gray color
    }

    print('   ✅ Complex problem solving successful\n');
  } catch (e, stackTrace) {
    print('   ❌ Complex problem solving failed!');
    print('   Error type: ${e.runtimeType}');
    print('   Error message: $e');
    if (e.toString().contains('API') || e.toString().contains('HTTP')) {
      print('   💡 Tip: Check your DEEPSEEK_API_KEY and network connection');
    }
    print(
        '   Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    print('');
  }
}

/// Demonstrate streaming reasoning with real-time thinking process
Future<void> demonstrateStreamingReasoning(String apiKey) async {
  print('🌊 Streaming Reasoning with DeepSeek R1:');
  print('=' * 50);

  try {
    // Create DeepSeek reasoning model for streaming
    final reasoningProvider = await LLMBuilder()
        .provider(deepseekProviderId)
        .apiKey(apiKey)
        .model('deepseek-reasoner')
        .temperature(0.7)
        .maxTokens(2000)
        .build();

    final problem =
        'What is 15 + 27? Please show your calculation step by step.';

    print('Problem: $problem');
    print('🧠 Starting streaming reasoning with thinking support...\n');

    var thinkingContent = StringBuffer();
    var responseContent = StringBuffer();
    var isThinking = true;

    // Stream text and handle thinking + final answer parts
    await for (final part in streamText(
      model: reasoningProvider,
      promptIr: Prompt(messages: [PromptMessage.user(problem)]),
    )) {
      switch (part) {
        case ThinkingDeltaPart(delta: final delta):
          // Collect thinking/reasoning content
          thinkingContent.write(delta);
          stdout.write(
              '\x1B[90m$delta\x1B[0m'); // Gray color for thinking content, no newline
          break;
        case TextDeltaPart(delta: final delta):
          // This is the actual response after thinking
          if (isThinking) {
            print('\n\n   🎯 Final Answer:');
            isThinking = false;
          }
          responseContent.write(delta);
          stdout.write(delta); // No newline for continuous text
          break;
        case ToolCallDeltaPart(toolCall: final toolCall):
          // Handle tool call events (if supported)
          print('\n   [Tool Call: ${toolCall.function.name}]');
          break;
        case ProviderToolCallPart():
        case ProviderToolDeltaPart():
        case ProviderToolResultPart():
          // Ignore provider tool lifecycle for this demo.
          break;
        case SourceUrlPart():
        case SourceDocumentPart():
          // Ignore sources for this demo.
          break;
        case FinishPart(result: final result):
          print('\n\n✅ Streaming reasoning completed!');

          if (result.usage != null) {
            final usage = result.usage!;
            print(
              '\n📊 Usage: ${usage.promptTokens} prompt + ${usage.completionTokens} completion = ${usage.totalTokens} total tokens',
            );
          }
          break;
        case ErrorPart(error: final error):
          // Handle errors
          print('\n❌ Stream error: $error');
          break;
      }
    }

    // Summary
    print('\n📝 Streaming Summary:');
    print('Thinking content length: ${thinkingContent.length} characters');
    print('Response content length: ${responseContent.length} characters');
    print('✅ Streaming reasoning successful\n');
  } catch (e, stackTrace) {
    print('❌ Streaming reasoning failed!');
    print('Error type: ${e.runtimeType}');
    print('Error message: $e');
    print('Stack trace:');
    print(stackTrace);
    print('');
  }
}

/// Compare reasoning vs standard models
Future<void> demonstrateReasoningComparison(
    String deepseekKey, String? openaiKey, String? anthropicKey) async {
  print('⚖️  Reasoning vs Standard Model Comparison:\n');

  final mathProblem = '''
If a train travels at 60 mph for 2 hours, then 80 mph for 1.5 hours,
and finally 40 mph for 30 minutes, what is the total distance traveled?
''';

  print('   Math Problem: $mathProblem');

  // Test with DeepSeek reasoning model
  await testDeepSeekReasoningModel(deepseekKey, mathProblem);

  // Test with standard model (OpenAI)
  if (openaiKey != null && openaiKey.isNotEmpty) {
    await testStandardModel(openaiKey, mathProblem);
  } else {
    print('\n   ⚠️  Skipped OpenAI comparison: set OPENAI_API_KEY');
  }

  // Test with Anthropic (which has built-in reasoning)
  if (anthropicKey != null && anthropicKey.isNotEmpty) {
    await testAnthropicModel(anthropicKey, mathProblem);
  } else {
    print('\n   ⚠️  Skipped Anthropic comparison: set ANTHROPIC_API_KEY');
  }

  print('   💡 Comparison Insights:');
  print('      • DeepSeek R1: Shows detailed thinking process');
  print('      • Standard models: Fast, direct answers');
  print('      • Anthropic: Good balance of speed and reasoning');
  print('   ✅ Model comparison completed\n');
}

/// Test DeepSeek reasoning model
Future<void> testDeepSeekReasoningModel(String apiKey, String problem) async {
  try {
    final reasoningProvider = await LLMBuilder()
        .provider(deepseekProviderId)
        .apiKey(apiKey)
        .model('deepseek-r1') // DeepSeek reasoning model
        .temperature(0.7)
        .build();

    final stopwatch = Stopwatch()..start();
    final response = await generateText(
      model: reasoningProvider,
      messages: [ChatMessage.user(problem)],
    );
    stopwatch.stop();

    print('\n   🧠 DeepSeek Reasoning Model (deepseek-r1):');
    print('      Response time: ${stopwatch.elapsedMilliseconds}ms');
    print('      Answer: ${response.text}');

    if (response.thinking != null && response.thinking!.isNotEmpty) {
      print('      Thinking process: ${response.thinking!.length} chars');
      print(
          '      Sample thinking: \x1B[90m${response.thinking!.substring(0, response.thinking!.length > 100 ? 100 : response.thinking!.length)}...\x1B[0m');
    }
  } catch (e, stackTrace) {
    print('\n   ❌ DeepSeek reasoning model test failed!');
    print('   Error type: ${e.runtimeType}');
    print('   Error message: $e');
    print(
        '   Stack trace: ${stackTrace.toString().split('\n').take(2).join('\n')}');
  }
}

/// Test standard model
Future<void> testStandardModel(String apiKey, String problem) async {
  try {
    final standardProvider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o-mini') // Standard model
        .temperature(0.3)
        .build();

    final stopwatch = Stopwatch()..start();
    final response = await generateText(
      model: standardProvider,
      messages: [ChatMessage.user(problem)],
    );
    stopwatch.stop();

    print('\n   📊 Standard Model (gpt-4o-mini):');
    print('      Response time: ${stopwatch.elapsedMilliseconds}ms');
    print('      Answer: ${response.text}');
  } catch (e) {
    print('\n   ❌ Standard model test failed!');
    print('   Error type: ${e.runtimeType}');
    print('   Error message: $e');
    if (e.toString().contains('API') || e.toString().contains('HTTP')) {
      print('   💡 Tip: Check your OPENAI_API_KEY and network connection');
    }
  }
}

/// Test Anthropic model
Future<void> testAnthropicModel(String apiKey, String problem) async {
  try {
    final anthropicProvider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-3-5-haiku-20241022')
        .temperature(0.3)
        .build();

    final stopwatch = Stopwatch()..start();
    final response = await generateText(
      model: anthropicProvider,
      messages: [ChatMessage.user(problem)],
    );
    stopwatch.stop();

    print('\n   🎭 Anthropic Model (Claude):');
    print('      Response time: ${stopwatch.elapsedMilliseconds}ms');
    print('      Answer: ${response.text}');
  } catch (e) {
    print('\n   ❌ Anthropic model test failed!');
    print('   Error type: ${e.runtimeType}');
    print('   Error message: $e');
    if (e.toString().contains('API') || e.toString().contains('HTTP')) {
      print('   💡 Tip: Check your ANTHROPIC_API_KEY and network connection');
    }
  }
}

/// Demonstrate thinking process analysis with DeepSeek
Future<void> demonstrateThinkingProcessAnalysis(String apiKey) async {
  print('🔬 Thinking Process Analysis with DeepSeek R1:\n');

  try {
    final deepseekProvider = await LLMBuilder()
        .provider(deepseekProviderId)
        .apiKey(apiKey)
        .model('deepseek-r1')
        .temperature(0.7)
        .maxTokens(3000)
        .build();

    final analyticalProblem = '''
Analyze the following business scenario and provide recommendations:

A small coffee shop has been losing customers over the past 6 months.
- Revenue down 30%
- Customer complaints about slow service
- New competitor opened nearby
- Staff turnover increased
- Equipment is 5 years old

What are the top 3 priorities to address, and why?
''';

    print('   Business Problem: Coffee shop losing customers');

    final response = await generateText(
      model: deepseekProvider,
      messages: [ChatMessage.user(analyticalProblem)],
    );

    print('   🤖 AI Analysis: ${response.text}');

    // Analyze response structure
    final responseText = response.text ?? '';
    print('\n   📈 Response Analysis:');
    print('      • Response length: ${responseText.length} characters');
    print('      • Number of paragraphs: ${responseText.split('\n\n').length}');
    print(
        '      • Contains numbered list: ${responseText.contains(RegExp(r'\d+\.'))}');
    print(
        '      • Mentions priorities: ${responseText.toLowerCase().contains('priority')}');

    // Look for structured thinking
    final structureIndicators = [
      'first',
      'second',
      'third',
      'priority',
      'important',
      'critical',
      'because',
      'therefore',
      'however',
      'recommendation',
      'suggest',
      'should'
    ];

    var structureScore = 0;
    for (final indicator in structureIndicators) {
      if (responseText.toLowerCase().contains(indicator)) {
        structureScore++;
      }
    }

    print(
        '      • Structure score: $structureScore/${structureIndicators.length}');
    print(
        '      • Well-structured response: ${structureScore > 5 ? 'Yes' : 'No'}');

    print('   ✅ Thinking process analysis completed\n');
  } catch (e, stackTrace) {
    print('   ❌ Thinking process analysis failed!');
    print('   Error type: ${e.runtimeType}');
    print('   Error message: $e');
    if (e.toString().contains('API') || e.toString().contains('HTTP')) {
      print('   💡 Tip: Check your DEEPSEEK_API_KEY and network connection');
    }
    print(
        '   Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    print('');
  }
}

/// 🎯 Key Reasoning Concepts Summary:
///
/// Reasoning Models:
/// - deepseek-r1: DeepSeek's reasoning model with visible thinking process
/// - o1-mini/o1-preview: OpenAI reasoning models (thinking not visible)
/// - Claude: Built-in reasoning capabilities
///
/// DeepSeek R1 Advantages:
/// - Shows complete thinking process
/// - Excellent for learning and debugging
/// - Strong mathematical reasoning
/// - Transparent problem-solving steps
///
/// When to Use Reasoning:
/// - Complex multi-step problems
/// - Mathematical calculations
/// - Logical puzzles
/// - Planning and analysis
/// - Code debugging
/// - Learning from AI reasoning
///
/// Thinking Process Features:
/// - Internal reasoning steps visible
/// - Problem decomposition shown
/// - Verification and checking exposed
/// - Alternative approaches considered
/// - Real-time streaming of thoughts
///
/// Best Practices:
/// 1. Use DeepSeek R1 when you need to see thinking
/// 2. Allow extra time for reasoning
/// 3. Analyze thinking process for insights
/// 4. Compare with standard models
/// 5. Use streaming for real-time thinking
/// 6. Consider cost vs transparency trade-offs
///
/// Performance Characteristics:
/// - Slower response times
/// - Higher accuracy on complex tasks
/// - Visible thinking process
/// - Better at self-correction
/// - Great for educational purposes
///
/// Next Steps:
/// - multi_modal.dart: Image and audio processing
/// - custom_providers.dart: Build custom AI providers
/// - performance_optimization.dart: Speed and efficiency
