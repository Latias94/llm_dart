/// App-facing AI runtime helpers.
///
/// This entrypoint is intentionally narrower than `llm_dart_ai.dart`: text
/// calls accept `ModelMessage` through `messages:` only. Provider-facing
/// `PromptMessage` and low-level request contracts remain available from
/// `provider_authoring.dart` and the compatibility `llm_dart_ai.dart` barrel.
library;

export 'src/app/app_generation.dart';
export 'src/model/embed.dart';
export 'src/model/generate_image.dart';
export 'src/model/generate_speech.dart';
export 'src/model/generate_text_result_accumulator.dart';
export 'src/model/generate_text_run_result.dart';
export 'src/model/generate_text_runner_support.dart'
    show
        GenerateTextFunctionToolExecutionRequest,
        GenerateTextFunctionToolExecutor,
        GenerateTextOnError,
        GenerateTextOnFinish,
        GenerateTextOnStepFinish,
        GenerateTextOnStepStart,
        GenerateTextOnToolFinish,
        GenerateTextOnToolStart,
        GenerateTextToolExecution,
        GenerateTextToolExecutionFinishEvent,
        GenerateTextToolExecutionResult,
        GenerateTextToolExecutionStartEvent,
        StreamTextOnChunk;
export 'src/model/generate_text_stop_condition.dart';
export 'src/model/generate_text_step_result.dart';
export 'src/model/output_spec.dart'
    hide
        generateObject,
        generateOutput,
        generateOutputForRequest,
        streamObject,
        streamOutput,
        streamOutputForRequest,
        streamOutputResult,
        streamOutputResultForRequest;
export 'src/model/text_call.dart'
    hide
        generateTextCall,
        generateTextCallForRequest,
        streamTextCall,
        streamTextCallForRequest;
export 'src/model/transcribe.dart';
export 'src/prompt/model_message.dart';
export 'src/serialization/chat_ui_json_codec.dart';
export 'src/serialization/text_stream_event_json_codec.dart';
export 'src/stream/text_stream_event.dart';
export 'src/ui/chat_message_mapper.dart';
export 'src/ui/chat_ui_accumulator.dart';
export 'src/ui/chat_ui_message.dart';
export 'src/ui/chat_ui_stream_accumulator.dart';
export 'src/ui/chat_ui_stream_chunk.dart';
export 'src/ui/chat_ui_stream_error.dart';
export 'src/ui/chat_ui_stream_projection.dart';
export 'src/ui/chat_ui_stream_reader.dart';
export 'src/ui/chat_ui_stream_validation.dart';

export 'package:llm_dart_provider/foundation.dart'
    show
        AutoToolChoice,
        CallOptions,
        CapabilityGateDecision,
        CapabilityGateMode,
        CapabilityConfidence,
        CapabilityDescribedModel,
        CapabilityDescriptor,
        ContentToolOutput,
        ContentPart,
        CustomContentPart,
        CustomToolOutputContentPart,
        EmbeddingModel,
        ErrorJsonToolOutput,
        ErrorTextToolOutput,
        ExecutionDeniedToolOutput,
        FileBytesData,
        FileContentPart,
        FileData,
        FileProviderReferenceData,
        FileTextData,
        FileToolOutputContentPart,
        FileUrlData,
        FinishReason,
        FunctionToolDefinition,
        GenerateTextOptions,
        GenerateTextReasoningOptions,
        GenerateTextResult,
        GeneratedFile,
        GeneratedImage,
        ImageGenerationInput,
        ImageGenerationResult,
        ImageModel,
        JsonSchema,
        JsonToolOutput,
        LanguageModel,
        ModelCapabilityFeatureIds,
        ModelCapabilityKind,
        ModelCapabilityProfile,
        ModelError,
        ModelErrorKind,
        ModelException,
        ModelReference,
        ModelResponseMetadata,
        ModelWarning,
        ModelWarningType,
        NoneToolChoice,
        Provider,
        ProviderCapabilityGate,
        ProviderCancellation,
        ProviderCancelledException,
        ProviderFeatureDescriptor,
        ProviderInputShapeDescriptor,
        ProviderInputShapeIds,
        ProviderInvocationOptions,
        ProviderInvocationOptionsBagProjection,
        ProviderInvocationOptionsBundle,
        ProviderMetadata,
        ProviderModelFacet,
        ProviderModelOptions,
        ProviderOptionsBag,
        ProviderPromptPartOptions,
        ProviderReference,
        ProviderRegistry,
        ProviderSpecification,
        ProviderSpecificationVersion,
        ModelCapabilityGate,
        ProviderToolOptions,
        ReasoningContentPart,
        ReasoningEffort,
        ReasoningFileContentPart,
        RequiredToolChoice,
        ResponseFormat,
        SourceContentPart,
        SourceReference,
        SourceReferenceKind,
        SpecificToolChoice,
        SpeechGenerationResult,
        SpeechModel,
        TextContentPart,
        TextToolOutput,
        ToolApprovalRequestContent,
        ToolApprovalRequestContentPart,
        ToolCallContent,
        ToolCallContentPart,
        ToolChoice,
        ToolDefinition,
        ToolJsonSchema,
        ToolOutput,
        ToolOutputContentPart,
        ToolResultContent,
        ToolResultContentPart,
        TranscriptionModel,
        TranscriptionResult,
        TranscriptionSegment,
        UsageStats,
        modelErrorFrom,
        providerInvocationOptions,
        providerOptionsBagFromInvocationOptions,
        providerOptionsNamespaceFromInvocationOptions,
        typedProviderOptionsFromInvocationOptions;
