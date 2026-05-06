import 'dart:io';

import 'package:llm_dart/builder/llm_builder.dart';
import 'package:llm_dart/models/audio_models.dart';

/// Compatibility builder methods for provider capability families.
///
/// These helpers provide stronger typing than `build()` plus manual casts when
/// you still need the older root builder surface:
/// - buildAudio() - Returns AudioCapability directly
/// - buildImageGeneration() - Returns ImageGenerationCapability directly
/// - buildEmbedding() - Returns EmbeddingCapability directly
/// - buildFileManagement() - Returns FileManagementCapability directly
/// - buildModeration() - Returns ModerationCapability directly
/// - buildAssistant() - Returns AssistantCapability directly
/// - buildModelListing() - Returns ModelListingCapability directly
///
/// This is not the new primary app architecture.
///
/// For new app-facing code, prefer the stable facade when it exists:
/// - `AI.*(...).chatModel(...)`
/// - `AI.*(...).embeddingModel(...)`
/// - `AI.*(...).imageModel(...)`
/// - `AI.*(...).speechModel(...)`
/// - `AI.*(...).transcriptionModel(...)`
///
/// Keep `build*()` mainly for migration and for capability families that still
/// remain provider-owned on the root package.
///
/// Benefits inside the compatibility layer:
/// - Compile-time type safety
/// - No runtime type casting needed
/// - Clear error messages for unsupported capabilities
/// - Cleaner, more readable code
///
/// Before running, set your API keys:
/// export OPENAI_API_KEY="your-key"
/// export ELEVENLABS_API_KEY="your-key"
void main() async {
  print('Compatibility Builder Methods for Provider Capabilities\n');

  // Position these helpers relative to the stable facade.
  demonstrateStableFirstPositioning();

  // Compare raw build() + cast with typed compatibility builders.
  await demonstrateCastVsCompatibilityBuild();

  // Show typed compatibility capability building.
  await demonstrateTypedCompatibilityBuilding();

  // Show error handling for unsupported capabilities.
  await demonstrateErrorHandling();

  // Show practical migration usage examples.
  await demonstratePracticalUsage();

  print('\nCompatibility builder demo completed.');
  print('Use the stable AI facade first when a stable model factory exists.');
}

void demonstrateStableFirstPositioning() {
  print('Stable-first positioning:\n');

  print('   New app code should usually start here:');
  print('   ```dart');
  print(
      "   final chatModel = AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');");
  print(
      "   final embeddingModel = AI.openai(apiKey: apiKey).embeddingModel('text-embedding-3-small');");
  print(
      "   final imageModel = AI.openai(apiKey: apiKey).imageModel('dall-e-3');");
  print('   ```');
  print('');

  print(
      '   Use `build*()` mainly when you still need the root builder surface:');
  print('      • migration from `build()` plus runtime casts');
  print('      • provider-owned capability families');
  print('      • typed access before a stable shared facade exists');
  print('');
}

/// Compare raw build() + cast against typed compatibility builders.
Future<void> demonstrateCastVsCompatibilityBuild() async {
  print('Raw build() + cast vs typed compatibility builders:\n');

  // final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';

  print('   Raw compatibility approach (runtime type casting):');
  print('   ```dart');
  print(
      '   final provider = await LLMBuilder().openai().apiKey(apiKey).build();');
  print('   if (provider is! AudioCapability) {');
  print('     throw Exception("Not supported");');
  print('   }');
  print(
      '   final audioProvider = provider as AudioCapability; // Runtime cast!');
  print('   final voices = await audioProvider.getVoices();');
  print('   ```');
  print('');

  print('   Typed compatibility approach:');
  print('   ```dart');
  print(
      '   final audioProvider = await LLMBuilder().openai().apiKey(apiKey).buildAudio();');
  print('   final voices = await audioProvider.getVoices(); // Direct usage!');
  print('   ```');
  print('');

  print('   Stable-first reminder:');
  print('      • Prefer `AI.*(...)` model factories for new app-facing code');
  print(
      '      • Use `build*()` when you are still on the compatibility surface');
  print(
      '      • Keep provider-specific lifecycle APIs behind clear boundaries');
  print('');
}

/// Demonstrate typed compatibility capability building.
Future<void> demonstrateTypedCompatibilityBuilding() async {
  print('Typed compatibility builder examples:\n');

  final openaiKey = Platform.environment['OPENAI_API_KEY'];
  final elevenlabsKey = Platform.environment['ELEVENLABS_API_KEY'];

  if (openaiKey != null) {
    print('   OpenAI compatibility builders:');

    try {
      // Audio capability
      print('      Building audio capability...');
      final audioProvider =
          await LLMBuilder().openai().apiKey(openaiKey).buildAudio();

      print('         Audio provider built successfully');
      print('         Type: ${audioProvider.runtimeType}');

      // Test audio functionality
      final voices = await audioProvider.getVoices();
      print('         Available voices: ${voices.length} voices');

      // Image generation capability
      print('      Building image generation capability...');
      final imageProvider = await LLMBuilder()
          .openai()
          .apiKey(openaiKey)
          .model('dall-e-3')
          .buildImageGeneration();

      print('         Image generation provider built successfully');
      print('         Type: ${imageProvider.runtimeType}');

      // Test image generation functionality
      final formats = imageProvider.getSupportedFormats();
      print('         Supported formats: ${formats.join(', ')}');

      // Embedding capability
      print('      Building embedding capability...');
      final embeddingProvider = await LLMBuilder()
          .openai()
          .apiKey(openaiKey)
          .model('text-embedding-3-small')
          .buildEmbedding();

      print('         Embedding provider built successfully');
      print('         Type: ${embeddingProvider.runtimeType}');

      // Test embedding functionality
      final embeddings = await embeddingProvider.embed(['Hello world']);
      print('         Generated embeddings: ${embeddings.length} vectors');

      // Model listing capability
      print('      Building model listing capability...');
      final modelProvider =
          await LLMBuilder().openai().apiKey(openaiKey).buildModelListing();

      print('         Model listing provider built successfully');
      print('         Type: ${modelProvider.runtimeType}');

      // Test model listing functionality
      final models = await modelProvider.models();
      print('         Available models: ${models.length} models');
    } catch (e) {
      print('      OpenAI capability building failed: $e');
    }
    print('');
  }

  if (elevenlabsKey != null) {
    print('   ElevenLabs compatibility builders:');

    try {
      // Audio capability (ElevenLabs specializes in audio)
      print('      Building audio capability...');
      final audioProvider = await LLMBuilder()
          .elevenlabs(
              (elevenlabs) => elevenlabs.voiceId('JBFqnCBsd6RMkjVDRZzb'))
          .apiKey(elevenlabsKey)
          .buildAudio();

      print('         Audio provider built successfully');
      print('         Type: ${audioProvider.runtimeType}');

      // Test audio functionality
      final voices = await audioProvider.getVoices();
      print('         Available voices: ${voices.length} voices');
      if (voices.isNotEmpty) {
        print(
            '         Sample voices: ${voices.take(3).map((v) => v.name).join(', ')}');
      }
    } catch (e) {
      print('      ElevenLabs capability building failed: $e');
    }
    print('');
  }

  if (openaiKey == null && elevenlabsKey == null) {
    print('   No API keys available for demonstration.');
    print('   Set OPENAI_API_KEY or ELEVENLABS_API_KEY to see live examples.');
    print('');
  }
}

/// Demonstrate error handling for unsupported capabilities
Future<void> demonstrateErrorHandling() async {
  print('Error handling for unsupported capabilities:\n');

  final elevenlabsKey = Platform.environment['ELEVENLABS_API_KEY'];

  if (elevenlabsKey != null) {
    print('   Testing unsupported capabilities with ElevenLabs:');

    // Try to build image generation with ElevenLabs (should fail)
    try {
      print('      Attempting to build image generation...');
      await LLMBuilder()
          .elevenlabs()
          .apiKey(elevenlabsKey)
          .buildImageGeneration();

      print('         This should not succeed.');
    } catch (e) {
      print('         Correctly caught error: ${e.runtimeType}');
      print('         Error message: $e');
    }

    // Try to build embedding with ElevenLabs (should fail)
    try {
      print('      Attempting to build embedding...');
      await LLMBuilder().elevenlabs().apiKey(elevenlabsKey).buildEmbedding();

      print('         This should not succeed.');
    } catch (e) {
      print('         Correctly caught error: ${e.runtimeType}');
      print('         Error message: $e');
    }

    print('');
  } else {
    print('   Set ELEVENLABS_API_KEY to see error handling examples.');
    print('');
  }
}

/// Demonstrate practical usage examples
Future<void> demonstratePracticalUsage() async {
  print('Practical migration usage examples:\n');

  final openaiKey = Platform.environment['OPENAI_API_KEY'];

  if (openaiKey != null) {
    print('   Real-world compatibility patterns:');

    // Example 1: Audio processing pipeline
    print('      Audio processing pipeline:');
    try {
      final audioProvider =
          await LLMBuilder().openai().apiKey(openaiKey).buildAudio();

      // Direct usage without type casting
      final ttsResponse = await audioProvider.textToSpeech(TTSRequest(
        text: 'Hello from the typed compatibility builder methods!',
        voice: 'alloy',
        format: 'mp3',
      ));

      print('         Generated speech: ${ttsResponse.audioData.length} bytes');
    } catch (e) {
      print('         Audio processing failed: $e');
    }

    // Example 2: Embedding similarity search
    print('      Embedding similarity search:');
    try {
      final embeddingProvider = await LLMBuilder()
          .openai()
          .apiKey(openaiKey)
          .model('text-embedding-3-small')
          .buildEmbedding();

      // Direct usage without type casting
      final embeddings = await embeddingProvider.embed([
        'The typed compatibility builder methods are helpful',
        'Type safety is important in software development',
        'Cats are cute animals',
      ]);

      print('         Generated ${embeddings.length} embeddings');
      print('         Vector dimensions: ${embeddings.first.length}');
    } catch (e) {
      print('         Embedding generation failed: $e');
    }

    // Example 3: Model discovery
    print('      Model discovery:');
    try {
      final modelProvider =
          await LLMBuilder().openai().apiKey(openaiKey).buildModelListing();

      // Direct usage without type casting
      final models = await modelProvider.models();
      final gptModels = models.where((m) => m.id.contains('gpt')).toList();

      print('         Found ${models.length} total models');
      print('         GPT models: ${gptModels.length}');
      if (gptModels.isNotEmpty) {
        print(
            '         Sample: ${gptModels.take(3).map((m) => m.id).join(', ')}');
      }
    } catch (e) {
      print('         Model listing failed: $e');
    }

    print('');
  } else {
    print('   Set OPENAI_API_KEY to see practical usage examples.');
    print('');
  }

  print('   What this example demonstrates:');
  print('      • better typing inside the legacy root builder surface');
  print('      • safer migration than raw `build()` plus runtime casts');
  print('      • clearer boundaries between stable and compatibility APIs');
}
