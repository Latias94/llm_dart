/// Backwards-compatible re-export of core capability types.
///
/// The canonical implementations live in the `llm_dart_core` package and
/// cover chat/streaming capabilities, usage metadata, language models,
/// completion/embedding/audio capabilities, middleware primitives, and
/// provider capability mixins.
///
/// This file keeps the legacy import path:
/// `package:llm_dart/core/capability.dart`, while limiting the public
/// surface to capability-related types instead of re-exporting the
/// entire `llm_dart_core` API.
library;

export 'package:llm_dart_core/llm_dart_core.dart'
    show
        // Capability enums
        LLMCapability,
        AudioFeature,
        ChatOperationKind,

        // Call warnings / metadata
        CallWarning,
        CallMetadata,

        // Core response / result types
        ChatResponse,
        GenerateTextResult,
        GenerateObjectResult,
        OutputSpec,
        UsageInfo,

        // High-level language model abstraction
        LanguageModel,
        DefaultLanguageModel,

        // Chat capability & middleware
        ChatCapability,
        ChatCallContext,
        ChatMiddleware,
        ChatStreamEvent,
        TextDeltaEvent,
        ToolCallDeltaEvent,
        CompletionEvent,
        ThinkingDeltaEvent,
        ErrorEvent,

        // Completion helpers
        CompletionRequest,
        CompletionResponse,

        // Embedding capability & middleware
        EmbeddingCapability,
        EmbeddingCallContext,
        EmbeddingMiddleware,

        // Audio capability
        AudioCapability,
        BaseAudioCapability,
        RealtimeAudioConfig,
        RealtimeAudioSession,
        RealtimeAudioEvent,
        RealtimeTranscriptionEvent,
        RealtimeAudioResponseEvent,
        RealtimeSessionStatusEvent,
        RealtimeErrorEvent,

        // Model listing & image generation
        ModelListingCapability,
        ImageGenerationCapability,

        // Text completion capability
        CompletionCapability,

        // Provider capability mixins
        ProviderCapabilities,
        BasicLLMProvider,
        EmbeddingLLMProvider,
        VoiceLLMProvider,
        FullLLMProvider,

        // File / moderation / assistant / tool execution capabilities
        FileManagementCapability,
        ModerationCapability,
        AssistantCapability,
        ToolExecutionCapability,
        EnhancedChatCapability;
