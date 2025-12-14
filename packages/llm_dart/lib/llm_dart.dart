/// LLM Dart Library - A modular Dart library for AI provider interactions
///
/// This library provides a unified interface for interacting with different
/// AI providers, starting with OpenAI. It's designed to be modular and
/// extensible
library;

// Core exports (forwarded from llm_dart_core).
//
// The root package now re-exports a curated SDK surface from
// `llm_dart_core` instead of the entire core API. This keeps the
// default import:
//   import 'package:llm_dart/llm_dart.dart';
// focused on high-level usage (messages, tools, language models,
// agents, and helper functions).
//
// For full access to all core types (capabilities, low-level models,
// registry, etc.), prefer importing `llm_dart_core` directly:
//   import 'package:llm_dart_core/llm_dart_core.dart';
export 'package:llm_dart_core/llm_dart_core.dart'
    show
        // Core error / cancellation
        LLMError,
        HttpError,
        GenericError,
        InvalidRequestError,
        AuthError,
        ProviderError,
        ResponseFormatError,
        TimeoutError,
        NotFoundError,
        JsonError,
        ToolConfigError,
        ToolExecutionError,
        ToolValidationError,
        StructuredOutputError,
        RateLimitError,
        QuotaExceededError,
        ModelNotAvailableError,
        CancelledError,
        ContentFilterError,
        ServerError,
        UnsupportedCapabilityError,
        OpenAIResponsesError,
        CancellationToken,
        CancellationTokenSource,

        // Core config & capabilities (high-level)
        LLMConfig,
        LLMCapability,
        LanguageModel,
        ChatCapability,
        EmbeddingCapability,
        CompletionCapability,
        ToolExecutionCapability,
        ModerationCapability,
        ModelListingCapability,
        ProviderCapabilities,
        ChatResponse,
        Agent,
        AgentInput,
        ToolLoopAgent,
        ToolLoopConfig,

        // Chat models & stream types
        ChatRole,
        ModelMessage,
        ChatContentPart,
        TextContentPart,
        FileContentPart,
        UrlFileContentPart,
        ReasoningContentPart,
        ToolCallContentPart,
        ToolResultContentPart,
        MessageBuilder,
        ImageMime,
        ImageMimeExtension,
        FileMime,
        ChatStreamEvent,
        TextDeltaEvent,
        ThinkingDeltaEvent,
        ToolCallDeltaEvent,
        CompletionEvent,
        ErrorEvent,
        StreamTextPart,
        StreamTextStart,
        StreamTextDelta,
        StreamTextEnd,
        StreamThinkingDelta,
        StreamToolInputStart,
        StreamToolInputDelta,
        StreamToolInputEnd,
        StreamToolCall,
        StreamFinish,
        GenerateTextResult,
        GenerateObjectResult,

        // Chat / embedding middleware & contexts
        ChatOperationKind,
        ChatCallContext,
        ChatMiddleware,
        EmbeddingCallContext,
        EmbeddingMiddleware,

        // Tools & structured output
        Tool,
        CallToolSpec,
        FunctionCallToolSpec,
        ProviderDefinedToolSpec,
        ExecutableTool,
        ToolBuilder,
        tool,
        ToolCall,
        ToolResult,
        FunctionCall,
        FunctionTool,
        ParameterProperty,
        ParametersSchema,
        ToolChoice,
        AutoToolChoice,
        AnyToolChoice,
        NoneToolChoice,
        SpecificToolChoice,
        ParallelToolConfig,
        ToolValidator,
        OutputSpec,
        StructuredOutputFormat,

        // Model capability configuration
        ModelCapabilityConfig,
        LLMConfigKeys,
        LLMConfigKey,
        LLMConfigTypedKeys,
        LLMLogger,
        ConsoleLLMLogger,
        NoopLLMLogger,
        resolveLogger,

        // Cancellation helpers
        CancellationHelper,

        // Call options and metadata
        LanguageModelCallOptions,
        CallWarning,
        UsageInfo,
        CallMetadata,
        ServiceTier,
        ReasoningEffort,
        Verbosity,
        ReasoningPruneMode,
        ToolCallPruneMode,
        pruneModelMessages,

        // Audio capabilities & models
        AudioFeature,
        AudioCapability,
        BaseAudioCapability,
        AudioProcessingMode,
        AudioQuality,
        AudioFormat,
        TextNormalization,
        AudioStreamEvent,
        AudioDataEvent,
        AudioMetadataEvent,
        AudioTimingEvent,
        AudioErrorEvent,
        TTSRequest,
        TTSResponse,
        STTRequest,
        STTResponse,
        AudioTranslationRequest,
        TimestampGranularity,
        EnhancedWordTiming,
        VoiceInfo,
        RealtimeAudioSession,
        RealtimeAudioEvent,
        RealtimeAudioConfig,
        RealtimeTranscriptionEvent,
        RealtimeAudioResponseEvent,
        RealtimeSessionStatusEvent,
        RealtimeErrorEvent,

        // Image generation capabilities & models
        ImageGenerationCapability,
        ImageGenerationRequest,
        ImageEditRequest,
        ImageVariationRequest,
        ImageGenerationResponse,
        ImageInput,
        ImageDimensions,
        ImageStyle,
        ImageQuality,
        ImageSize,

        // Stream helpers
        adaptStreamText,

        // File capabilities & models
        FileManagementCapability,
        FilePurpose,
        FileStatus,
        FileObject,
        FileUploadRequest,
        FileListResponse,
        FileListQuery,

        // Moderation models
        ModerationRequest,
        ModerationCategories,
        ModerationCategoryScores,
        ModerationResult,
        ModerationResponse,

        // Model listing
        AIModel,

        // Responses API models
        ResponseInputItemsList,
        ResponseInputItem,

        // Web search configuration
        WebSearchConfig,
        WebSearchType,
        WebSearchContextSize,
        WebSearchStrategy,
        WebSearchLocation,

        // Assistant capabilities & models
        AssistantCapability,
        AssistantToolType,
        AssistantTool,
        CodeInterpreterTool,
        FileSearchTool,
        AssistantFunctionTool,
        AssistantResponseFormat,
        Assistant,
        CreateAssistantRequest,
        ModifyAssistantRequest,
        ListAssistantsResponse,
        DeleteAssistantResponse,
        ListAssistantsQuery,

        // Reranking models
        RerankDocument,
        RerankResultItem,
        RerankResult;

// Provider utils exports (HTTP config, error handling, UTF-8 decoding).
//
// These utilities live in the llm_dart_provider_utils package but are
// re-exported here for convenience so that common SDK usage only needs
// `package:llm_dart/llm_dart.dart`.
export 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    show
        HttpConfigUtils,
        DioErrorHandler,
        Utf8StreamDecoder,
        Utf8StreamDecoderExtension,
        ProviderDefinedToolFactory,
        createProviderDefinedExecutableTool;

// Provider packages ("full bundle").
export 'package:llm_dart_openai/llm_dart_openai.dart';
export 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
export 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
export 'package:llm_dart_google/llm_dart_google.dart';
export 'package:llm_dart_deepseek/llm_dart_deepseek.dart';
export 'package:llm_dart_ollama/llm_dart_ollama.dart';
export 'package:llm_dart_xai/llm_dart_xai.dart';
export 'package:llm_dart_groq/llm_dart_groq.dart';
export 'package:llm_dart_phind/llm_dart_phind.dart';
export 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';

// Builder exports
export 'builder/llm_builder.dart';
export 'builder/llm_builder_providers.dart';
export 'builder/chat_prompt_builder.dart';
export 'builder/http_config.dart';

// Utility exports
//
// Other capabilities and registry helpers are re-exported directly from
// llm_dart_core.
export 'package:llm_dart_core/llm_dart_core.dart'
    show CapabilityUtils, CapabilityError, CapabilityValidationReport;
export 'package:llm_dart_core/llm_dart_core.dart'
    show
        ProviderFactoryRegistry,
        ProviderRegistry,
        ProviderInstanceRegistry,
        RegistryProviderInfo,
        RegistryStats,
        ProviderRegistryClient,
        createProviderRegistry,
        LLMProviderFactory,
        LLMProviderRegistry,
        ProviderInfo,
        LanguageModelProviderFactory,
        EmbeddingModelProviderFactory,
        ImageModelProviderFactory,
        SpeechModelProviderFactory,
        BaseProviderFactory,
        OpenAICompatibleBaseFactory,
        LocalProviderFactory,
        AudioProviderFactory;
export 'utils/logging_middleware.dart';
export 'utils/default_settings_middleware.dart';

// High-level helpers grouped by domain
export 'text.dart';
export 'audio.dart';
export 'agents.dart';

// Convenience functions for creating providers
import 'package:llm_dart_core/llm_dart_core.dart';

import 'builder/llm_builder.dart';
import 'src/builtin_providers.dart' show registerBuiltinProviders;

// Ensure the full-bundle package registers built-in providers eagerly on import.
// This avoids a common footgun where users instantiate `LLMBuilder()` directly
// and call `.provider('openai')` without first calling `ai()` or any of the
// provider shortcut extensions.
// ignore: unused_element
final bool _llmDartBuiltinsInitialized = (() {
  registerBuiltinProviders();
  return true;
})();

/// Create a new LLM builder instance
///
/// This is the main entry point for creating AI providers.
///
/// Example:
/// ```dart
/// final provider = await ai()
///     .openai()
///     .apiKey('your-key')
///     .model('gpt-4')
///     .build();
/// ```
LLMBuilder ai() {
  registerBuiltinProviders();
  return LLMBuilder();
}

/// Create a provider with the given configuration
///
/// Convenience function for quickly creating providers with common settings.
///
/// Example:
/// ```dart
/// final provider = await createProvider(
///   providerId: 'openai',
///   apiKey: 'your-key',
///   model: 'gpt-4',
/// );
/// ```
Future<ChatCapability> createProvider({
  required String providerId,
  required String apiKey,
  required String model,
  String? baseUrl,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  Duration? timeout,
  double? topP,
  int? topK,
  Map<String, dynamic>? extensions,
}) async {
  // ElevenLabs is an audio-focused provider and does not support the
  // chat-centric [createProvider] helper. Users should build audio
  // capabilities explicitly instead.
  if (providerId == 'elevenlabs') {
    throw const UnsupportedCapabilityError(
      'createProvider() does not support the "elevenlabs" provider for '
      'chat capabilities. Use ai().elevenlabs().apiKey(...).buildAudio() '
      'or the generateSpeech()/transcribe() helpers for audio use cases.',
    );
  }

  var builder = ai().provider(providerId).apiKey(apiKey).model(model);

  if (baseUrl != null) builder = builder.baseUrl(baseUrl);
  if (temperature != null) builder = builder.temperature(temperature);
  if (maxTokens != null) builder = builder.maxTokens(maxTokens);
  if (systemPrompt != null) builder = builder.systemPrompt(systemPrompt);
  if (timeout != null) builder = builder.timeout(timeout);
  if (topP != null) builder = builder.topP(topP);
  if (topK != null) builder = builder.topK(topK);

  // Add extensions if provided
  if (extensions != null) {
    for (final entry in extensions.entries) {
      builder = builder.extension(entry.key, entry.value);
    }
  }

  return await builder.build();
}
