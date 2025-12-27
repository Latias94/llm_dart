// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

/// 🔍 Provider Comparison - Help you choose the best AI provider
///
/// This example will test multiple providers simultaneously, allowing you to intuitively compare:
/// - Response quality
/// - Response speed
/// - Special features
/// - Cost considerations
///
/// Before running, please set the API keys for providers you want to test:
/// export OPENAI_API_KEY="your-key"
/// export ANTHROPIC_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
/// export DEEPSEEK_API_KEY="your-key"
void main() async {
  print('🔍 AI Provider Comparison Test\n');

  registerOpenAI();
  registerAnthropic();
  registerGroq();
  registerDeepSeek();
  registerOllama();

  // Test question - shows basic capabilities while highlighting differences
  final testQuestion =
      'Explain artificial intelligence in 3 key points, each point no more than 20 words.';

  print('📝 Test Question: $testQuestion\n');
  print('⏱️  Testing all providers...\n');

  // Create provider list
  final providers = await createProviders();

  // Test all providers in parallel
  final results = <String, ProviderResult>{};

  for (final entry in providers.entries) {
    final name = entry.key;
    final provider = entry.value;

    if (provider != null) {
      final result = await testProvider(name, provider, testQuestion);
      results[name] = result;
    }
  }

  // Display comparison results
  displayComparison(results);

  // Provide selection recommendations
  provideRecommendations(results);
}

/// Create all available providers
Future<Map<String, ChatCapability?>> createProviders() async {
  final providers = <String, ChatCapability?>{};

  // OpenAI
  try {
    final openaiKey = Platform.environment['OPENAI_API_KEY'];
    if (openaiKey == null || openaiKey.isEmpty) {
      providers['OpenAI'] = null;
      print('⚠️  OpenAI skipped: set OPENAI_API_KEY');
    } else {
      providers['OpenAI'] = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(openaiKey)
          .model('gpt-4o-mini')
          .temperature(0.7)
          .build();
    }
  } catch (e) {
    providers['OpenAI'] = null;
    print('⚠️  OpenAI creation failed: $e');
  }

  // Anthropic Claude
  try {
    final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
    if (anthropicKey == null || anthropicKey.isEmpty) {
      providers['Anthropic'] = null;
      print('⚠️  Anthropic skipped: set ANTHROPIC_API_KEY');
    } else {
      providers['Anthropic'] = await LLMBuilder()
          .provider(anthropicProviderId)
          .apiKey(anthropicKey)
          .model('claude-3-5-haiku-20241022')
          .temperature(0.7)
          .build();
    }
  } catch (e) {
    providers['Anthropic'] = null;
    print('⚠️  Anthropic creation failed: $e');
  }

  // Groq
  try {
    final groqKey = Platform.environment['GROQ_API_KEY'];
    if (groqKey == null || groqKey.isEmpty) {
      providers['Groq'] = null;
      print('⚠️  Groq skipped: set GROQ_API_KEY');
    } else {
      providers['Groq'] = await LLMBuilder()
          .provider(groqProviderId)
          .apiKey(groqKey)
          .model('llama-3.1-8b-instant')
          .temperature(0.7)
          .build();
    }
  } catch (e) {
    providers['Groq'] = null;
    print('⚠️  Groq creation failed: $e');
  }

  // DeepSeek
  try {
    final deepseekKey = Platform.environment['DEEPSEEK_API_KEY'];
    if (deepseekKey == null || deepseekKey.isEmpty) {
      providers['DeepSeek'] = null;
      print('⚠️  DeepSeek skipped: set DEEPSEEK_API_KEY');
    } else {
      providers['DeepSeek'] = await LLMBuilder()
          .provider(deepseekProviderId)
          .apiKey(deepseekKey)
          .model('deepseek-chat')
          .temperature(0.7)
          .build();
    }
  } catch (e) {
    providers['DeepSeek'] = null;
    print('⚠️  DeepSeek creation failed: $e');
  }

  // Ollama
  try {
    providers['Ollama'] = await LLMBuilder()
        .provider(ollamaProviderId)
        .baseUrl('http://localhost:11434')
        .model('llama3.2')
        .temperature(0.7)
        .build();
  } catch (e) {
    providers['Ollama'] = null;
    print('⚠️  Ollama creation failed: $e');
  }

  return providers;
}

/// Test a single provider
Future<ProviderResult> testProvider(
    String name, ChatCapability provider, String question) async {
  final stopwatch = Stopwatch()..start();

  try {
    final prompt = Prompt(messages: [PromptMessage.user(question)]);
    final result = await generateText(model: provider, promptIr: prompt);

    stopwatch.stop();

    return ProviderResult(
      name: name,
      success: true,
      response: result.text ?? 'No response',
      responseTime: stopwatch.elapsedMilliseconds,
      usage: result.usage,
      thinking: result.thinking,
    );
  } catch (e) {
    stopwatch.stop();

    return ProviderResult(
      name: name,
      success: false,
      response: 'Error: $e',
      responseTime: stopwatch.elapsedMilliseconds,
    );
  }
}

/// Display comparison results
void displayComparison(Map<String, ProviderResult> results) {
  print('📊 Comparison Results:\n');

  // Sort by response time
  final sortedResults = results.values.toList()
    ..sort((a, b) => a.responseTime.compareTo(b.responseTime));

  for (final result in sortedResults) {
    print('🤖 ${result.name}:');

    if (result.success) {
      print('   ✅ Status: Success');
      print('   ⏱️  Response Time: ${result.responseTime}ms');
      print('   💬 Reply: ${result.response}');

      if (result.usage != null) {
        print('   📊 Token Usage: ${result.usage!.totalTokens}');
      }

      if (result.thinking != null && result.thinking!.isNotEmpty) {
        print('   🧠 Thinking Process: Available');
      }
    } else {
      print('   ❌ Status: Failed');
      print('   💬 Error: ${result.response}');
    }

    print('');
  }
}

/// Provide selection recommendations
void provideRecommendations(Map<String, ProviderResult> results) {
  print('🎯 Selection Recommendations:\n');

  final successfulProviders = results.values.where((r) => r.success).toList();

  if (successfulProviders.isEmpty) {
    print('❌ No available providers, please check API key settings');
    return;
  }

  // Fastest provider
  final fastest = successfulProviders
      .reduce((a, b) => a.responseTime < b.responseTime ? a : b);
  print('⚡ Fastest Response: ${fastest.name} (${fastest.responseTime}ms)');

  // Usage scenario recommendations
  print('\n📋 Usage Scenario Recommendations:');

  for (final result in successfulProviders) {
    switch (result.name) {
      case 'OpenAI':
        print(
            '   🔵 OpenAI: Beginner\'s choice, stable and reliable, complete ecosystem');
        break;
      case 'Anthropic':
        print(
            '   🟣 Anthropic: Complex reasoning, thinking process, high safety');
        break;
      case 'Groq':
        print('   🟢 Groq: Real-time applications, fast response, lower cost');
        break;
      case 'DeepSeek':
        print(
            '   🔴 DeepSeek: High cost-effectiveness, Chinese-friendly, strong reasoning');
        break;
      case 'Ollama':
        print(
            '   🟡 Ollama: Local deployment, completely free, privacy protection');
        break;
    }
  }

  print('\n💡 Selection Suggestions:');
  print('   • Beginner learning: OpenAI (stable and reliable)');
  print('   • Production environment: Anthropic (highest quality)');
  print('   • Real-time applications: Groq (fastest speed)');
  print('   • Cost-sensitive: DeepSeek (high cost-effectiveness)');
  print('   • Privacy requirements: Ollama (local deployment)');

  print('\n🚀 Next Steps:');
  print(
      '   • Run basic_configuration.dart to learn configuration optimization');
  print('   • Check ../02_core_features/ for advanced features');
  print('   • Choose ../04_providers/ for specific provider deep dive');
}

/// Provider test result
class ProviderResult {
  final String name;
  final bool success;
  final String response;
  final int responseTime;
  final UsageInfo? usage;
  final String? thinking;

  ProviderResult({
    required this.name,
    required this.success,
    required this.response,
    required this.responseTime,
    this.usage,
    this.thinking,
  });
}
