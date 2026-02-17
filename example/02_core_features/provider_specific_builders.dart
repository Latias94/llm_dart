import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

/// Demonstrates provider-specific configuration via `providerOptions`.
///
/// Provider packages no longer depend on `llm_dart_builder`. Instead, configure
/// provider-only knobs via namespaced `providerOptions` using:
///
/// - `LLMBuilder.providerConfig((p) => ...)` (convenience)
/// - `LLMBuilder.providerOption(providerId, key, value)` (explicit)
/// - `LLMBuilder.providerTool(...)` for provider-native tools
Future<void> main() async {
  print('🏗️  Provider-Specific Configuration Demo\n');

  registerOpenAI();
  registerAnthropic();
  registerOllama();
  registerElevenLabs();
  registerOpenAICompatibleProvider('openrouter');

  // Get API keys from environment
  final openaiKey = Platform.environment['OPENAI_API_KEY'];
  final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
  final ollamaBaseUrl =
      Platform.environment['OLLAMA_BASE_URL'] ?? 'http://localhost:11434';
  final elevenlabsKey = Platform.environment['ELEVENLABS_API_KEY'];
  final openrouterKey = Platform.environment['OPENROUTER_API_KEY'];

  // Demo OpenAI-specific configuration
  await demoOpenAIBuilder(openaiKey);

  // Demo Anthropic-specific configuration
  await demoAnthropicBuilder(anthropicKey);

  // Demo Ollama-specific configuration
  await demoOllamaBuilder(ollamaBaseUrl);

  // Demo ElevenLabs-specific configuration
  await demoElevenLabsBuilder(elevenlabsKey);

  // Demo OpenRouter-specific configuration
  await demoOpenRouterBuilder(openrouterKey);

  // Demo mixed configurations
  await demoMixedConfigurations();

  print('✅ Provider-specific builders demo completed!');
}

/// Demonstrate OpenAI-specific builder configuration
Future<void> demoOpenAIBuilder(String? apiKey) async {
  print('🤖 OpenAI Builder Configuration');
  print('=' * 40);

  if (apiKey == null) {
    print('   ⚠️  OPENAI_API_KEY not set, skipping OpenAI demo\n');
    return;
  }

  try {
    // OpenAI with provider-specific parameters (providerOptions).
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4')
        .temperature(0.7)
        .maxTokens(100)
        .providerConfig(
          (config) => config
              .openai()
              .frequencyPenalty(0.5)
              .presencePenalty(0.3)
              .seed(12345)
              .parallelToolCalls(true)
              .logprobs(true)
              .topLogprobs(5),
        )
        .build();

    final result = await generateText(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user(
            'Write a creative short story opening about a mysterious door.',
          ),
        ],
      ),
    );

    print('   📝 Creative writing response:');
    final text = result.text ?? '';
    final preview = text.length > 150 ? text.substring(0, 150) : text;
    print('   $preview...\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Demonstrate Anthropic-specific builder configuration
Future<void> demoAnthropicBuilder(String? apiKey) async {
  print('🧠 Anthropic Builder Configuration');
  print('=' * 40);

  if (apiKey == null) {
    print('   ⚠️  ANTHROPIC_API_KEY not set, skipping Anthropic demo\n');
    return;
  }

  try {
    // Anthropic with metadata and container configuration
    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.5)
        .maxTokens(100)
        .providerConfig((config) => config.anthropic().metadata({
              'user_id': 'demo_user_123',
              'session_id': 'session_456',
              'application': 'llm_dart_demo',
              'environment': 'development',
            }))
        .build();

    final result = await generateText(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user('Explain the concept of metadata in AI systems.'),
        ],
      ),
    );

    print('   🔍 Metadata-tracked response:');
    final text = result.text ?? '';
    final preview = text.length > 150 ? text.substring(0, 150) : text;
    print('   $preview...\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Demonstrate Ollama-specific builder configuration
Future<void> demoOllamaBuilder(String baseUrl) async {
  print('🦙 Ollama Builder Configuration');
  print('=' * 40);

  try {
    // Ollama with performance-related provider options.
    final provider = await LLMBuilder()
        .provider(ollamaProviderId)
        .baseUrl(baseUrl)
        .model('llama3.2')
        .temperature(0.7)
        .maxTokens(100)
        .providerConfig(
          (config) => config
              .ollama()
              .numCtx(4096)
              .numGpu(-1) // Use all GPU layers
              .numThread(8)
              .numa(true)
              .numBatch(512)
              .keepAlive('10m')
              .raw(false),
        )
        .build();

    final result = await generateText(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user(
            'Explain how GPU acceleration works in language models.',
          ),
        ],
      ),
    );

    print('   ⚡ High-performance response:');
    final text = result.text ?? '';
    final preview = text.length > 150 ? text.substring(0, 150) : text;
    print('   $preview...\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Demonstrate ElevenLabs-specific builder configuration
Future<void> demoElevenLabsBuilder(String? apiKey) async {
  print('🎵 ElevenLabs Builder Configuration');
  print('=' * 40);

  if (apiKey == null) {
    print('   ⚠️  ELEVENLABS_API_KEY not set, skipping ElevenLabs demo\n');
    return;
  }

  try {
    // ElevenLabs with voice customization (providerOptions).
    final ttsProvider = await LLMBuilder()
        .provider(elevenLabsProviderId)
        .apiKey(apiKey)
        .providerOptions(elevenLabsProviderId, const {
      'voiceId': 'JBFqnCBsd6RMkjVDRZzb',
      'stability': 0.75,
      'similarityBoost': 0.8,
      'style': 0.2,
      'useSpeakerBoost': true,
    }).buildSpeech();

    // Generate speech (TTS)
    final response = await ttsProvider.textToSpeech(
      const TTSRequest(
        text:
            'Welcome to the new provider-specific builder pattern in LLM Dart!',
        format: 'mp3',
      ),
    );
    final audioData = response.audioData;

    print('   🔊 Generated audio: ${audioData.length} bytes');
    print('   💾 Audio saved to: elevenlabs_builder_demo.mp3\n');

    // Save audio file
    await File('elevenlabs_builder_demo.mp3').writeAsBytes(audioData);
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Demonstrate OpenRouter-specific builder configuration
Future<void> demoOpenRouterBuilder(String? apiKey) async {
  print('🌐 OpenRouter Builder Configuration');
  print('=' * 40);

  if (apiKey == null) {
    print('   ⚠️  OPENROUTER_API_KEY not set, skipping OpenRouter demo\n');
    return;
  }

  try {
    final provider = await LLMBuilder()
        .openRouter(
          (openrouter) => openrouter.appInfo(
            referer: 'https://example.com',
            title: 'llm_dart demo',
          ),
        )
        .apiKey(apiKey)
        .model('anthropic/claude-3.5-sonnet')
        .temperature(0.3)
        .maxTokens(150)
        .build();

    final result = await generateText(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user(
            'What are the latest developments in large language models?',
          ),
        ],
      ),
    );

    print('   🔍 Web-enhanced response:');
    final text = result.text ?? '';
    final preview = text.length > 200 ? text.substring(0, 200) : text;
    print('   $preview...\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Demonstrate mixed configurations and backward compatibility
Future<void> demoMixedConfigurations() async {
  print('🔄 Mixed Configurations & Backward Compatibility');
  print('=' * 50);

  // Providers work without any provider-specific wrapper.
  print('   ✅ No wrapper (only generic LLMBuilder):');
  final base = LLMBuilder()
      .provider(openaiProviderId)
      .apiKey('test-key')
      .model('gpt-4')
      .temperature(0.8)
      .maxTokens(500)
      .systemPrompt('You are a helpful assistant')
      .timeout(const Duration(seconds: 30));
  print('      Base builder type: ${base.runtimeType}');

  // Show mixed configuration with both generic and provider-specific parameters
  print('   ✅ Mixed configuration:');
  final mixed = base.providerConfig(
    (p) => p.openai().seed(42).parallelToolCalls(false),
  );
  print('      Mixed generic + providerOptions config successful');
  print(
      '      Builder configured with model: ${base.currentConfig.model}, temperature: ${base.currentConfig.temperature}');
  print('      Builder type: ${mixed.runtimeType}');

  print('');
}
