import 'dart:io';
import 'package:llm_dart/legacy.dart';

/// Demonstrates the new provider-specific builder pattern
///
/// This example shows how to use the new callback-style configuration
/// for provider-specific parameters, keeping the main LLMBuilder clean
/// while providing powerful customization options.
Future<void> main() async {
  print('🏗️  Provider-Specific Builders Demo\n');

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
    // OpenAI with provider-specific parameters
    final provider = await LLMBuilder()
        .openai((openai) => openai
            .frequencyPenalty(0.5)
            .presencePenalty(0.3)
            .seed(12345)
            .parallelToolCalls(true)
            .logprobs(true)
            .topLogprobs(5)
            .forCreativeWriting()) // Convenience method
        .apiKey(apiKey)
        .model('gpt-4')
        .temperature(0.7)
        .maxTokens(100)
        .build();

    final response = await provider.chat([
      ChatMessage.user(
          'Write a creative short story opening about a mysterious door.')
    ]);

    print('   📝 Creative writing response:');
    print('   ${response.text?.substring(0, 150)}...\n');
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
        .anthropic((anthropic) => anthropic.metadata({
              'user_id': 'demo_user_123',
              'session_id': 'session_456',
              'application': 'llm_dart_demo',
              'environment': 'development',
            }).forProduction(
              userId: 'demo_user_123',
              sessionId: 'session_456',
              applicationName: 'llm_dart_demo',
            )) // Convenience method
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.5)
        .maxTokens(100)
        .build();

    final response = await provider.chat(
        [ChatMessage.user('Explain the concept of metadata in AI systems.')]);

    print('   🔍 Metadata-tracked response:');
    print('   ${response.text?.substring(0, 150)}...\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Demonstrate Ollama-specific builder configuration
Future<void> demoOllamaBuilder(String baseUrl) async {
  print('🦙 Ollama Builder Configuration');
  print('=' * 40);

  try {
    // Ollama with performance optimization
    final provider = await LLMBuilder()
        .ollama((ollama) => ollama
            .numCtx(4096)
            .numGpu(-1) // Use all GPU layers
            .numThread(8)
            .numa(true)
            .numBatch(512)
            .keepAlive('10m')
            .forMaxPerformance()) // Convenience method
        .baseUrl(baseUrl)
        .model('llama3.2')
        .temperature(0.7)
        .maxTokens(100)
        .build();

    final response = await provider.chat([
      ChatMessage.user('Explain how GPU acceleration works in language models.')
    ]);

    print('   ⚡ High-performance response:');
    print('   ${response.text?.substring(0, 150)}...\n');
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
    // ElevenLabs with voice customization
    final audioProvider = await LLMBuilder()
        .elevenlabs((elevenlabs) => elevenlabs
            .voiceId('JBFqnCBsd6RMkjVDRZzb')
            .stability(0.75)
            .similarityBoost(0.8)
            .style(0.2)
            .useSpeakerBoost(true)
            .forHighQuality()) // Convenience method
        .apiKey(apiKey)
        .buildAudio();

    // Generate speech
    final audioData = await audioProvider.speech(
        'Welcome to the new provider-specific builder pattern in LLM Dart!');

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
    // OpenRouter with audited online-search intent
    final provider = await LLMBuilder()
        .openRouter((openrouter) => openrouter.onlineSearch())
        .apiKey(apiKey)
        .model('anthropic/claude-3.5-sonnet')
        .temperature(0.3)
        .maxTokens(150)
        .build();

    final response = await provider.chat([
      ChatMessage.user(
          'What are the latest developments in large language models?')
    ]);

    print('   🔍 Web-enhanced response:');
    print('   ${response.text?.substring(0, 200)}...\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Demonstrate mixed configurations and backward compatibility
Future<void> demoMixedConfigurations() async {
  print('🔄 Mixed Configurations & Backward Compatibility');
  print('=' * 50);

  // Show that providers work without callback configuration (backward compatible)
  print('   ✅ Backward compatibility - no callbacks:');
  final simpleBuilder = LLMBuilder()
      .openai()
      .anthropic()
      .ollama()
      .elevenlabs()
      .openRouter();
  print('      Builder created successfully without provider-specific config');
  print('      Builder type: ${simpleBuilder.runtimeType}');

  // Show mixed configuration with both generic and provider-specific parameters
  print('   ✅ Mixed configuration:');
  final mixedBuilder = LLMBuilder()
      .openai((openai) => openai.seed(42).parallelToolCalls(false))
      .apiKey('test-key')
      .model('gpt-4')
      .temperature(0.8)
      .maxTokens(500)
      .systemPrompt('You are a helpful assistant')
      .timeout(Duration(seconds: 30));
  print('      Mixed generic + provider-specific config successful');
  print('      Builder configured with model: gpt-4, temperature: 0.8');
  print('      Builder type: ${mixedBuilder.runtimeType}');

  print('');
}
