// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// 🚀 buildOpenAIResponses() Method Demo
///
/// This example demonstrates the new `buildOpenAIResponses()` convenience method
/// that provides type-safe access to OpenAI Responses API features.
///
/// **Key Benefits:**
/// - **Automatic Configuration**: Automatically enables Responses API
/// - **Type Safety**: Returns properly typed OpenAIProvider
/// - **Direct Access**: No need for casting or capability checking
/// - **Error Prevention**: Validates Responses API initialization
///
/// **Usage Patterns:**
/// ```dart
/// // Traditional approach (manual configuration)
/// final provider1 = await ai()
///     .openai((openai) => openai.useResponsesAPI())
///     .apiKey(apiKey)
///     .model('gpt-4o')
///     .build();
///
/// if (provider1.supports(LLMCapability.openaiResponses) && provider1 is OpenAIProvider) {
///   final responsesAPI = (provider1 as OpenAIProvider).responses!;
///   // Use responsesAPI...
/// }
///
/// // New convenience approach
/// final provider2 = await ai()
///     .openai((openai) => openai.webSearchTool())
///     .apiKey(apiKey)
///     .model('gpt-4o')
///     .buildOpenAIResponses();
///
/// // Direct access - no casting needed!
/// final responsesAPI = provider2.responses!;
/// ```
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
void main() async {
  print('🚀 buildOpenAIResponses() Method Demo\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    exit(1);
  }

  await demonstrateTraditionalApproach(apiKey);
  await demonstrateConvenienceMethod(apiKey);
  await demonstrateErrorHandling(apiKey);
  await demonstrateCapabilityComparison(apiKey);

  print('\n✅ buildOpenAIResponses() demo completed!');
}

/// Demonstrate traditional approach with manual configuration
Future<void> demonstrateTraditionalApproach(String apiKey) async {
  print('📋 Traditional Approach (Manual Configuration):\n');

  try {
    // Manual configuration with capability checking
    final provider = await ai()
        .openai((openai) => openai.useResponsesAPI().webSearchTool())
        .apiKey(apiKey)
        .model('gpt-4o')
        .build();

    print('   ✅ Provider created: ${provider.runtimeType}');

    // Manual capability checking and casting
    if (provider is ProviderCapabilities &&
        (provider as ProviderCapabilities)
            .supports(LLMCapability.openaiResponses) &&
        provider is openai.OpenAIProvider) {
      final openai.OpenAIProvider openaiProvider = provider;
      final responsesAPI = openaiProvider.responses;

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

/// Demonstrate the new convenience method
Future<void> demonstrateConvenienceMethod(String apiKey) async {
  print('\n🚀 New Convenience Method (buildOpenAIResponses):\n');

  try {
    // New convenience method - automatic configuration
    final provider = await ai()
        .openai((openai) => openai.webSearchTool())
        .apiKey(apiKey)
        .model('gpt-4o')
        .buildOpenAIResponses();

    print('   ✅ Provider created: ${provider.runtimeType}');
    print('   ✅ Automatic Responses API configuration');
    print('   ✅ Type-safe OpenAIProvider returned');

    // Direct access - no casting needed!
    final responsesAPI = provider.responses!;
    print('   ✅ Direct access to Responses API');

    // Verify capabilities
    print('   📋 Capabilities:');
    print(
        '      • openaiResponses: ${provider.supports(LLMCapability.openaiResponses)}');
    print('      • chat: ${provider.supports(LLMCapability.chat)}');
    print('      • streaming: ${provider.supports(LLMCapability.streaming)}');

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
    await ai()
        .anthropic()
        .apiKey('dummy-key')
        .model('claude-3-sonnet-20240229')
        .buildOpenAIResponses();

    print('   ❌ Should have thrown an error!');
  } catch (e) {
    print('   ✅ Correctly caught error: ${e.toString().substring(0, 80)}...');
  }

  // Test automatic enablement
  try {
    print('\n   Testing automatic Responses API enablement...');
    final provider = await ai()
        .openai() // No explicit useResponsesAPI() call
        .apiKey(apiKey)
        .model('gpt-4o')
        .buildOpenAIResponses();

    print('   ✅ Responses API automatically enabled');
    print(
        '   ✅ Provider supports openaiResponses: ${provider.supports(LLMCapability.openaiResponses)}');
  } catch (e) {
    print('   ❌ Error in automatic enablement: $e');
  }
}

/// Compare capabilities between different build methods
Future<void> demonstrateCapabilityComparison(String apiKey) async {
  print('\n📊 Capability Comparison:\n');

  try {
    // Standard build
    final standardProvider =
        await ai().openai().apiKey(apiKey).model('gpt-4o-mini').build();

    // Responses API build
    final responsesProvider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .buildOpenAIResponses();

    print('   📋 Standard Provider Capabilities:');
    _printCapabilities(standardProvider);

    print('\n   📋 Responses Provider Capabilities:');
    _printCapabilities(responsesProvider);

    // Highlight the difference
    final standardHasResponses = standardProvider is ProviderCapabilities &&
        (standardProvider as ProviderCapabilities)
            .supports(LLMCapability.openaiResponses);
    final responsesHasResponses =
        responsesProvider.supports(LLMCapability.openaiResponses);

    print('\n   🔍 Key Difference:');
    print('      • Standard build has openaiResponses: $standardHasResponses');
    print(
        '      • buildOpenAIResponses() has openaiResponses: $responsesHasResponses');

    if (!standardHasResponses && responsesHasResponses) {
      print('      ✅ buildOpenAIResponses() successfully adds the capability!');
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
/// **buildOpenAIResponses() vs Traditional Approach:**
///
/// **Traditional:**
/// ```dart
/// final provider = await ai().openai((openai) => openai.useResponsesAPI()).build();
/// if (provider.supports(LLMCapability.openaiResponses) && provider is OpenAIProvider) {
///   final responsesAPI = (provider as OpenAIProvider).responses!;
///   // Use responsesAPI...
/// }
/// ```
///
/// **New Convenience Method:**
/// ```dart
/// final provider = await ai().openai().buildOpenAIResponses();
/// final responsesAPI = provider.responses!; // Direct access!
/// ```
///
/// **Benefits:**
/// 1. **Less Boilerplate**: No manual capability checking or casting
/// 2. **Type Safety**: Guaranteed OpenAIProvider return type
/// 3. **Automatic Configuration**: Enables Responses API automatically
/// 4. **Error Prevention**: Validates initialization at build time
/// 5. **Better DX**: Cleaner, more intuitive API
///
/// **When to Use:**
/// - Use `buildOpenAIResponses()` when you specifically need Responses API features
/// - Use `build()` for general OpenAI usage without Responses API
/// - The method automatically handles the configuration complexity for you
