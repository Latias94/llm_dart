import 'dart:io';

import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/models.dart';

/// 🏭 Capability Factory Methods - Type-Safe Provider Building
///
/// This example demonstrates the new capability factory methods that provide
/// type-safe access to specific provider capabilities at build time:
/// - buildSpeech() - Returns TextToSpeechCapability directly
/// - buildStreamingSpeech() - Returns StreamingTextToSpeechCapability directly
/// - buildTranscription() - Returns SpeechToTextCapability directly
/// - buildAudioTranslation() - Returns AudioTranslationCapability directly
/// - buildRealtimeAudio() - Returns RealtimeAudioCapability directly
/// - buildImageGeneration() - Returns ImageGenerationCapability directly
/// - buildEmbedding() - Returns EmbeddingCapability directly
///
/// Benefits:
/// - Compile-time type safety
/// - No runtime type casting needed
/// - Clear error messages for unsupported capabilities
/// - Cleaner, more readable code
///
/// Before running, set your API keys:
/// export OPENAI_API_KEY="your-key"
/// export ELEVENLABS_API_KEY="your-key"
void main() async {
  print('🏭 Capability Factory Methods - Type-Safe Provider Building\n');

  registerOpenAI();
  registerElevenLabs();

  // Demonstrate old vs new approach
  await demonstrateOldVsNewApproach();

  // Show type-safe capability building
  await demonstrateTypeSafeBuilding();

  // Show error handling for unsupported capabilities
  await demonstrateErrorHandling();

  // Show practical usage examples
  await demonstratePracticalUsage();

  print('\n✅ Capability factory methods demo completed!');
  print('📖 This approach provides compile-time type safety and cleaner code');
}

/// Demonstrate old vs new approach
Future<void> demonstrateOldVsNewApproach() async {
  print('🔄 Old vs New Approach Comparison:\n');

  // final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';

  print('   🚨 OLD APPROACH (runtime type casting):');
  print('   ```dart');
  print(
      '   final provider = await LLMBuilder().provider(openaiProviderId).apiKey(apiKey).build();');
  print('   if (provider is! TextToSpeechCapability) {');
  print('     throw Exception("Not supported");');
  print('   }');
  print('   final tts = provider as TextToSpeechCapability; // Runtime cast!');
  print('   final audio = await tts.textToSpeech(TTSRequest(text: "Hi"));');
  print('   ```');
  print('');

  print('   ✅ NEW APPROACH (compile-time type safety):');
  print('   ```dart');
  print(
      '   final tts = await LLMBuilder().provider(openaiProviderId).apiKey(apiKey).buildSpeech();');
  print('   final audio = await tts.textToSpeech(TTSRequest(text: "Hi"));');
  print('   ```');
  print('');

  print('   💡 Benefits of new approach:');
  print('      • Compile-time type checking');
  print('      • No runtime type casting');
  print('      • Clear error messages');
  print('      • Better IDE support and autocomplete');
  print('      • Cleaner, more readable code');
  print('');
}

/// Demonstrate type-safe capability building
Future<void> demonstrateTypeSafeBuilding() async {
  print('🔒 Type-Safe Capability Building:\n');

  final openaiKey = Platform.environment['OPENAI_API_KEY'];
  final elevenlabsKey = Platform.environment['ELEVENLABS_API_KEY'];

  if (openaiKey != null) {
    print('   🤖 OpenAI Provider Capabilities:');

    try {
      // Speech (TTS) capability
      print('      🎵 Building speech (TTS) capability...');
      final audioProvider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(openaiKey)
          .buildSpeech();

      print('         ✅ Speech provider built successfully');
      print('         Type: ${audioProvider.runtimeType}');

      // Test TTS functionality (minimal smoke check)
      final ttsResponse = await audioProvider.textToSpeech(
        const TTSRequest(text: 'Hello from LLM Dart'),
      );
      print(
          '         🔊 Generated audio: ${ttsResponse.audioData.length} bytes');

      // Image generation capability
      print('      🖼️  Building image generation capability...');
      final imageProvider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(openaiKey)
          .model('dall-e-3')
          .buildImageGeneration();

      print('         ✅ Image generation provider built successfully');
      print('         Type: ${imageProvider.runtimeType}');

      // Test image generation functionality
      final formats = imageProvider.getSupportedFormats();
      print('         🎨 Supported formats: ${formats.join(', ')}');

      // Embedding capability
      print('      📊 Building embedding capability...');
      final embeddingProvider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(openaiKey)
          .model('text-embedding-3-small')
          .buildEmbedding();

      print('         ✅ Embedding provider built successfully');
      print('         Type: ${embeddingProvider.runtimeType}');

      // Test embedding functionality
      final embeddingResponse = await embeddingProvider.embed(['Hello world']);
      print(
          '         🔢 Generated embeddings: ${embeddingResponse.embeddings.length} vectors');

      // Model listing is provider-specific (Vercel-style: not part of standard surface)
      print('      📋 Building provider (for model discovery)...');
      final provider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(openaiKey)
          .build();

      final openai = provider as OpenAIProvider;
      print('         ✅ OpenAI provider built successfully');
      print('         Type: ${openai.runtimeType}');

      // Test model listing functionality
      final modelsApi =
          OpenAIModels(OpenAIClient(openai.config), openai.config);
      final models = await modelsApi.models();
      print('         🤖 Available models: ${models.length} models');
    } catch (e) {
      print('      ❌ OpenAI capability building failed: $e');
    }
    print('');
  }

  if (elevenlabsKey != null) {
    print('   🎙️ ElevenLabs Provider Capabilities:');

    try {
      // Speech (TTS) capability (ElevenLabs specializes in TTS)
      print('      🎵 Building speech (TTS) capability...');
      final ttsProvider = await LLMBuilder()
          .provider(elevenLabsProviderId)
          .apiKey(elevenlabsKey)
          .providerOption('elevenlabs', 'voiceId', 'JBFqnCBsd6RMkjVDRZzb')
          .buildSpeech();

      print('         ✅ Speech provider built successfully');
      print('         Type: ${ttsProvider.runtimeType}');

      // Voice listing is provider-specific; check opt-in capability.
      if (ttsProvider is VoiceListingCapability) {
        final voices =
            await (ttsProvider as VoiceListingCapability).getVoices();
        print('         🎭 Available voices: ${voices.length} voices');
        if (voices.isNotEmpty) {
          print(
              '         Sample voices: ${voices.take(3).map((v) => v.name).join(', ')}');
        }
      } else {
        print('         🎭 Voice listing not supported by this provider');
      }
    } catch (e) {
      print('      ❌ ElevenLabs capability building failed: $e');
    }
    print('');
  }

  if (openaiKey == null && elevenlabsKey == null) {
    print('   ⚠️  No API keys available for demonstration');
    print('   Set OPENAI_API_KEY or ELEVENLABS_API_KEY to see live examples');
    print('');
  }
}

/// Demonstrate error handling for unsupported capabilities
Future<void> demonstrateErrorHandling() async {
  print('⚠️  Error Handling for Unsupported Capabilities:\n');

  final elevenlabsKey = Platform.environment['ELEVENLABS_API_KEY'];

  if (elevenlabsKey != null) {
    print('   🧪 Testing unsupported capabilities with ElevenLabs:');

    // Try to build image generation with ElevenLabs (should fail)
    try {
      print('      🖼️  Attempting to build image generation...');
      await LLMBuilder()
          .provider(elevenLabsProviderId)
          .apiKey(elevenlabsKey)
          .buildImageGeneration();

      print('         ❌ This should not succeed!');
    } catch (e) {
      print('         ✅ Correctly caught error: ${e.runtimeType}');
      print('         📝 Error message: $e');
    }

    // Try to build embedding with ElevenLabs (should fail)
    try {
      print('      📊 Attempting to build embedding...');
      await LLMBuilder()
          .provider(elevenLabsProviderId)
          .apiKey(elevenlabsKey)
          .buildEmbedding();

      print('         ❌ This should not succeed!');
    } catch (e) {
      print('         ✅ Correctly caught error: ${e.runtimeType}');
      print('         📝 Error message: $e');
    }

    print('');
  } else {
    print('   ⚠️  Set ELEVENLABS_API_KEY to see error handling examples');
    print('');
  }
}

/// Demonstrate practical usage examples
Future<void> demonstratePracticalUsage() async {
  print('🚀 Practical Usage Examples:\n');

  final openaiKey = Platform.environment['OPENAI_API_KEY'];

  if (openaiKey != null) {
    print('   💼 Real-world usage patterns:');

    // Example 1: Audio processing pipeline
    print('      🎵 Audio Processing Pipeline:');
    try {
      final ttsProvider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(openaiKey)
          .buildSpeech();

      // Direct usage without type casting
      final ttsResponse = await ttsProvider.textToSpeech(TTSRequest(
        text: 'Hello from the new capability factory methods!',
        voice: 'alloy',
        format: 'mp3',
      ));

      print(
          '         ✅ Generated speech: ${ttsResponse.audioData.length} bytes');
    } catch (e) {
      print('         ❌ Audio processing failed: $e');
    }

    // Example 2: Embedding similarity search
    print('      📊 Embedding Similarity Search:');
    try {
      final embeddingProvider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(openaiKey)
          .model('text-embedding-3-small')
          .buildEmbedding();

      // Direct usage without type casting
      final embeddingResponse = await embeddingProvider.embed([
        'The new capability factory methods are great',
        'Type safety is important in software development',
        'Cats are cute animals',
      ]);

      print(
          '         ✅ Generated ${embeddingResponse.embeddings.length} embeddings');
      print(
          '         📏 Vector dimensions: ${embeddingResponse.embeddings.first.length}');
    } catch (e) {
      print('         ❌ Embedding generation failed: $e');
    }

    // Example 3: Model discovery (provider-specific)
    print('      🔍 Model Discovery:');
    try {
      final provider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(openaiKey)
          .build();

      final openai = provider as OpenAIProvider;
      final modelsApi =
          OpenAIModels(OpenAIClient(openai.config), openai.config);
      final models = await modelsApi.models();
      final gptModels = models.where((m) => m.id.contains('gpt')).toList();

      print('         ✅ Found ${models.length} total models');
      print('         🤖 GPT models: ${gptModels.length}');
      if (gptModels.isNotEmpty) {
        print(
            '         Sample: ${gptModels.take(3).map((m) => m.id).join(', ')}');
      }
    } catch (e) {
      print('         ❌ Model listing failed: $e');
    }

    print('');
  } else {
    print('   ⚠️  Set OPENAI_API_KEY to see practical usage examples');
    print('');
  }

  print('   💡 Key Benefits Demonstrated:');
  print('      • 标准任务无需 type casting');
  print('      • Provider-specific API 需要显式 cast');
  print('      • Compile-time type safety');
  print('      • Clear error messages for unsupported capabilities');
  print('      • Cleaner, more maintainable code');
  print('      • Better IDE support and autocomplete');
}
