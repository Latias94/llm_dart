import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

/// AI-runtime full stream event vocabulary.
///
/// These are compatibility aliases while event implementations move out of
/// `llm_dart_provider`. App-facing runtime code should import these names from
/// `llm_dart_ai`; provider-facing code should use `LanguageModelStreamEvent`.
typedef TextStreamEvent = provider.TextStreamEvent;
typedef StartEvent = provider.StartEvent;
typedef ResponseMetadataEvent = provider.ResponseMetadataEvent;
typedef TextStartEvent = provider.TextStartEvent;
typedef TextDeltaEvent = provider.TextDeltaEvent;
typedef TextEndEvent = provider.TextEndEvent;
typedef ReasoningStartEvent = provider.ReasoningStartEvent;
typedef ReasoningDeltaEvent = provider.ReasoningDeltaEvent;
typedef ReasoningEndEvent = provider.ReasoningEndEvent;
typedef ReasoningFileEvent = provider.ReasoningFileEvent;
typedef ToolInputStartEvent = provider.ToolInputStartEvent;
typedef ToolInputDeltaEvent = provider.ToolInputDeltaEvent;
typedef ToolInputEndEvent = provider.ToolInputEndEvent;
typedef ToolInputErrorEvent = provider.ToolInputErrorEvent;
typedef ToolCallEvent = provider.ToolCallEvent;
typedef ToolResultEvent = provider.ToolResultEvent;
typedef ToolApprovalRequestEvent = provider.ToolApprovalRequestEvent;
typedef ToolOutputDeniedEvent = provider.ToolOutputDeniedEvent;
typedef SourceEvent = provider.SourceEvent;
typedef FileEvent = provider.FileEvent;
typedef StepStartEvent = provider.StepStartEvent;
typedef StepFinishEvent = provider.StepFinishEvent;
typedef FinishEvent = provider.FinishEvent;
typedef AbortEvent = provider.AbortEvent;
typedef CustomEvent = provider.CustomEvent;
typedef RawChunkEvent = provider.RawChunkEvent;
typedef ErrorEvent = provider.ErrorEvent;
