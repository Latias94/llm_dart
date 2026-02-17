// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai/responses.dart';

/// 🚀 OpenAI Responses API Provider Build Demo
///
/// This example demonstrates how to build an OpenAI provider configured for the
/// Responses API using only subpackages.
///
/// **Key Benefits:**
/// - **Explicit Configuration**: Enable Responses API via `providerOptions`
/// - **Type Safety**: Cast the built provider to `OpenAIProvider`
/// - **Provider-native tools**: Configure built-in tools via `providerTools`
///
/// **Usage Patterns:**
/// ```dart
/// // Traditional approach (manual configuration)
/// registerOpenAI();
///
/// final provider1 = await LLMBuilder()
///     .provider(openaiProviderId)
///     .apiKey(apiKey)
///     .model('gpt-4o')
///     .providerOption('openai', 'useResponsesAPI', true)
///     .providerTool(OpenAIProviderTools.webSearchPreview())
///     .build();
///
/// if (provider1.supports(LLMCapability.openaiResponses) && provider1 is OpenAIProvider) {
///   final responsesAPI = (provider1 as OpenAIProvider).responses!;
///   // Use responsesAPI...
/// }
///
/// final openaiProvider = provider1 as OpenAIProvider;
/// final responsesAPI = openaiProvider.responses!;
/// ```
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
void main() async {
  print('🚀 OpenAI Responses API Provider Build Demo\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    exit(1);
  }

  registerOpenAI();
  registerAnthropic();

  await demonstrateTraditionalApproach(apiKey);
  await demonstrateConvenienceMethod(apiKey);
  await demonstrateErrorHandling(apiKey);
  await demonstrateCapabilityComparison(apiKey);

  print('\n✅ OpenAI Responses build demo completed!');
}

/// Demonstrate traditional approach with manual configuration
Future<void> demonstrateTraditionalApproach(String apiKey) async {
  print('📋 Traditional Approach (Manual Configuration):\n');

  try {
    // Manual configuration with capability checking
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o')
        .providerOption('openai', 'useResponsesAPI', true)
        .providerTool(OpenAIProviderTools.webSearchPreview())
        .build();

    print('   ✅ Provider created: ${provider.runtimeType}');

    // Manual capability checking and casting
    if (provider is ProviderCapabilities &&
        (provider as ProviderCapabilities)
            .supports(LLMCapability.openaiResponses) &&
        provider is OpenAIProvider) {
      final openaiProvider = provider;
      // ignore: unnecessary_nullable_for_final_variable_declarations
      final OpenAIResponses? responsesAPI = OpenAIResponses(
        OpenAIClient(openaiProvider.config),
        openaiProvider.config,
      );

      if (responsesAPI != null) {
        print('   ✅ Responses API available after manual setup');

        // Test basic functionality
        final response = await responsesAPI.chat([
          ChatMessage.user('Hello from traditional approach!'),
        ]);
        print(
            '   💬 Response: ${response.text?.substring(0, 50) ?? 'No text'}...');
      } else {
        print('   ❌ Responses API not available despite capability');
      }
    } else {
      print('   ❌ Capability check failed');
    }
  } catch (e) {
    print('   ❌ Error in traditional approach: $e');
  }
}

/// Demonstrate typed access with an explicit cast
Future<void> demonstrateConvenienceMethod(String apiKey) async {
  print('\n🚀 Typed Access (cast to OpenAIProvider):\n');

  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o')
        .providerOption('openai', 'useResponsesAPI', true)
        .providerTool(OpenAIProviderTools.webSearchPreview())
        .build();
    final openaiProvider = provider as OpenAIProvider;

    print('   ✅ Provider created: ${provider.runtimeType}');
    print('   ✅ Responses API enabled via providerOptions');
    print('   ✅ OpenAIProvider obtained via cast');

    final responsesAPI = OpenAIResponses(
      OpenAIClient(openaiProvider.config),
      openaiProvider.config,
    );
    print('   ✅ Direct access to Responses API');

    // Verify capabilities
    print('   📋 Capabilities:');
    print(
        '      • openaiResponses: ${openaiProvider.supports(LLMCapability.openaiResponses)}');
    print('      • chat: ${openaiProvider.supports(LLMCapability.chat)}');
    print(
        '      • streaming: ${openaiProvider.supports(LLMCapability.streaming)}');

    // Test basic functionality
    final response = await responsesAPI.chat([
      ChatMessage.user('Hello from convenience method!'),
    ]);
    print('   💬 Response: ${response.text?.substring(0, 50) ?? 'No text'}...');

    // Test response ID access
    if (response is OpenAIResponsesResponse && response.responseId != null) {
      print('   🆔 Response ID: ${response.responseId!.substring(0, 20)}...');
    }
  } catch (e) {
    print('   ❌ Error in convenience method: $e');
  }
}

/// Demonstrate error handling
Future<void> demonstrateErrorHandling(String apiKey) async {
  print('\n⚠️ Error Handling:\n');

  // Test with non-OpenAI provider
  try {
    print('   Testing with non-OpenAI provider...');
    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey('dummy-key')
        .model('claude-3-sonnet-20240229')
        .build();
    // ignore: unused_local_variable
    final openaiProvider = provider as OpenAIProvider;

    print('   ❌ Should have thrown an error!');
  } catch (e) {
    print('   ✅ Correctly caught error: ${e.toString().substring(0, 80)}...');
  }

  // Test enablement
  try {
    print('\n   Testing Responses API enablement...');
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o')
        .providerOption('openai', 'useResponsesAPI', true)
        .build();
    final openaiProvider = provider as OpenAIProvider;

    print('   ✅ Responses API enabled');
    print(
        '   ✅ Provider supports openaiResponses: ${openaiProvider.supports(LLMCapability.openaiResponses)}');
  } catch (e) {
    print('   ❌ Error in automatic enablement: $e');
  }
}

/// Compare capabilities between different build methods
Future<void> demonstrateCapabilityComparison(String apiKey) async {
  print('\n📊 Capability Comparison:\n');

  try {
    // Standard build
    final standardProvider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .build();

    final responsesProvider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o')
        .providerOption('openai', 'useResponsesAPI', true)
        .build();

    print('   📋 Standard Provider Capabilities:');
    _printCapabilities(standardProvider);

    print('\n   📋 Responses Provider Capabilities:');
    _printCapabilities(responsesProvider);

    // Highlight the difference
    final standardHasResponses = standardProvider is ProviderCapabilities &&
        (standardProvider as ProviderCapabilities)
            .supports(LLMCapability.openaiResponses);
    final responsesHasResponses = responsesProvider is ProviderCapabilities &&
        (responsesProvider as ProviderCapabilities)
            .supports(LLMCapability.openaiResponses);

    print('\n   🔍 Key Difference:');
    print('      • Standard build has openaiResponses: $standardHasResponses');
    print(
        '      • Responses-enabled build has openaiResponses: $responsesHasResponses');

    if (!standardHasResponses && responsesHasResponses) {
      print('      ✅ Enabling Responses API adds the capability!');
    }
  } catch (e) {
    print('   ❌ Error in capability comparison: $e');
  }
}

/// Helper function to print provider capabilities
void _printCapabilities(dynamic provider) {
  if (provider is ProviderCapabilities) {
    final capabilities = provider.supportedCapabilities.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final capability in capabilities) {
      final icon = capability == LLMCapability.openaiResponses ? '🚀' : '✅';
      print('      $icon ${capability.name}');
    }

    print('      📊 Total: ${capabilities.length} capabilities');
  } else {
    print('      ❌ Provider does not implement ProviderCapabilities');
  }
}

/// 🎯 Key Benefits Summary:
///
/// **Subpackage-friendly Responses API configuration**
///
/// ```dart
/// final provider = await LLMBuilder()
///     .provider(openaiProviderId)
///     .apiKey(apiKey)
///     .model('gpt-4o')
///     .providerOption('openai', 'useResponsesAPI', true)
///     .providerTool(OpenAIProviderTools.webSearchPreview())
///     .build();
///
/// final openaiProvider = provider as OpenAIProvider;
/// final responsesAPI = openaiProvider.responses!;
/// // Use responsesAPI...
/// ```
///
/// **Benefits:**
/// 1. **Explicit**: Enables Responses API via `providerOptions`.
/// 2. **Typed tools**: Configures built-ins via `providerTools` catalogs.
/// 3. **Composable**: Works with subpackages without pulling the umbrella package.
