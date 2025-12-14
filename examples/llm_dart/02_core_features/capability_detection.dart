// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 🔍 Capability Detection - Discover Provider Features
///
/// This example demonstrates how to detect and compare capabilities across
/// different AI providers using the ProviderCapabilities interface:
/// - Check what features a provider supports
/// - Compare capabilities across multiple providers
/// - Make informed provider selection decisions
/// - Understand capability limitations and variations
///
/// **Important Notes:**
///
/// 1. **Informational Purpose**: Capability detection is primarily for provider
///    selection and documentation, not strict runtime validation.
///
/// 2. **Model Variations**: Actual support may vary by specific model within
///    the same provider (e.g., GPT-4 vs GPT-3.5, Claude Sonnet vs Haiku).
///
/// 3. **Runtime Detection**: Some features (like reasoning output) are detected
///    at runtime through response parsing rather than capability declarations.
///
/// 4. **OpenAI-Compatible Providers**: Providers using OpenAI-compatible APIs
///    may have different capabilities than declared.
///
/// **Best Practices:**
/// - Use capability checks for provider selection
/// - Always implement graceful error handling
/// - Test critical features with actual API calls
/// - Don't rely solely on capability declarations for runtime validation
///
/// Before running, set your API keys:
/// export OPENAI_API_KEY="your-key"
/// export ANTHROPIC_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main() async {
  print('🔍 Capability Detection - Discover Provider Features\n');

  // Create multiple providers for comparison
  final providers = await createProviders();

  // Demonstrate capability detection
  await demonstrateBasicCapabilityCheck(providers);
  await demonstrateCapabilityComparison(providers);
  await demonstrateFeatureBasedSelection(providers);
  await demonstrateCapabilityValidation(providers);

  print('\n✅ Capability detection completed!');
}

/// Create multiple providers for capability comparison
Future<Map<String, ProviderCapabilities>> createProviders() async {
  final providers = <String, ProviderCapabilities>{};

  // OpenAI provider (standard)
  final openaiKey = Platform.environment['OPENAI_API_KEY'];
  if (openaiKey != null) {
    try {
      final openai =
          await ai().openai().apiKey(openaiKey).model('gpt-4o-mini').build();
      if (openai is ProviderCapabilities) {
        providers['OpenAI Standard'] = openai as ProviderCapabilities;
      }
    } catch (e) {
      print('⚠️  Failed to create OpenAI provider: $e');
    }

    // OpenAI provider with Responses API (manual configuration)
    try {
      final openaiResponses = await ai()
          .openai((openai) => openai.useResponsesAPI().webSearchTool())
          .apiKey(openaiKey)
          .model('gpt-4o')
          .build();
      if (openaiResponses is ProviderCapabilities) {
        providers['OpenAI Responses (Manual)'] =
            openaiResponses as ProviderCapabilities;
      }
    } catch (e) {
      print('⚠️  Failed to create OpenAI Responses provider: $e');
    }

    // OpenAI provider with Responses API (using buildOpenAIResponses)
    try {
      final openaiResponsesAuto = await ai()
          .openai((openai) => openai.webSearchTool())
          .apiKey(openaiKey)
          .model('gpt-4o')
          .buildOpenAIResponses();
      providers['OpenAI Responses (Auto)'] = openaiResponsesAuto;
    } catch (e) {
      print('⚠️  Failed to create OpenAI Responses auto provider: $e');
    }
  }

  // Anthropic provider
  final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (anthropicKey != null) {
    try {
      final anthropic = await ai()
          .anthropic()
          .apiKey(anthropicKey)
          .model('claude-3-5-haiku-20241022')
          .build();
      if (anthropic is ProviderCapabilities) {
        providers['Anthropic'] = anthropic as ProviderCapabilities;
      }
    } catch (e) {
      print('⚠️  Failed to create Anthropic provider: $e');
    }
  }

  // Groq provider (speed-optimized)
  final groqKey = Platform.environment['GROQ_API_KEY'];
  if (groqKey != null) {
    try {
      final groq = await ai()
          .groq()
          .apiKey(groqKey)
          .model('llama-3.1-8b-instant')
          .build();
      if (groq is ProviderCapabilities) {
        providers['Groq'] = groq as ProviderCapabilities;
      }
    } catch (e) {
      print('⚠️  Failed to create Groq provider: $e');
    }
  }

  if (providers.isEmpty) {
    print('❌ No providers available. Please set at least one API key.');
    exit(1);
  }

  print('📋 Created ${providers.length} providers for comparison\n');
  return providers;
}

/// Demonstrate basic capability checking
Future<void> demonstrateBasicCapabilityCheck(
    Map<String, ProviderCapabilities> providers) async {
  print('🔤 Basic Capability Check:\n');

  for (final entry in providers.entries) {
    final providerName = entry.key;
    final provider = entry.value;

    print('   📊 $providerName Capabilities:');

    // Check core capabilities
    final coreCapabilities = [
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
      LLMCapability.vision,
      LLMCapability.reasoning,
    ];

    for (final capability in coreCapabilities) {
      final supported = provider.supports(capability);
      final icon = supported ? '✅' : '❌';
      print('      $icon ${capability.name}');
    }

    print(
        '      Total: ${provider.supportedCapabilities.length} capabilities\n');
  }
}

/// Demonstrate capability comparison across providers
Future<void> demonstrateCapabilityComparison(
    Map<String, ProviderCapabilities> providers) async {
  print('📊 Capability Comparison:\n');

  // Get all unique capabilities across providers
  final allCapabilities = <LLMCapability>{};
  for (final provider in providers.values) {
    allCapabilities.addAll(provider.supportedCapabilities);
  }

  // Create comparison table
  print('   Capability Comparison Table:');
  print(
      '   ${'Capability'.padRight(20)} | ${providers.keys.map((name) => name.padRight(12)).join(' | ')}');
  print('   ${'-' * 20} | ${providers.keys.map((_) => '-' * 12).join(' | ')}');

  for (final capability in allCapabilities) {
    final row = StringBuffer();
    row.write('   ${capability.name.padRight(20)} | ');

    final supportStatus = providers.values
        .map((provider) =>
            provider.supports(capability) ? '✅'.padRight(12) : '❌'.padRight(12))
        .join(' | ');
    row.write(supportStatus);

    print(row.toString());
  }

  print('\n   📈 Capability Statistics:');
  for (final entry in providers.entries) {
    final name = entry.key;
    final provider = entry.value;
    final percentage =
        (provider.supportedCapabilities.length / allCapabilities.length * 100)
            .round();
    print(
        '      • $name: ${provider.supportedCapabilities.length}/${allCapabilities.length} capabilities ($percentage%)');
  }
  print('');
}

/// Demonstrate feature-based provider selection
Future<void> demonstrateFeatureBasedSelection(
    Map<String, ProviderCapabilities> providers) async {
  print('🎯 Feature-Based Provider Selection:\n');

  // Scenario 1: Need vision capabilities
  print('   Scenario 1: Building a vision-enabled chatbot');
  final visionProviders = providers.entries
      .where((entry) => entry.value.supports(LLMCapability.vision))
      .map((entry) => entry.key)
      .toList();

  if (visionProviders.isNotEmpty) {
    print('      ✅ Recommended providers: ${visionProviders.join(', ')}');
  } else {
    print('      ❌ No providers support vision capabilities');
  }

  // Scenario 2: Need reasoning capabilities
  print('\n   Scenario 2: Building a reasoning/thinking application');
  final reasoningProviders = providers.entries
      .where((entry) => entry.value.supports(LLMCapability.reasoning))
      .map((entry) => entry.key)
      .toList();

  if (reasoningProviders.isNotEmpty) {
    print('      ✅ Recommended providers: ${reasoningProviders.join(', ')}');
  } else {
    print('      ❌ No providers support reasoning capabilities');
  }

  // Scenario 3: Need audio capabilities
  print('\n   Scenario 3: Building a voice assistant');
  final audioProviders = providers.entries
      .where((entry) =>
          entry.value.supports(LLMCapability.textToSpeech) ||
          entry.value.supports(LLMCapability.speechToText))
      .map((entry) => entry.key)
      .toList();

  if (audioProviders.isNotEmpty) {
    print('      ✅ Recommended providers: ${audioProviders.join(', ')}');
  } else {
    print('      ❌ No providers support audio capabilities');
  }

  // Scenario 4: Need image generation
  print('\n   Scenario 4: Building an image generation app');
  final imageProviders = providers.entries
      .where((entry) => entry.value.supports(LLMCapability.imageGeneration))
      .map((entry) => entry.key)
      .toList();

  if (imageProviders.isNotEmpty) {
    print('      ✅ Recommended providers: ${imageProviders.join(', ')}');
  } else {
    print('      ❌ No providers support image generation');
  }

  // Scenario 5: Need OpenAI Responses API features
  print(
      '\n   Scenario 5: Building stateful conversation app with advanced features');
  final responsesProviders = providers.entries
      .where((entry) => entry.value.supports(LLMCapability.openaiResponses))
      .map((entry) => entry.key)
      .toList();

  if (responsesProviders.isNotEmpty) {
    print('      ✅ Recommended providers: ${responsesProviders.join(', ')}');
    print(
        '      💡 Features: Stateful conversations, background processing, built-in tools');
  } else {
    print('      ❌ No providers support OpenAI Responses API');
    print(
        '      💡 Tip: Enable with .openai((openai) => openai.useResponsesAPI())');
  }
  print('');
}

/// Demonstrate capability validation before use
Future<void> demonstrateCapabilityValidation(
    Map<String, ProviderCapabilities> providers) async {
  print('🛡️ Capability Validation:\n');

  for (final entry in providers.entries) {
    final providerName = entry.key;
    final provider = entry.value;

    print('   🔍 Validating $providerName:');

    // Safe capability checking
    if (provider.supports(LLMCapability.chat)) {
      print('      ✅ Chat capability available - can use chat() method');
    } else {
      print('      ❌ Chat capability not available - avoid chat() method');
    }

    if (provider.supports(LLMCapability.streaming)) {
      print(
          '      ✅ Streaming capability available - can use chatStream() method');
    } else {
      print(
          '      ❌ Streaming capability not available - avoid chatStream() method');
    }

    if (provider.supports(LLMCapability.toolCalling)) {
      print('      ✅ Tool calling available - can use tools parameter');
    } else {
      print('      ❌ Tool calling not available - avoid tools parameter');
    }

    if (provider.supports(LLMCapability.vision)) {
      print('      ✅ Vision capability available - can send image messages');
    } else {
      print('      ❌ Vision capability not available - text-only messages');
    }

    if (provider.supports(LLMCapability.openaiResponses)) {
      print(
          '      ✅ OpenAI Responses API available - can use stateful features');
      print('      💡 Access via: (provider as OpenAIProvider).responses');
    } else {
      print('      ❌ OpenAI Responses API not available - standard chat only');
    }

    print('');
  }

  print('   💡 Best Practices:');
  print(
      '      • Use capability checks for provider selection and documentation');
  print('      • Always implement graceful error handling for all features');
  print('      • Test critical features with actual API calls when possible');
  print('      • Remember that actual support may vary by specific model');
  print(
      '      • For reasoning: check response.thinking at runtime, not just capability');
  print(
      '      • For OpenAI-compatible providers: capabilities may differ from declarations');
  print('');
}

/// 🎯 Key Capability Concepts Summary:
///
/// **ProviderCapabilities Interface:**
/// - supportedCapabilities: Set of all supported capabilities
/// - supports(capability): Check if specific capability is supported
/// - **Note**: Primarily for informational and selection purposes
///
/// **LLMCapability Enum Values:**
/// - chat: Basic chat functionality
/// - streaming: Real-time response streaming
/// - toolCalling: Function/tool calling
/// - vision: Image understanding
/// - reasoning: Thinking/reasoning processes (varies by provider!)
/// - embedding: Vector embeddings
/// - textToSpeech: Text-to-speech conversion
/// - speechToText: Speech-to-text conversion
/// - imageGeneration: Image creation
/// - modelListing: Model discovery
/// - fileManagement: File operations
/// - moderation: Content moderation
/// - assistants: Assistant management
/// - liveSearch: Real-time web search (xAI Grok)
/// - openaiResponses: OpenAI Responses API (stateful conversations, background processing)
///
/// **Important Limitations:**
/// 1. **Model Variations**: Support varies by specific model within providers
/// 2. **OpenAI-Compatible Providers**: May have different actual capabilities
/// 3. **Runtime Detection**: Some features detected through response parsing
/// 4. **Reasoning Differences**:
///    - OpenAI o1: Internal reasoning, no visible thinking
///    - Anthropic Claude: May output thinking process
///    - DeepSeek Reasoner: Detailed reasoning steps
///
/// **Best Practices:**
/// 1. Use capability checks for provider selection and documentation
/// 2. Always implement graceful error handling for all features
/// 3. Test critical features with actual API calls when possible
/// 4. For reasoning: check `response.thinking` at runtime
/// 5. Don't rely solely on capability declarations for validation
/// 6. Consider capability evolution and model updates over time
///
/// **Next Steps:**
/// - model_listing.dart: Discover available models
/// - error_handling.dart: Handle capability-related errors
/// - reasoning_models.dart: See runtime reasoning detection in action
/// - Provider-specific examples for advanced features
