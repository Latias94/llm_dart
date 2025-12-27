// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';

/// 🚀 X.AI Grok Integration - Real-Time AI with Personality
///
/// This example demonstrates X.AI's Grok model capabilities:
/// - Real-time information access
/// - Conversational AI with personality
/// - Social media integration features
/// - Witty and engaging responses
///
/// Before running, set your API key:
/// export XAI_API_KEY="your-xai-api-key"
void main() async {
  print('🚀 X.AI Grok Integration - Real-Time AI with Personality\n');

  registerXAI();

  final apiKey = Platform.environment['XAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('⚠️  Skipped: Please set XAI_API_KEY environment variable');
    return;
  }

  // Demonstrate Grok's unique capabilities
  await demonstrateBasicGrok(apiKey);
  await demonstratePersonalityFeatures(apiKey);
  await demonstrateRealTimeInformation(apiKey);
  await demonstrateConversationalStyle(apiKey);
  await demonstrateBestPractices(apiKey);

  print('\n✅ X.AI Grok integration completed!');
}

/// Demonstrate basic Grok functionality
Future<void> demonstrateBasicGrok(String apiKey) async {
  print('🤖 Basic Grok Functionality:\n');

  try {
    final provider = await LLMBuilder()
        .provider(xaiProviderId)
        .apiKey(apiKey)
        .model('grok-3')
        .temperature(0.7)
        .maxTokens(500)
        .build();

    // Test basic conversation
    print('   Basic Conversation:');
    var response = await generateText(
      model: provider,
      messages: [
        ChatMessage.user('Hello Grok! Tell me something interesting about AI.')
      ],
    );
    print('      User: Hello Grok! Tell me something interesting about AI.');
    print('      Grok: ${response.text}\n');

    // Test with system prompt
    print('   With System Prompt:');
    response = await generateText(
      model: provider,
      messages: [
        ChatMessage.system(
            'You are Grok, a witty AI assistant with a sense of humor.'),
        ChatMessage.user('Explain quantum computing like I\'m 5 years old.')
      ],
    );
    print('      System: You are Grok, a witty AI assistant...');
    print('      User: Explain quantum computing like I\'m 5 years old.');
    print('      Grok: ${response.text}');

    if (response.usage != null) {
      print('\n      📊 Usage: ${response.usage!.totalTokens} tokens');
    }

    print('   ✅ Basic Grok demonstration completed\n');
  } catch (e) {
    print('   ❌ Basic Grok failed: $e\n');
  }
}

/// Demonstrate Grok's personality features
Future<void> demonstratePersonalityFeatures(String apiKey) async {
  print('😄 Personality Features:\n');

  try {
    final provider = await LLMBuilder()
        .provider(xaiProviderId)
        .apiKey(apiKey)
        .model('grok-3')
        .temperature(0.8) // Higher for more personality
        .maxTokens(400)
        .build();

    final personalityTests = [
      'Tell me a joke about programming.',
      'What do you think about the meaning of life?',
      'Explain why cats are better than dogs (or vice versa).',
      'What would you do if you were human for a day?',
    ];

    for (final test in personalityTests) {
      print('   Testing: $test');

      final response = await generateText(
        model: provider,
        messages: [
          ChatMessage.system(
              'Be witty, engaging, and show your personality. Don\'t be afraid to be humorous or opinionated.'),
          ChatMessage.user(test)
        ],
      );

      print('      Grok: ${response.text}\n');
    }

    print('   💡 Personality Highlights:');
    print('      • Witty and humorous responses');
    print('      • Engaging conversational style');
    print('      • Not afraid to express opinions');
    print('      • Balances humor with helpfulness');
    print('   ✅ Personality features demonstration completed\n');
  } catch (e) {
    print('   ❌ Personality features failed: $e\n');
  }
}

/// Demonstrate real-time information capabilities
Future<void> demonstrateRealTimeInformation(String apiKey) async {
  print('🌐 Real-Time Information:\n');

  try {
    final provider = await LLMBuilder()
        .provider(xaiProviderId)
        .apiKey(apiKey)
        .model('grok-3')
        .temperature(0.3) // Lower for factual information
        .maxTokens(600)
        .build();

    final realTimeQueries = [
      'What are the latest developments in AI this week?',
      'Tell me about recent tech news.',
      'What\'s happening in the world of cryptocurrency today?',
      'Any recent breakthroughs in space exploration?',
    ];

    for (final query in realTimeQueries) {
      print('   Query: $query');

      final response = await generateText(
        model: provider,
        messages: [
          ChatMessage.system(
              'Provide current, up-to-date information. If you\'re not sure about recent events, be honest about your knowledge cutoff.'),
          ChatMessage.user(query)
        ],
      );

      print('      Grok: ${response.text}\n');
    }

    print('   💡 Real-Time Features:');
    print('      • Access to current information');
    print('      • Recent news and developments');
    print('      • Current events awareness');
    print('      • Honest about knowledge limitations');
    print('   ✅ Real-time information demonstration completed\n');
  } catch (e) {
    print('   ❌ Real-time information failed: $e\n');
  }
}

/// Demonstrate conversational style
Future<void> demonstrateConversationalStyle(String apiKey) async {
  print('💬 Conversational Style:\n');

  try {
    final provider = await LLMBuilder()
        .provider(xaiProviderId)
        .apiKey(apiKey)
        .model('grok-3')
        .temperature(0.7)
        .maxTokens(400)
        .build();

    // Multi-turn conversation
    print('   Multi-turn Conversation:');
    final conversation = [
      ChatMessage.system(
          'You are Grok. Be conversational, witty, and remember the context of our chat.'),
      ChatMessage.user('I\'m thinking about learning to code. Any advice?'),
    ];

    var response = await generateText(model: provider, messages: conversation);
    print('      User: I\'m thinking about learning to code. Any advice?');
    print('      Grok: ${response.text}\n');

    // Continue conversation
    conversation.add(ChatMessage.assistant(response.text ?? ''));
    conversation.add(ChatMessage.user(
        'I\'m particularly interested in AI and machine learning.'));

    response = await generateText(model: provider, messages: conversation);
    print(
        '      User: I\'m particularly interested in AI and machine learning.');
    print('      Grok: ${response.text}\n');

    // Another follow-up
    conversation.add(ChatMessage.assistant(response.text ?? ''));
    conversation.add(
        ChatMessage.user('What programming language should I start with?'));

    response = await generateText(model: provider, messages: conversation);
    print('      User: What programming language should I start with?');
    print('      Grok: ${response.text}');

    print('\n   💡 Conversational Strengths:');
    print('      • Maintains context across turns');
    print('      • Natural, flowing dialogue');
    print('      • Builds on previous responses');
    print('      • Engaging and helpful');
    print('   ✅ Conversational style demonstration completed\n');
  } catch (e) {
    print('   ❌ Conversational style failed: $e\n');
  }
}

/// Demonstrate best practices
Future<void> demonstrateBestPractices(String apiKey) async {
  print('🏆 Best Practices:\n');

  // Error handling
  print('   Error Handling:');
  try {
    final provider = await LLMBuilder()
        .provider(xaiProviderId)
        .apiKey('invalid-key') // Intentionally invalid
        .model('grok-3')
        .build();

    await generateText(model: provider, messages: [ChatMessage.user('Test')]);
  } on AuthError catch (e) {
    print('      ✅ Properly caught AuthError: ${e.message}');
  } catch (e) {
    print('      ⚠️  Unexpected error type: $e');
  }

  // Optimal configuration
  print('\n   Optimal Configuration:');
  try {
    final optimizedProvider = await LLMBuilder()
        .provider(xaiProviderId)
        .apiKey(apiKey)
        .model('grok-3')
        .temperature(0.7) // Balanced creativity
        .maxTokens(500) // Reasonable response length
        .systemPrompt('You are Grok, a helpful and witty AI assistant.')
        .timeout(Duration(seconds: 30))
        .build();

    final response = await generateText(
      model: optimizedProvider,
      messages: [
        ChatMessage.user('Give me a creative solution to reduce plastic waste.')
      ],
    );

    print('      ✅ Optimized response: ${response.text?.substring(0, 150)}...');
  } catch (e) {
    print('      ❌ Optimization error: $e');
  }

  // Streaming for better UX
  print('\n   Streaming for Better UX:');
  try {
    final streamProvider = await LLMBuilder()
        .provider(xaiProviderId)
        .apiKey(apiKey)
        .model('grok-3')
        .temperature(0.7)
        .build();

    print('      Question: Write a short poem about technology.');
    print('      Grok (streaming): ');

    await for (final part in streamText(
      model: streamProvider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user('Write a short poem about technology.'),
        ],
      ),
    )) {
      switch (part) {
        case TextDeltaPart(delta: final delta):
          stdout.write(delta);
          break;
        case FinishPart():
          print('\n      ✅ Streaming completed');
          break;
        case ErrorPart(error: final error):
          print('\n      ❌ Stream error: $error');
          break;
        case ThinkingDeltaPart():
        case ToolCallDeltaPart():
          // Handle other event types
          break;
      }
    }
  } catch (e) {
    print('      ❌ Streaming error: $e');
  }

  print('\n   💡 Best Practices Summary:');
  print('      • Use appropriate temperature for task type');
  print('      • Leverage Grok\'s personality for engaging responses');
  print('      • Implement streaming for better user experience');
  print('      • Handle errors gracefully');
  print('      • Take advantage of real-time information');
  print('      • Use system prompts to guide personality');
  print('   ✅ Best practices demonstration completed\n');
}

/// 🎯 Key X.AI Grok Concepts Summary:
///
/// Unique Features:
/// - Real-time information access
/// - Witty and engaging personality
/// - Social media integration capabilities
/// - Conversational and opinionated responses
///
/// Model Capabilities:
/// - Current events awareness
/// - Humor and personality
/// - Engaging dialogue style
/// - Balanced helpfulness and entertainment
///
/// Configuration Tips:
/// - Higher temperature (0.7-0.8) for personality
/// - Lower temperature (0.3-0.5) for factual queries
/// - Use system prompts to guide personality
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
/// - openrouter.dart: Multi-provider access
/// - custom_providers.dart: Building custom integrations
/// - ../../05_use_cases/chatbot.dart: Real-world applications
