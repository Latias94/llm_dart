# Runtime Ownership Audit

## Runtime Surfaces

The user-facing runtime remains in `llm_dart_ai`:

- `generateText` and `streamText` are in
  `packages/llm_dart_ai/lib/src/model/language_model.dart`
- multi-step tool orchestration is in `GenerateTextRunner`,
  `StreamTextRunner`, and `GenerateTextRunnerSupport`
- object and structured-output helpers are in
  `packages/llm_dart_ai/lib/src/model/output_spec.dart`
- UI projection helpers such as `ChatMessageMapper` and chat UI accumulators
  are in `packages/llm_dart_ai/lib/src/ui`

Provider implementations call `doGenerate` and `doStream` only. They translate
provider-neutral request contracts into provider wire requests and translate
wire results back into provider-neutral result/event contracts.

## Codec Ownership

The current codec split is intentional:

- provider-neutral prompt and stream-event JSON codecs live in
  `llm_dart_provider`
- chat UI message codecs live in `llm_dart_ai`
- HTTP chat transport request/chunk codecs live in `llm_dart_chat`
- Flutter persistence adapters depend on chat/runtime codecs instead of owning
  provider contracts
- provider packages may keep provider-native replay/custom-part codecs when
  those codecs translate provider-owned wire data, not UI projections

## Guard Coverage

`tool/check_workspace_dependency_guards.dart` enforces runtime ownership by:

- rejecting provider package production dependencies on `llm_dart_ai`,
  `llm_dart_chat`, `llm_dart_flutter`, root `llm_dart`, or compatibility
  `llm_dart_core`
- rejecting `package:llm_dart/...` imports from package implementation files
- rejecting old provider method names `generate` and `stream`
- rejecting chat/UI projection ownership in `llm_dart_provider/lib` by
  flagging `ChatUi`, `CustomUiPart`, `ChatMessageMapper`, and
  `HttpChatTransport`

This keeps provider specifications free of runtime, UI, and transport-chat
implementation ownership while still allowing provider-neutral serialization
contracts where the provider layer needs them.
