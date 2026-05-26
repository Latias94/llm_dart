/// Provider-authoring and advanced runtime contracts.
///
/// Use this entrypoint when implementing providers, writing low-level tests, or
/// working directly with provider prompt/replay/stream contracts. App code
/// should prefer `app.dart`.
library;

export 'ai.dart'
    hide
        CustomEvent,
        ErrorEvent,
        FileEvent,
        FinishEvent,
        RawChunkEvent,
        ReasoningDeltaEvent,
        ReasoningEndEvent,
        ReasoningFileEvent,
        ReasoningStartEvent,
        ResponseMetadataEvent,
        SourceEvent,
        StartEvent,
        TextDeltaEvent,
        TextEndEvent,
        TextStartEvent,
        ToolApprovalRequestEvent,
        ToolCallEvent,
        ToolInputDeltaEvent,
        ToolInputEndEvent,
        ToolInputErrorEvent,
        ToolInputStartEvent,
        ToolResultEvent;
export 'package:llm_dart_provider/provider_authoring.dart';
