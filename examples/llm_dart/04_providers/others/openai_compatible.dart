// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 🔗 OpenAI-Compatible Providers - Unified Interface Demo
///
/// This example demonstrates all OpenAI-compatible providers:
/// - DeepSeek (OpenAI-compatible interface)
/// - Groq (ultra-fast inference)
/// - xAI Grok (reasoning capabilities)
/// - OpenRouter (multi-model access)
/// - GitHub Copilot (coding assistance)
/// - Together AI (open source models)
///
/// Before running, set your API keys:
/// export DEEPSEEK_API_KEY="your-deepseek-api-key"
/// export GROQ_API_KEY="your-groq-api-key"
/// export XAI_API_KEY="your-xai-api-key"
/// export OPENROUTER_API_KEY="your-openrouter-api-key"
/// export GITHUB_COPILOT_API_KEY="your-github-copilot-api-key"
/// export TOGETHER_API_KEY="your-together-ai-api-key"
void main() async {
  print('🔗 OpenAI-Compatible Providers - Unified Interface Demo\n');

  // Get API keys from environment
  final apiKeys = {
    'deepseek': Platform.environment['DEEPSEEK_API_KEY'] ?? 'sk-TESTKEY',
    'groq': Platform.environment['GROQ_API_KEY'] ?? 'gsk_TESTKEY',
    'xai': Platform.environment['XAI_API_KEY'] ?? 'xai-TESTKEY',
    'openrouter': Platform.environment['OPENROUTER_API_KEY'] ?? 'or-TESTKEY',
    'copilot': Platform.environment['GITHUB_COPILOT_API_KEY'] ?? 'ghu_TESTKEY',
    'together': Platform.environment['TOGETHER_API_KEY'] ?? 'together-TESTKEY',
  };

  // Demonstrate all OpenAI-compatible providers
  await demonstrateAllProviders(apiKeys);
  await demonstrateProviderComparison(apiKeys);
  await demonstrateSpecializedUseCases(apiKeys);
  await demonstrateBestPractices(apiKeys);

  print('\n✅ OpenAI-compatible providers demo completed!');
}

/// Demonstrate all OpenAI-compatible providers
Future<void> demonstrateAllProviders(Map<String, String> apiKeys) async {
  print('🚀 All OpenAI-Compatible Providers:\n');

  final providers = [
    {
      'name': 'DeepSeek',
      'method': 'deepseekOpenAI',
      'model': 'deepseek-chat',
      'key': apiKeys['deepseek']!,
      'description': 'Cost-effective with reasoning capabilities'
    },
    {
      'name': 'Groq',
      'method': 'groqOpenAI',
      'model': 'llama-3.3-70b-versatile',
      'key': apiKeys['groq']!,
      'description': 'Ultra-fast inference speeds'
    },
    {
      'name': 'xAI Grok',
      'method': 'xaiOpenAI',
      'model': 'grok-3',
      'key': apiKeys['xai']!,
      'description': 'Real-time info with personality'
    },
    {
      'name': 'OpenRouter',
      'method': 'openRouter',
      'model': 'openai/gpt-4',
      'key': apiKeys['openrouter']!,
      'description': 'Access to multiple AI models'
    },
    {
      'name': 'GitHub Copilot',
      'method': 'githubCopilot',
      'model': 'gpt-4',
      'key': apiKeys['copilot']!,
      'description': 'Specialized for coding tasks'
    },
    {
      'name': 'Together AI',
      'method': 'togetherAI',
      'model': 'meta-llama/Llama-3-70b-chat-hf',
      'key': apiKeys['together']!,
      'description': 'Open source model platform'
    },
  ];

  final question = 'What are the benefits of using AI in software development?';

  for (final provider in providers) {
    try {
      print('   ${provider['name']}: ${provider['description']}');

      // Create provider using the appropriate method
      late final LanguageModel model;
      switch (provider['method']) {
        case 'deepseekOpenAI':
          model = await ai()
              .deepseekOpenAI()
              .apiKey(provider['key']!)
              .model(provider['model']!)
              .temperature(0.7)
              .maxTokens(200)
              .buildLanguageModel();
          break;
        case 'groqOpenAI':
          model = await ai()
              .groqOpenAI()
              .apiKey(provider['key']!)
              .model(provider['model']!)
              .temperature(0.7)
              .maxTokens(200)
              .buildLanguageModel();
          break;
        case 'xaiOpenAI':
          model = await ai()
              .xaiOpenAI()
              .apiKey(provider['key']!)
              .model(provider['model']!)
              .temperature(0.7)
              .maxTokens(200)
              .buildLanguageModel();
          break;
        case 'openRouter':
          model = await ai()
              .openRouter()
              .apiKey(provider['key']!)
              .model(provider['model']!)
              .temperature(0.7)
              .maxTokens(200)
              .buildLanguageModel();
          break;
        case 'githubCopilot':
          model = await ai()
              .githubCopilot()
              .apiKey(provider['key']!)
              .model(provider['model']!)
              .temperature(0.7)
              .maxTokens(200)
              .buildLanguageModel();
          break;
        case 'togetherAI':
          model = await ai()
              .togetherAI()
              .apiKey(provider['key']!)
              .model(provider['model']!)
              .temperature(0.7)
              .maxTokens(200)
              .buildLanguageModel();
          break;
      }

      final stopwatch = Stopwatch()..start();
      final prompt = ChatPromptBuilder.user().text(question).build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      stopwatch.stop();

      print('      Response: ${response.text?.substring(0, 100)}...');
      print('      Time: ${stopwatch.elapsedMilliseconds}ms');

      if (response.usage != null) {
        print('      Tokens: ${response.usage!.totalTokens}');
      }
      print('');
    } catch (e) {
      print('      ❌ Error: $e\n');
    }
  }

  print('   ✅ All providers demonstration completed\n');
}

/// Compare providers for specific tasks
Future<void> demonstrateProviderComparison(Map<String, String> apiKeys) async {
  print('⚖️  Provider Comparison:\n');

  final tasks = [
    {
      'name': 'Coding Task',
      'prompt': 'Write a Python function to calculate factorial recursively.',
      'providers': ['deepseekOpenAI', 'groqOpenAI', 'githubCopilot']
    },
    {
      'name': 'Creative Writing',
      'prompt': 'Write a short story about a robot learning to paint.',
      'providers': ['xaiOpenAI', 'openRouter', 'togetherAI']
    },
  ];

  for (final task in tasks) {
    print('   ${task['name']}: "${task['prompt']}"');
    print('');

    for (final providerMethod in task['providers'] as List<String>) {
      try {
        late final LanguageModel model;
        late final String providerName;

        switch (providerMethod) {
          case 'deepseekOpenAI':
            model = await ai()
                .deepseekOpenAI()
                .apiKey(apiKeys['deepseek']!)
                .model('deepseek-chat')
                .temperature(0.3)
                .maxTokens(150)
                .buildLanguageModel();
            providerName = 'DeepSeek';
            break;
          case 'groqOpenAI':
            model = await ai()
                .groqOpenAI()
                .apiKey(apiKeys['groq']!)
                .model('llama-3.3-70b-versatile')
                .temperature(0.3)
                .maxTokens(150)
                .buildLanguageModel();
            providerName = 'Groq';
            break;
          case 'githubCopilot':
            model = await ai()
                .githubCopilot()
                .apiKey(apiKeys['copilot']!)
                .model('gpt-4')
                .temperature(0.3)
                .maxTokens(150)
                .buildLanguageModel();
            providerName = 'GitHub Copilot';
            break;
          case 'xaiOpenAI':
            model = await ai()
                .xaiOpenAI()
                .apiKey(apiKeys['xai']!)
                .model('grok-3')
                .temperature(0.8)
                .maxTokens(150)
                .buildLanguageModel();
            providerName = 'xAI Grok';
            break;
          case 'openRouter':
            model = await ai()
                .openRouter()
                .apiKey(apiKeys['openrouter']!)
                .model('openai/gpt-4')
                .temperature(0.8)
                .maxTokens(150)
                .buildLanguageModel();
            providerName = 'OpenRouter';
            break;
          case 'togetherAI':
            model = await ai()
                .togetherAI()
                .apiKey(apiKeys['together']!)
                .model('meta-llama/Llama-3-70b-chat-hf')
                .temperature(0.8)
                .maxTokens(150)
                .buildLanguageModel();
            providerName = 'Together AI';
            break;
          default:
            continue;
        }

        final prompt =
            ChatPromptBuilder.user().text(task['prompt'] as String).build();
        final response = await generateTextWithModel(
          model,
          promptMessages: [prompt],
        );
        print('      $providerName: ${response.text}');
        print('');
      } catch (e) {
        print('      $providerMethod: Error - $e');
        print('');
      }
    }
    print('');
  }

  print('   ✅ Provider comparison completed\n');
}

/// Demonstrate specialized use cases
Future<void> demonstrateSpecializedUseCases(Map<String, String> apiKeys) async {
  print('🎯 Specialized Use Cases:\n');

  // Fast inference with Groq
  print('   Fast Inference (Groq):');
  try {
    final groq = await ai()
        .groqOpenAI()
        .apiKey(apiKeys['groq']!)
        .model('llama-3.3-70b-versatile')
        .temperature(0.5)
        .maxTokens(100)
        .buildLanguageModel();

    final stopwatch = Stopwatch()..start();
    final prompt = ChatPromptBuilder.user()
        .text('Quickly explain what is machine learning?')
        .build();
    final response = await generateTextWithModel(
      groq,
      promptMessages: [prompt],
    );
    stopwatch.stop();

    print('      Response: ${response.text}');
    print('      Speed: ${stopwatch.elapsedMilliseconds}ms (Ultra-fast!)');
  } catch (e) {
    print('      Error: $e');
  }

  // Reasoning with DeepSeek
  print('\n   Complex Reasoning (DeepSeek):');
  try {
    final deepseek = await ai()
        .deepseekOpenAI()
        .apiKey(apiKeys['deepseek']!)
        .model('deepseek-reasoner')
        .temperature(0.1)
        .maxTokens(300)
        .reasoning(true)
        .buildLanguageModel();

    final prompt = ChatPromptBuilder.user()
        .text(
            'If a train travels 120 km in 1.5 hours, and then 80 km in 45 minutes, what is the average speed for the entire journey?')
        .build();
    final response = await generateTextWithModel(
      deepseek,
      promptMessages: [prompt],
    );

    print('      Response: ${response.text}');
    if (response.thinking != null) {
      print('      Thinking: ${response.thinking?.substring(0, 100)}...');
    }
  } catch (e) {
    print('      Error: $e');
  }

  // Coding with GitHub Copilot
  print('\n   Coding Assistance (GitHub Copilot):');
  try {
    final copilot = await ai()
        .githubCopilot()
        .apiKey(apiKeys['copilot']!)
        .model('gpt-4')
        .temperature(0.2)
        .maxTokens(200)
        .systemPrompt(
            'You are a helpful coding assistant. Provide clean, well-commented code.')
        .buildLanguageModel();

    final prompt = ChatPromptBuilder.user()
        .text(
            'Create a simple HTTP server in Dart that responds with "Hello World"')
        .build();
    final response = await generateTextWithModel(
      copilot,
      promptMessages: [prompt],
    );

    print('      Response: ${response.text}');
  } catch (e) {
    print('      Error: $e');
  }

  // Multi-model access with OpenRouter
  print('\n   Multi-Model Access (OpenRouter):');
  try {
    final openrouter = await ai()
        .openRouter()
        .apiKey(apiKeys['openrouter']!)
        .model('anthropic/claude-3-sonnet')
        .temperature(0.7)
        .maxTokens(150)
        .buildLanguageModel();

    final prompt = ChatPromptBuilder.user()
        .text('Explain the difference between AI, ML, and Deep Learning')
        .build();
    final response = await generateTextWithModel(
      openrouter,
      promptMessages: [prompt],
    );

    print('      Response (Claude via OpenRouter): ${response.text}');
  } catch (e) {
    print('      Error: $e');
  }

  print('\n   ✅ Specialized use cases completed\n');
}

/// Demonstrate best practices
Future<void> demonstrateBestPractices(Map<String, String> apiKeys) async {
  print('🏆 Best Practices:\n');

  // Error handling
  print('   Error Handling:');
  try {
    final model = await ai()
        .deepseekOpenAI()
        .apiKey('invalid-key')
        .model('deepseek-chat')
        .buildLanguageModel();

    final prompt = ChatPromptBuilder.user().text('Test').build();
    await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );
  } on AuthError catch (e) {
    print('      ✅ Properly caught AuthError: ${e.message}');
  } catch (e) {
    print('      ⚠️  Unexpected error type: $e');
  }

  // Provider fallback strategy
  print('\n   Provider Fallback Strategy:');
  final fallbackProviders = [
    () => ai()
        .groqOpenAI()
        .apiKey(apiKeys['groq']!)
        .model('llama-3.3-70b-versatile'),
    () => ai()
        .deepseekOpenAI()
        .apiKey(apiKeys['deepseek']!)
        .model('deepseek-chat'),
    () => ai()
        .openRouter()
        .apiKey(apiKeys['openrouter']!)
        .model('openai/gpt-3.5-turbo'),
  ];

  for (int i = 0; i < fallbackProviders.length; i++) {
    try {
      final model = await fallbackProviders[i]().buildLanguageModel();
      final prompt = ChatPromptBuilder.user().text('Test fallback').build();
      await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      print('      ✅ Successfully used fallback provider ${i + 1}');
      break;
    } catch (e) {
      print('      ⚠️  Fallback provider ${i + 1} failed: $e');
      continue;
    }
  }

  // Configuration optimization
  print('\n   Configuration Optimization:');
  final optimizedConfigs = {
    'Fast responses': () => ai()
        .groqOpenAI()
        .apiKey(apiKeys['groq']!)
        .temperature(0.3)
        .maxTokens(100),
    'Creative writing': () => ai()
        .xaiOpenAI()
        .apiKey(apiKeys['xai']!)
        .temperature(0.9)
        .maxTokens(500),
    'Code generation': () => ai()
        .githubCopilot()
        .apiKey(apiKeys['copilot']!)
        .temperature(0.1)
        .maxTokens(300),
    'Cost-effective': () => ai()
        .deepseekOpenAI()
        .apiKey(apiKeys['deepseek']!)
        .temperature(0.7)
        .maxTokens(200),
  };

  for (final entry in optimizedConfigs.entries) {
    try {
      await entry.value().buildLanguageModel();
      print('      ✅ ${entry.key}: Configuration ready');
    } catch (e) {
      print('      ❌ ${entry.key}: Configuration failed - $e');
    }
  }

  print('\n   💡 Best Practices Summary:');
  print('      • Implement proper error handling for all providers');
  print('      • Use fallback strategies for reliability');
  print('      • Choose providers based on specific use cases:');
  print('        - Groq: Speed-critical applications');
  print('        - DeepSeek: Cost-effective with reasoning');
  print('        - GitHub Copilot: Coding assistance');
  print('        - OpenRouter: Model variety and comparison');
  print('        - xAI: Real-time info and personality');
  print('        - Together AI: Open source model access');
  print('      • Optimize configurations for each task type');
  print('      • Monitor usage and costs across providers');
  print('   ✅ Best practices demonstration completed\n');
}

/// 🎯 Key OpenAI-Compatible Providers Summary:
///
/// Provider Strengths:
/// - DeepSeek: Cost-effective, reasoning capabilities, OpenAI compatibility
/// - Groq: Ultra-fast inference, excellent for real-time applications
/// - xAI Grok: Real-time information, personality, reasoning
/// - OpenRouter: Multi-model access, provider comparison, flexibility
/// - GitHub Copilot: Specialized for coding, integrated development
/// - Together AI: Open source models, community-driven, cost-effective
///
/// Usage Patterns:
/// - All use the same OpenAI-compatible interface
/// - Easy to switch between providers
/// - Consistent API across different backends
/// - Unified error handling and response format
///
/// Selection Criteria:
/// - Speed: Groq > Others
/// - Cost: DeepSeek, Together AI > OpenRouter > Others
/// - Reasoning: DeepSeek, xAI > Others
/// - Coding: GitHub Copilot > DeepSeek > Others
/// - Variety: OpenRouter > Others
/// - Open Source: Together AI > Others
///
/// Best Use Cases:
/// - Multi-provider applications with fallback
/// - Cost optimization through provider selection
/// - Performance optimization for different tasks
/// - A/B testing different AI providers
/// - Specialized workflows (coding, reasoning, etc.)
///
/// Next Steps:
/// - Explore individual provider examples for advanced features
/// - Implement provider selection logic in your applications
/// - Monitor performance and costs across providers
/// - Consider hybrid approaches using multiple providers
