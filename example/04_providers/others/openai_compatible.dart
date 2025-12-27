// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

/// 🔗 OpenAI-Compatible Providers - Unified Interface Demo
///
/// This example demonstrates OpenAI-compatible providers shipped in
/// `llm_dart_openai_compatible`, which offers pre-configured providers
/// that share an OpenAI-style API surface (chat/stream/tools/embeddings).
///
/// Supported (in this repo):
/// - DeepSeek (`deepseek-openai`)
/// - Groq (`groq-openai`)
/// - xAI (`xai-openai`)
/// - Google Gemini OpenAI compat (`google-openai`)
/// - OpenRouter (`openrouter`)
///
/// Before running, set the API keys you want to try:
/// export DEEPSEEK_API_KEY="..."
/// export GROQ_API_KEY="..."
/// export XAI_API_KEY="..."
/// export GOOGLE_API_KEY="..."
/// export OPENROUTER_API_KEY="..."
void main() async {
  print('🔗 OpenAI-Compatible Providers - Unified Interface Demo\n');

  registerOpenAICompatibleProviders();

  await demonstrateAllProviders();
  await demonstrateProviderComparison();
  await demonstrateSpecializedUseCases();
  await demonstrateBestPractices();

  print('\n✅ OpenAI-compatible providers demo completed!');
}

class _ProviderSpec {
  final String providerId;
  final String displayName;
  final String envVar;
  final String defaultModel;

  const _ProviderSpec({
    required this.providerId,
    required this.displayName,
    required this.envVar,
    required this.defaultModel,
  });
}

const _providers = <_ProviderSpec>[
  _ProviderSpec(
    providerId: 'deepseek-openai',
    displayName: 'DeepSeek (OpenAI-compatible)',
    envVar: 'DEEPSEEK_API_KEY',
    defaultModel: 'deepseek-chat',
  ),
  _ProviderSpec(
    providerId: 'groq-openai',
    displayName: 'Groq (OpenAI-compatible)',
    envVar: 'GROQ_API_KEY',
    defaultModel: 'llama-3.3-70b-versatile',
  ),
  _ProviderSpec(
    providerId: 'xai-openai',
    displayName: 'xAI (OpenAI-compatible)',
    envVar: 'XAI_API_KEY',
    defaultModel: 'grok-3',
  ),
  _ProviderSpec(
    providerId: 'google-openai',
    displayName: 'Google Gemini (OpenAI-compatible)',
    envVar: 'GOOGLE_API_KEY',
    defaultModel: 'gemini-2.0-flash',
  ),
  _ProviderSpec(
    providerId: 'openrouter',
    displayName: 'OpenRouter',
    envVar: 'OPENROUTER_API_KEY',
    defaultModel: 'openai/gpt-4',
  ),
];

_ProviderSpec? _byId(String providerId) {
  for (final spec in _providers) {
    if (spec.providerId == providerId) return spec;
  }
  return null;
}

String? _env(String name) => Platform.environment[name];

Future<ChatCapability?> _buildChatProvider(
  _ProviderSpec spec, {
  String? model,
  double? temperature,
  int? maxTokens,
  bool? reasoning,
  String? systemPrompt,
}) async {
  final apiKey = _env(spec.envVar);
  if (apiKey == null || apiKey.isEmpty) return null;

  final builder = LLMBuilder()
      .provider(spec.providerId)
      .apiKey(apiKey)
      .model(model ?? spec.defaultModel);

  if (temperature != null) builder.temperature(temperature);
  if (maxTokens != null) builder.maxTokens(maxTokens);
  if (reasoning != null) builder.reasoning(reasoning);
  if (systemPrompt != null) builder.systemPrompt(systemPrompt);

  return builder.build();
}

Prompt _prompt(String text, {String? system}) => Prompt(
      messages: [
        if (system != null && system.isNotEmpty) PromptMessage.system(system),
        PromptMessage.user(text),
      ],
    );

Future<void> demonstrateAllProviders() async {
  print('🚀 All OpenAI-Compatible Providers:\n');

  final question = 'What are the benefits of using AI in software development?';

  for (final provider in _providers) {
    final instance = await _buildChatProvider(
      provider,
      temperature: 0.7,
      maxTokens: 200,
    );

    if (instance == null) {
      print(
          '   ${provider.displayName}: Skipped (missing ${provider.envVar})\n');
      continue;
    }

    final stopwatch = Stopwatch()..start();
    final result = await generateText(
      model: instance,
      promptIr: _prompt(question),
    );
    stopwatch.stop();

    final text = result.text ?? '';
    final preview = text.length > 140 ? '${text.substring(0, 140)}...' : text;

    print('   ${provider.displayName}');
    print('      Model: ${provider.defaultModel}');
    print('      Time: ${stopwatch.elapsedMilliseconds}ms');
    print('      Response: $preview\n');
  }

  print('   ✅ All providers demonstration completed\n');
}

Future<void> demonstrateProviderComparison() async {
  print('⚖️  Provider Comparison:\n');

  final tasks = [
    (
      name: 'Short answer',
      prompt: 'Explain what embeddings are in one paragraph.',
      providers: ['google-openai', 'deepseek-openai', 'groq-openai'],
    ),
    (
      name: 'Creative writing',
      prompt: 'Write a short story about a robot learning to paint.',
      providers: ['xai-openai', 'openrouter'],
    ),
  ];

  for (final task in tasks) {
    print('   ${task.name}: "${task.prompt}"\n');

    for (final providerId in task.providers) {
      final spec = _byId(providerId);
      if (spec == null) continue;

      final instance = await _buildChatProvider(
        spec,
        temperature: 0.6,
        maxTokens: 180,
      );

      if (instance == null) {
        print('      ${spec.displayName}: Skipped (missing ${spec.envVar})');
        continue;
      }

      try {
        final result = await generateText(
          model: instance,
          promptIr: _prompt(task.prompt),
        );

        final text = result.text ?? '';
        final preview =
            text.length > 120 ? '${text.substring(0, 120)}...' : text;
        print('      ${spec.displayName}: $preview');
      } catch (e) {
        print('      ${spec.displayName}: Error - $e');
      }
    }

    print('');
  }

  print('   ✅ Provider comparison completed\n');
}

Future<void> demonstrateSpecializedUseCases() async {
  print('🎯 Specialized Use Cases:\n');

  // Fast inference (Groq)
  {
    final spec = _byId('groq-openai');
    if (spec != null) {
      print('   Fast inference (${spec.displayName}):');
      final provider = await _buildChatProvider(
        spec,
        temperature: 0.4,
        maxTokens: 100,
      );
      if (provider == null) {
        print('      Skipped (missing ${spec.envVar})\n');
      } else {
        final stopwatch = Stopwatch()..start();
        final result = await generateText(
          model: provider,
          promptIr: _prompt('Quickly explain what machine learning is.'),
        );
        stopwatch.stop();
        print('      Time: ${stopwatch.elapsedMilliseconds}ms');
        print('      Response: ${result.text}\n');
      }
    }
  }

  // Reasoning-ish use case (DeepSeek)
  {
    final spec = _byId('deepseek-openai');
    if (spec != null) {
      print('   Complex reasoning (${spec.displayName}):');
      final provider = await _buildChatProvider(
        spec,
        model: 'deepseek-reasoner',
        temperature: 0.2,
        maxTokens: 260,
        reasoning: true,
      );
      if (provider == null) {
        print('      Skipped (missing ${spec.envVar})\n');
      } else {
        final result = await generateText(
          model: provider,
          promptIr: _prompt(
            'If a train travels 120 km in 1.5 hours, and then 80 km in 45 minutes, '
            'what is the average speed for the entire journey?',
          ),
        );
        print('      Response: ${result.text}\n');
      }
    }
  }

  // Coding assistant-ish (Groq)
  {
    final spec = _byId('groq-openai');
    if (spec != null) {
      print('   Coding assistance (${spec.displayName}):');
      final provider = await _buildChatProvider(
        spec,
        temperature: 0.2,
        maxTokens: 220,
        systemPrompt:
            'You are a helpful coding assistant. Provide clean, minimal code.',
      );
      if (provider == null) {
        print('      Skipped (missing ${spec.envVar})\n');
      } else {
        final result = await generateText(
          model: provider,
          promptIr: _prompt(
            'Create a simple HTTP server in Dart that responds with "Hello World".',
          ),
        );
        print('      Response: ${result.text}\n');
      }
    }
  }

  // Multi-model access (OpenRouter)
  {
    final spec = _byId('openrouter');
    if (spec != null) {
      print('   Multi-model access (${spec.displayName}):');
      final provider = await _buildChatProvider(
        spec,
        model: 'anthropic/claude-3-sonnet',
        temperature: 0.7,
        maxTokens: 180,
      );
      if (provider == null) {
        print('      Skipped (missing ${spec.envVar})\n');
      } else {
        final result = await generateText(
          model: provider,
          promptIr: _prompt(
            'Explain the difference between AI, ML, and Deep Learning.',
          ),
        );
        print('      Response: ${result.text}\n');
      }
    }
  }

  print('   ✅ Specialized use cases completed\n');
}

Future<void> demonstrateBestPractices() async {
  print('🏆 Best Practices:\n');

  // Error handling
  print('   Error handling:');
  try {
    final provider = await LLMBuilder()
        .provider('deepseek-openai')
        .apiKey('invalid-key')
        .model('deepseek-chat')
        .build();

    await generateText(model: provider, promptIr: _prompt('Test'));
    print('      ⚠️  Unexpected: request succeeded with invalid key');
  } on AuthError catch (e) {
    print('      ✅ Caught AuthError: ${e.message}');
  } catch (e) {
    print('      ⚠️  Unexpected error type: $e');
  }

  // Fallback strategy
  print('\n   Fallback strategy:');
  final fallbackOrder = ['groq-openai', 'deepseek-openai', 'openrouter'];
  var succeeded = false;

  for (final providerId in fallbackOrder) {
    final spec = _byId(providerId);
    if (spec == null) continue;

    final provider = await _buildChatProvider(
      spec,
      temperature: 0.3,
      maxTokens: 80,
    );

    if (provider == null) {
      print('      ${spec.displayName}: Skipped (missing ${spec.envVar})');
      continue;
    }

    try {
      await generateText(
        model: provider,
        promptIr: _prompt('Return the word "ok".'),
      );
      print('      ✅ Selected: ${spec.displayName}');
      succeeded = true;
      break;
    } catch (e) {
      print('      ${spec.displayName}: Failed - $e');
    }
  }

  if (!succeeded) {
    print('      ❌ No fallback providers available (missing API keys)');
  }

  print('\n   ✅ Best practices demonstration completed\n');
}
