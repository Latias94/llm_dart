# llm_dart_provider

Provider specification contracts and shared provider-facing data structures for
`llm_dart`.

This package is the new landing zone for stable model/provider contracts that
provider implementations can depend on without pulling in AI runtime
orchestration, chat session code, Flutter adapters, or the root compatibility
package.

The current migration slices own provider-facing contracts:

- `JsonSchema`
- `ModelError` and `ModelErrorKind`
- `ModelWarning` and `ModelWarningType`
- `ProviderMetadata`
- `UsageStats`
- `ProviderModelOptions`
- `ProviderInvocationOptions`
- `ProviderCancellation` and `ProviderCancelledException`
- `CallOptions`
- prompt message and prompt part contracts
- generated content part contracts
- tool definition and tool choice contracts
- `FinishReason`
- response format contracts
- text stream event contracts
- file data and provider reference contracts
- language, embedding, image, speech, and transcription model interfaces
- model response metadata and capability profiles
- shared UI message, UI stream chunk, projection, and mapping contracts
- prompt, text-stream, and chat-UI serialization codecs

Future slices should keep this package focused on stable provider-facing
contracts and avoid moving runtime orchestration, transport, or Flutter adapter
logic here.

## Ownership Rules

- Do not depend on `llm_dart_core`, `llm_dart_transport`, concrete provider
  packages, chat packages, Flutter packages, or the root `llm_dart` package.
- Do not add runtime orchestration helpers such as multi-step generation loops
  here. Those belong in `llm_dart_ai`.
- Do not add transport implementations or Dio types here. Those belong in
  `llm_dart_transport`.
