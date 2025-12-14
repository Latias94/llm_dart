// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

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

  // Get API keys
  final deepseekKey = Platform.environment['DEEPSEEK_API_KEY'] ?? 'sk-TESTKEY';
  final openaiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';
  final anthropicKey =
      Platform.environment['ANTHROPIC_API_KEY'] ?? 'sk-ant-TESTKEY';

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
    // Create DeepSeek reasoning model (prompt-first LanguageModel)
    final reasoningModel = await ai()
        .deepseek()
        .apiKey(apiKey)
        .model('deepseek-reasoner') // DeepSeek reasoning model
        .temperature(0.7)
        .maxTokens(2000)
        .timeout(const Duration(seconds: 300)) // Reasoning can take longer
        .buildLanguageModel();

    final problem = '''
A farmer has chickens and rabbits. In total, there are 35 heads and 94 legs.
How many chickens and how many rabbits does the farmer have?
Show your reasoning step by step.
''';

    print('   Problem: $problem');

    final messages = <ModelMessage>[
      ModelMessage.userText(problem),
    ];

    final result = await generateTextPromptWithModel(
      reasoningModel,
      messages: messages,
    );

    print('   🤖 AI Response: ${result.text}');

    // Check if thinking process is available
    if (result.thinking != null && result.thinking!.isNotEmpty) {
      print(
          '\n   🧠 Thinking Process Available: ${result.thinking!.length} characters');
      print('   First 200 chars of thinking:');
      final thinkingPreview = result.thinking!.length > 200
          ? '${result.thinking!.substring(0, 200)}...'
          : result.thinking!;
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
    // Create DeepSeek reasoning model for complex problems (LanguageModel)
    final reasoningModel = await ai()
        .deepseek()
        .apiKey(apiKey)
        .model('deepseek-reasoner')
        .temperature(0.8)
        .maxTokens(3000)
        .timeout(const Duration(seconds: 300)) // Reasoning can take longer
        .buildLanguageModel();

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

    final messages = <ModelMessage>[
      ModelMessage.userText(complexProblem),
    ];

    final result = await generateTextPromptWithModel(
      reasoningModel,
      messages: messages,
    );

    print('   🤖 AI Solution: ${result.text}');

    // Analyze the thinking process
    if (result.thinking != null && result.thinking!.isNotEmpty) {
      print('\n   🧠 Thinking Process Analysis:');
      final thinking = result.thinking!;
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
    // Create DeepSeek reasoning model for streaming (LanguageModel)
    final reasoningModel = await ai()
        .deepseek()
        .apiKey(apiKey)
        .model('deepseek-reasoner')
        .temperature(0.7)
        .maxTokens(2000)
        .buildLanguageModel();

    final problem =
        'What is 15 + 27? Please show your calculation step by step.';

    print('Problem: $problem');
    print('🧠 Starting streaming reasoning with thinking support...\n');

    var thinkingContent = StringBuffer();
    var responseContent = StringBuffer();
    var isThinking = true;

    // Send streaming request via prompt-first helper and handle events
    final messages = <ModelMessage>[
      ModelMessage.userText(problem),
    ];

    await for (final event in streamTextWithModel(
      reasoningModel,
      promptMessages: messages,
    )) {
      switch (event) {
        case ThinkingDeltaEvent(delta: final delta):
          // Collect thinking/reasoning content
          thinkingContent.write(delta);
          stdout.write(
              '\x1B[90m$delta\x1B[0m'); // Gray color for thinking content, no newline
          break;
        case TextDeltaEvent(delta: final delta):
          // This is the actual response after thinking
          if (isThinking) {
            print('\n\n   🎯 Final Answer:');
            isThinking = false;
          }
          responseContent.write(delta);
          stdout.write(delta); // No newline for continuous text
          break;
        case ToolCallDeltaEvent(toolCall: final toolCall):
          // Handle tool call events (if supported)
          print('\n   [Tool Call: ${toolCall.function.name}]');
          break;
        case CompletionEvent(response: final response):
          // Handle completion
          print('\n\n✅ Streaming reasoning completed!');

          if (response.usage != null) {
            final usage = response.usage!;
            print(
              '\n📊 Usage: ${usage.promptTokens} prompt + ${usage.completionTokens} completion = ${usage.totalTokens} total tokens',
            );
          }
          break;
        case ErrorEvent(error: final error):
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
    String deepseekKey, String openaiKey, String anthropicKey) async {
  print('⚖️  Reasoning vs Standard Model Comparison:\n');

  final mathProblem = '''
If a train travels at 60 mph for 2 hours, then 80 mph for 1.5 hours,
and finally 40 mph for 30 minutes, what is the total distance traveled?
''';

  print('   Math Problem: $mathProblem');

  // Test with DeepSeek reasoning model
  await testDeepSeekReasoningModel(deepseekKey, mathProblem);

  // Test with standard model (OpenAI)
  await testStandardModel(openaiKey, mathProblem);

  // Test with Anthropic (which has built-in reasoning)
  await testAnthropicModel(anthropicKey, mathProblem);

  print('   💡 Comparison Insights:');
  print('      • DeepSeek R1: Shows detailed thinking process');
  print('      • Standard models: Fast, direct answers');
  print('      • Anthropic: Good balance of speed and reasoning');
  print('   ✅ Model comparison completed\n');
}

/// Test DeepSeek reasoning model
Future<void> testDeepSeekReasoningModel(String apiKey, String problem) async {
  try {
    final reasoningModel = await ai()
        .deepseek()
        .apiKey(apiKey)
        .model('deepseek-r1') // DeepSeek reasoning model
        .temperature(0.7)
        .buildLanguageModel();

    final stopwatch = Stopwatch()..start();
    final result = await generateTextPromptWithModel(
      reasoningModel,
      messages: [
        ModelMessage.userText(problem),
      ],
    );
    stopwatch.stop();

    print('\n   🧠 DeepSeek Reasoning Model (deepseek-r1):');
    print('      Response time: ${stopwatch.elapsedMilliseconds}ms');
    print('      Answer: ${result.text}');

    if (result.thinking != null && result.thinking!.isNotEmpty) {
      print('      Thinking process: ${result.thinking!.length} chars');
      final sample = result.thinking!;
      print(
          '      Sample thinking: \x1B[90m${sample.substring(0, sample.length > 100 ? 100 : sample.length)}...\x1B[0m');
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
    final standardModel = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini') // Standard model
        .temperature(0.3)
        .buildLanguageModel();

    final stopwatch = Stopwatch()..start();
    final result = await generateTextPromptWithModel(
      standardModel,
      messages: [
        ModelMessage.userText(problem),
      ],
    );
    stopwatch.stop();

    print('\n   📊 Standard Model (gpt-4o-mini):');
    print('      Response time: ${stopwatch.elapsedMilliseconds}ms');
    print('      Answer: ${result.text}');
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
    final anthropicModel = await ai()
        .anthropic()
        .apiKey(apiKey)
        .model('claude-3-5-haiku-20241022')
        .temperature(0.3)
        .buildLanguageModel();

    final stopwatch = Stopwatch()..start();
    final result = await generateTextPromptWithModel(
      anthropicModel,
      messages: [
        ModelMessage.userText(problem),
      ],
    );
    stopwatch.stop();

    print('\n   🎭 Anthropic Model (Claude):');
    print('      Response time: ${stopwatch.elapsedMilliseconds}ms');
    print('      Answer: ${result.text}');
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
    final deepseekModel = await ai()
        .deepseek()
        .apiKey(apiKey)
        .model('deepseek-r1')
        .temperature(0.7)
        .maxTokens(3000)
        .buildLanguageModel();

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

    final result = await generateTextPromptWithModel(
      deepseekModel,
      messages: [
        ModelMessage.userText(analyticalProblem),
      ],
    );

    print('   🤖 AI Analysis: ${result.text}');

    // Analyze response structure
    final responseText = result.text ?? '';
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
