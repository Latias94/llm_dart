// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/legacy.dart';

/// 📋 Model Listing - Explore Available Models
///
/// This example demonstrates how to discover and explore available models
/// from AI providers using the ModelListingCapability interface:
/// - List all available models from providers
/// - Filter models by type and capability
/// - Inspect model metadata and ownership
/// - Select appropriate models for specific tasks
///
/// Before running, set your API keys:
/// export OPENAI_API_KEY="your-key"
/// export ANTHROPIC_API_KEY="your-key"
/// export OLLAMA_BASE_URL="http://localhost:11434" (if using Ollama)
void main() async {
  print('📋 Model Listing - Explore Available Models\n');

  // Create providers that support model listing
  final providers = await createModelListingProviders();

  // Demonstrate model listing features
  await demonstrateBasicModelListing(providers);
  await demonstrateModelFiltering(providers);
  await demonstrateModelMetadata(providers);
  await demonstrateModelSelection(providers);

  print('\n✅ Model listing completed!');
}

/// Create providers that support model listing
Future<Map<String, ModelListingCapability>>
    createModelListingProviders() async {
  final providers = <String, ModelListingCapability>{};

  // OpenAI provider (supports model listing)
  final openaiKey = Platform.environment['OPENAI_API_KEY'];
  if (openaiKey != null) {
    try {
      final openai = await ai()
          .openai()
          .apiKey(openaiKey)
          .model('gpt-4o-mini')
          .buildModelListing();

      if (openai is ProviderCapabilities &&
          (openai as ProviderCapabilities)
              .supports(LLMCapability.modelListing)) {
        providers['OpenAI'] = openai;
      }
    } catch (e) {
      print('⚠️  Failed to create OpenAI provider: $e');
    }
  }

  // Anthropic provider (supports model listing)
  final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (anthropicKey != null) {
    try {
      final anthropic = await ai()
          .anthropic()
          .apiKey(anthropicKey)
          .model('claude-3-5-haiku-20241022')
          .buildModelListing();

      if (anthropic is ProviderCapabilities &&
          (anthropic as ProviderCapabilities)
              .supports(LLMCapability.modelListing)) {
        providers['Anthropic'] = anthropic;
      }
    } catch (e) {
      print('⚠️  Failed to create Anthropic provider: $e');
    }
  }

  // Ollama provider (supports model listing)
  final ollamaUrl =
      Platform.environment['OLLAMA_BASE_URL'] ?? 'http://localhost:11434';
  try {
    final ollama = await ai()
        .ollama()
        .baseUrl(ollamaUrl)
        .model('llama3.2')
        .buildModelListing();

    if (ollama is ProviderCapabilities &&
        (ollama as ProviderCapabilities).supports(LLMCapability.modelListing)) {
      providers['Ollama'] = ollama;
    }
  } catch (e) {
    print('⚠️  Failed to create Ollama provider: $e');
  }

  if (providers.isEmpty) {
    print('❌ No providers with model listing capability available.');
    print(
        '   Please set API keys for OpenAI, Anthropic, or start Ollama server.');
    exit(1);
  }

  print(
      '📋 Created ${providers.length} providers with model listing capability\n');
  return providers;
}

/// Demonstrate basic model listing
Future<void> demonstrateBasicModelListing(
    Map<String, ModelListingCapability> providers) async {
  print('📝 Basic Model Listing:\n');

  for (final entry in providers.entries) {
    final providerName = entry.key;
    final provider = entry.value;

    print('   🤖 $providerName Models:');

    try {
      final models = await provider.models();

      if (models.isEmpty) {
        print('      ❌ No models available');
        continue;
      }

      print('      📊 Found ${models.length} models:');

      // Show first 5 models as preview
      final previewModels = models.take(5).toList();
      for (final model in previewModels) {
        final owner = model.ownedBy != null ? ' (${model.ownedBy})' : '';
        print('         • ${model.id}$owner');
      }

      if (models.length > 5) {
        print('         ... and ${models.length - 5} more models');
      }
    } catch (e) {
      print('      ❌ Failed to list models: $e');
    }

    print('');
  }
}

/// Demonstrate model filtering by type and capability
Future<void> demonstrateModelFiltering(
    Map<String, ModelListingCapability> providers) async {
  print('🔍 Model Filtering:\n');

  for (final entry in providers.entries) {
    final providerName = entry.key;
    final provider = entry.value;

    print('   🎯 $providerName Model Categories:');

    try {
      final allModels = await provider.models();

      if (allModels.isEmpty) {
        print('      ❌ No models to filter');
        continue;
      }

      // Filter chat models
      final chatModels = allModels
          .where((model) =>
              model.id.toLowerCase().contains('gpt') ||
              model.id.toLowerCase().contains('claude') ||
              model.id.toLowerCase().contains('chat') ||
              model.id.toLowerCase().contains('llama'))
          .toList();

      if (chatModels.isNotEmpty) {
        print('      💬 Chat Models (${chatModels.length}):');
        for (final model in chatModels.take(3)) {
          print('         • ${model.id}');
        }
        if (chatModels.length > 3) {
          print('         ... and ${chatModels.length - 3} more');
        }
      }

      // Filter embedding models
      final embeddingModels = allModels
          .where((model) =>
              model.id.toLowerCase().contains('embedding') ||
              model.id.toLowerCase().contains('ada'))
          .toList();

      if (embeddingModels.isNotEmpty) {
        print('      🔢 Embedding Models (${embeddingModels.length}):');
        for (final model in embeddingModels.take(3)) {
          print('         • ${model.id}');
        }
        if (embeddingModels.length > 3) {
          print('         ... and ${embeddingModels.length - 3} more');
        }
      }

      // Filter image models
      final imageModels = allModels
          .where((model) =>
              model.id.toLowerCase().contains('dall-e') ||
              model.id.toLowerCase().contains('dalle') ||
              model.id.toLowerCase().contains('imagen'))
          .toList();

      if (imageModels.isNotEmpty) {
        print('      🎨 Image Models (${imageModels.length}):');
        for (final model in imageModels) {
          print('         • ${model.id}');
        }
      }

      // Filter audio models
      final audioModels = allModels
          .where((model) =>
              model.id.toLowerCase().contains('whisper') ||
              model.id.toLowerCase().contains('tts'))
          .toList();

      if (audioModels.isNotEmpty) {
        print('      🎵 Audio Models (${audioModels.length}):');
        for (final model in audioModels) {
          print('         • ${model.id}');
        }
      }

      // Filter reasoning models
      final reasoningModels = allModels
          .where((model) =>
              model.id.toLowerCase().contains('o1') ||
              model.id.toLowerCase().contains('reasoning') ||
              model.id.toLowerCase().contains('thinking'))
          .toList();

      if (reasoningModels.isNotEmpty) {
        print('      🧠 Reasoning Models (${reasoningModels.length}):');
        for (final model in reasoningModels) {
          print('         • ${model.id}');
        }
      }
    } catch (e) {
      print('      ❌ Failed to filter models: $e');
    }

    print('');
  }
}

/// Demonstrate model metadata inspection
Future<void> demonstrateModelMetadata(
    Map<String, ModelListingCapability> providers) async {
  print('📊 Model Metadata Inspection:\n');

  for (final entry in providers.entries) {
    final providerName = entry.key;
    final provider = entry.value;

    print('   🔍 $providerName Model Details:');

    try {
      final models = await provider.models();

      if (models.isEmpty) {
        print('      ❌ No models to inspect');
        continue;
      }

      // Group models by owner
      final modelsByOwner = <String, List<AIModel>>{};
      for (final model in models) {
        final owner = model.ownedBy ?? 'unknown';
        modelsByOwner.putIfAbsent(owner, () => []).add(model);
      }

      print('      👥 Models by Owner:');
      for (final ownerEntry in modelsByOwner.entries) {
        final owner = ownerEntry.key;
        final ownerModels = ownerEntry.value;
        print('         • $owner: ${ownerModels.length} models');
      }

      // Show detailed info for a few models
      print('\n      📋 Sample Model Details:');
      final sampleModels = models.take(3).toList();
      for (final model in sampleModels) {
        print('         Model: ${model.id}');
        print('           • Object: ${model.object}');
        if (model.description != null) {
          print('           • Description: ${model.description}');
        }
        if (model.ownedBy != null) {
          print('           • Owner: ${model.ownedBy}');
        }
        print('');
      }
    } catch (e) {
      print('      ❌ Failed to inspect metadata: $e');
    }

    print('');
  }
}

/// Demonstrate model selection for specific tasks
Future<void> demonstrateModelSelection(
    Map<String, ModelListingCapability> providers) async {
  print('🎯 Model Selection for Tasks:\n');

  for (final entry in providers.entries) {
    final providerName = entry.key;
    final provider = entry.value;

    print('   🎪 $providerName Model Recommendations:');

    try {
      final models = await provider.models();

      if (models.isEmpty) {
        print('      ❌ No models available for selection');
        continue;
      }

      // Task 1: General chat
      print('      💬 For General Chat:');
      final chatModel = models.firstWhere(
        (model) =>
            model.id.toLowerCase().contains('gpt-4') ||
            model.id.toLowerCase().contains('claude-3') ||
            model.id.toLowerCase().contains('llama'),
        orElse: () => models.first,
      );
      print('         Recommended: ${chatModel.id}');

      // Task 2: Fast responses
      print('      ⚡ For Fast Responses:');
      final fastModel = models.firstWhere(
        (model) =>
            model.id.toLowerCase().contains('mini') ||
            model.id.toLowerCase().contains('instant') ||
            model.id.toLowerCase().contains('turbo'),
        orElse: () => models.first,
      );
      print('         Recommended: ${fastModel.id}');

      // Task 3: Complex reasoning
      print('      🧠 For Complex Reasoning:');
      final reasoningModel = models.firstWhere(
        (model) =>
            model.id.toLowerCase().contains('o1') ||
            model.id.toLowerCase().contains('reasoning') ||
            model.id.toLowerCase().contains('pro'),
        orElse: () => models.first,
      );
      print('         Recommended: ${reasoningModel.id}');

      // Task 4: Cost-effective
      print('      💰 For Cost-Effective Usage:');
      final costEffectiveModel = models.firstWhere(
        (model) =>
            model.id.toLowerCase().contains('mini') ||
            model.id.toLowerCase().contains('3.5') ||
            model.id.toLowerCase().contains('haiku'),
        orElse: () => models.first,
      );
      print('         Recommended: ${costEffectiveModel.id}');
    } catch (e) {
      print('      ❌ Failed to recommend models: $e');
    }

    print('');
  }

  print('   💡 Model Selection Tips:');
  print('      • Choose models based on your specific use case');
  print('      • Consider cost vs. performance trade-offs');
  print('      • Test different models for your specific tasks');
  print('      • Monitor model performance and costs in production');
  print('      • Stay updated with new model releases');
  print('');
}

/// 🎯 Key Model Listing Concepts Summary:
///
/// ModelListingCapability Interface:
/// - models(): Get list of available models from provider
///
/// AIModel Class Properties:
/// - id: Unique model identifier
/// - description: Human-readable model description
/// - object: Object type (typically "model")
/// - ownedBy: Organization that owns the model
///
/// Model Categories:
/// - Chat Models: For conversational AI (GPT, Claude, LLaMA)
/// - Embedding Models: For vector representations (text-embedding-ada)
/// - Image Models: For image generation (DALL-E, Imagen)
/// - Audio Models: For speech processing (Whisper, TTS)
/// - Reasoning Models: For complex thinking (GPT-4o1, Claude-3-Opus)
///
/// Best Practices:
/// 1. List models to discover available options
/// 2. Filter models by capability and use case
/// 3. Consider cost and performance characteristics
/// 4. Test models with your specific data
/// 5. Monitor model availability and deprecation
///
/// Next Steps:
/// - error_handling.dart: Handle model-related errors
/// - Provider-specific examples for model details
/// - Performance benchmarking across models
