// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/xai.dart' as xai;

/// 🚀 X.AI Grok Integration - Real-Time AI with Personality
///
/// This example demonstrates xAI's Grok model capabilities through the stable
/// `xai(...).chatModel(...)` facade.
///
/// Before running, set your API key:
/// export XAI_API_KEY="your-xai-api-key"
Future<void> main() async {
  print('🚀 X.AI Grok Integration - Real-Time AI with Personality\n');

  final apiKey = Platform.environment['XAI_API_KEY'] ?? 'xai-TESTKEY';

  await demonstrateBasicGrok(apiKey);
  await demonstratePersonalityFeatures(apiKey);
  await demonstrateRealTimeInformation(apiKey);
  await demonstrateConversationalStyle(apiKey);
  await demonstrateBestPractices(apiKey);

  print('\n✅ X.AI Grok integration completed!');
}

Future<void> demonstrateBasicGrok(String apiKey) async {
  print('🤖 Basic Grok Functionality:\n');

  try {
    final model = _createGrokModel(apiKey);

    print('   Basic Conversation:');
    var response = await _generateText(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Hello Grok! Tell me something interesting about AI.',
        ),
      ],
      temperature: 0.7,
      maxOutputTokens: 500,
    );
    print('      User: Hello Grok! Tell me something interesting about AI.');
    print('      Grok: ${response.text}\n');

    print('   With System Prompt:');
    response = await _generateText(
      model: model,
      prompt: [
        core.SystemPromptMessage.text(
          'You are Grok, a witty AI assistant with a sense of humor.',
        ),
        core.UserPromptMessage.text(
          'Explain quantum computing like I\'m 5 years old.',
        ),
      ],
      temperature: 0.7,
      maxOutputTokens: 500,
    );
    print('      System: You are Grok, a witty AI assistant...');
    print('      User: Explain quantum computing like I\'m 5 years old.');
    print('      Grok: ${response.text}');

    if (response.usage != null) {
      print('\n      📊 Usage: ${response.usage!.totalTokens} tokens');
    }

    print('   ✅ Basic Grok demonstration completed\n');
  } catch (error) {
    print('   ❌ Basic Grok failed: $error\n');
  }
}

Future<void> demonstratePersonalityFeatures(String apiKey) async {
  print('😄 Personality Features:\n');

  try {
    final model = _createGrokModel(apiKey);
    final personalityTests = [
      'Tell me a joke about programming.',
      'What do you think about the meaning of life?',
      'Explain why cats are better than dogs (or vice versa).',
      'What would you do if you were human for a day?',
    ];

    for (final test in personalityTests) {
      print('   Testing: $test');

      final response = await _generateText(
        model: model,
        prompt: [
          core.SystemPromptMessage.text(
            'Be witty, engaging, and show your personality. '
            'Do not be afraid to be humorous or opinionated.',
          ),
          core.UserPromptMessage.text(test),
        ],
        temperature: 0.8,
        maxOutputTokens: 400,
      );

      print('      Grok: ${response.text}\n');
    }

    print('   💡 Personality Highlights:');
    print('      • Witty and humorous responses');
    print('      • Engaging conversational style');
    print('      • Not afraid to express opinions');
    print('      • Balances humor with helpfulness');
    print('   ✅ Personality features demonstration completed\n');
  } catch (error) {
    print('   ❌ Personality features failed: $error\n');
  }
}

Future<void> demonstrateRealTimeInformation(String apiKey) async {
  print('🌐 Real-Time Information:\n');

  try {
    final model = _createGrokModel(apiKey);
    final realTimeQueries = [
      'What are the latest developments in AI this week?',
      'Tell me about recent tech news.',
      'What\'s happening in the world of cryptocurrency today?',
      'Any recent breakthroughs in space exploration?',
    ];

    for (final query in realTimeQueries) {
      print('   Query: $query');

      final response = await _generateText(
        model: model,
        prompt: [
          core.SystemPromptMessage.text(
            'Provide current, up-to-date information and cite the most '
            'relevant live findings when available.',
          ),
          core.UserPromptMessage.text(query),
        ],
        temperature: 0.3,
        maxOutputTokens: 600,
        callOptions: const core.CallOptions(
          providerOptions: xai.XAIGenerateTextOptions(
            search: xai.XAILiveSearchOptions.autoWeb(
              maxSearchResults: 5,
            ),
          ),
        ),
      );

      print('      Grok: ${response.text}\n');
    }

    print('   💡 Real-Time Features:');
    print('      • Access to current information');
    print('      • Recent news and developments');
    print('      • Current events awareness');
    print('      • Typed live-search controls');
    print('   ✅ Real-time information demonstration completed\n');
  } catch (error) {
    print('   ❌ Real-time information failed: $error\n');
  }
}

Future<void> demonstrateConversationalStyle(String apiKey) async {
  print('💬 Conversational Style:\n');

  try {
    final model = _createGrokModel(apiKey);

    print('   Multi-turn Conversation:');
    final conversation = <core.PromptMessage>[
      core.SystemPromptMessage.text(
        'You are Grok. Be conversational, witty, and remember the context of our chat.',
      ),
      core.UserPromptMessage.text(
        'I\'m thinking about learning to code. Any advice?',
      ),
    ];

    var response = await _generateText(
      model: model,
      prompt: conversation,
      temperature: 0.7,
      maxOutputTokens: 400,
    );
    print('      User: I\'m thinking about learning to code. Any advice?');
    print('      Grok: ${response.text}\n');

    conversation.add(core.AssistantPromptMessage.text(response.text));
    conversation.add(
      core.UserPromptMessage.text(
        'I\'m particularly interested in AI and machine learning.',
      ),
    );

    response = await _generateText(
      model: model,
      prompt: conversation,
      temperature: 0.7,
      maxOutputTokens: 400,
    );
    print(
      '      User: I\'m particularly interested in AI and machine learning.',
    );
    print('      Grok: ${response.text}\n');

    conversation.add(core.AssistantPromptMessage.text(response.text));
    conversation.add(
      core.UserPromptMessage.text(
        'What programming language should I start with?',
      ),
    );

    response = await _generateText(
      model: model,
      prompt: conversation,
      temperature: 0.7,
      maxOutputTokens: 400,
    );
    print('      User: What programming language should I start with?');
    print('      Grok: ${response.text}');

    print('\n   💡 Conversational Strengths:');
    print('      • Maintains context across turns');
    print('      • Natural, flowing dialogue');
    print('      • Builds on previous responses');
    print('      • Engaging and helpful');
    print('   ✅ Conversational style demonstration completed\n');
  } catch (error) {
    print('   ❌ Conversational style failed: $error\n');
  }
}

Future<void> demonstrateBestPractices(String apiKey) async {
  print('🏆 Best Practices:\n');

  print('   Error Handling:');
  try {
    final invalidModel = _createGrokModel('invalid-key');
    await _generateText(
      model: invalidModel,
      prompt: [
        core.UserPromptMessage.text('Test'),
      ],
      maxOutputTokens: 64,
    );
  } catch (error) {
    print('      ✅ Properly surfaced provider error: $error');
  }

  print('\n   Optimal Configuration:');
  try {
    final model = _createGrokModel(apiKey);
    final response = await _generateText(
      model: model,
      prompt: [
        core.SystemPromptMessage.text(
          'You are Grok, a helpful and witty AI assistant.',
        ),
        core.UserPromptMessage.text(
          'Give me a creative solution to reduce plastic waste.',
        ),
      ],
      temperature: 0.7,
      maxOutputTokens: 500,
      callOptions: const core.CallOptions(
        timeout: Duration(seconds: 30),
      ),
    );

    final preview = response.text.length > 150
        ? '${response.text.substring(0, 150)}...'
        : response.text;
    print('      ✅ Optimized response: $preview');
  } catch (error) {
    print('      ❌ Optimization error: $error');
  }

  print('\n   Streaming for Better UX:');
  try {
    final model = _createGrokModel(apiKey);
    print('      Question: Write a short poem about technology.');
    print('      Grok (streaming): ');

    final stream = core.streamTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Write a short poem about technology.'),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.7,
        maxOutputTokens: 240,
      ),
    );

    await for (final event in stream) {
      switch (event) {
        case core.TextDeltaEvent(:final delta):
          stdout.write(delta);
        case core.FinishEvent():
          print('\n      ✅ Streaming completed');
        case core.ErrorEvent(:final error):
          print('\n      ❌ Stream error: $error');
        default:
          break;
      }
    }
  } catch (error) {
    print('      ❌ Streaming error: $error');
  }

  print('\n   💡 Best Practices Summary:');
  print('      • Use appropriate temperature for task type');
  print('      • Use typed live-search options for current-events queries');
  print('      • Implement streaming for better user experience');
  print('      • Handle provider errors gracefully');
  print('      • Use system prompts to guide personality');
  print('   ✅ Best practices demonstration completed\n');
}

core.LanguageModel _createGrokModel(String apiKey) {
  return xai.xai(apiKey: apiKey).chatModel('grok-3');
}

Future<core.GenerateTextCallResult<Never>> _generateText({
  required core.LanguageModel model,
  required List<core.PromptMessage> prompt,
  double temperature = 0.7,
  int maxOutputTokens = 400,
  core.CallOptions callOptions = const core.CallOptions(),
}) {
  return core.generateTextCall<Never>(
    model: model,
    prompt: prompt,
    options: core.GenerateTextOptions(
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    ),
    callOptions: callOptions,
  );
}

/// 🎯 Key X.AI Grok Concepts Summary:
///
/// Unique Features:
/// - Real-time information access
/// - Witty and engaging personality
/// - Conversational and opinionated responses
///
/// Model Capabilities:
/// - Current events awareness through typed live-search options
/// - Humor and personality
/// - Engaging dialogue style
/// - Balanced helpfulness and entertainment
///
/// Configuration Tips:
/// - Higher temperature (0.7-0.8) for personality
/// - Lower temperature (0.3-0.5) for factual queries
/// - Use system prompts to guide personality
/// - Enable typed live search for current-events prompts
/// - Implement streaming for better UX
///
/// Best Use Cases:
/// - Interactive chatbots with personality
/// - Social media applications
/// - Entertainment and gaming
/// - Current events discussion
/// - Creative content generation
///
/// Next Steps:
/// - ../xai/live_search.dart: Stable xAI live-search examples
/// - ../../05_use_cases/chatbot.dart: Real-world applications
