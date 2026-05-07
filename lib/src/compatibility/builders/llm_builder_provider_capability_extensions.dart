import '../../../builder/llm_builder.dart';
import '../../../core/llm_error.dart';
import '../../../providers/openai/provider.dart';
import '../providers/google/google_tts_capability.dart';
import '../providers/openai/assistant_capability.dart';
import 'google_builder.dart';
import 'openai_builder.dart';

/// Provider-specific typed build helpers layered on top of [LLMBuilder].
extension LLMBuilderProviderCapabilityExtensions on LLMBuilder {
  /// Builds an OpenAI provider with Responses API enabled.
  ///
  /// This is a convenience method that automatically:
  /// - Ensures the provider is OpenAI
  /// - Enables the Responses API (`useResponsesAPI(true)`)
  /// - Returns a properly typed OpenAIProvider with Responses API access
  /// - Ensures the `openaiResponses` capability is available
  ///
  /// Throws [UnsupportedCapabilityError] if the provider is not OpenAI.
  Future<OpenAIProvider> buildOpenAIResponses() async {
    if (currentProviderId != 'openai') {
      throw UnsupportedCapabilityError(
        'buildOpenAIResponses() can only be used with OpenAI provider. '
        'Current provider: $currentProviderId. Use .openai() first.',
      );
    }

    return OpenAIBuilder(this).buildOpenAIResponses();
  }

  /// Builds a provider with OpenAI assistant capability.
  Future<AssistantCapability> buildAssistant() async {
    final provider = await build();
    if (provider is! AssistantCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$currentProviderId" does not support assistant capabilities. '
        'Supported providers: OpenAI',
      );
    }

    return provider as AssistantCapability;
  }

  /// Builds a Google provider with TTS capability.
  ///
  /// This automatically ensures the Google provider is selected and
  /// applies a default TTS model when the current model is not TTS-capable.
  Future<GoogleTTSCapability> buildGoogleTTS() async {
    if (currentProviderId != 'google') {
      throw UnsupportedCapabilityError(
        'buildGoogleTTS() can only be used with Google provider. '
        'Current provider: $currentProviderId. Use .google() first.',
      );
    }

    if (currentConfig.model.isEmpty || !currentConfig.model.contains('tts')) {
      model('gemini-2.5-flash-preview-tts');
    }

    return GoogleLLMBuilder(this).buildGoogleTTS();
  }
}
