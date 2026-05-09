# Reference Architecture Map

## Useful Lessons From `repo-ref/ai`

The reference repository is valuable because its ownership boundaries are
legible:

- `@ai-sdk/provider` defines provider specifications.
- `@ai-sdk/provider-utils` holds reusable provider implementation helpers.
- `ai` owns app-facing generation functions and orchestration.
- provider packages implement the provider specification and expose
  provider-owned helpers.
- UI packages and framework adapters stay above the model/provider layer.

The lesson is not that `llm_dart` needs the same number of packages. The lesson
is that provider contracts, runtime orchestration, provider implementations, and
UI adapters should not compete for the same package identity.

## Current `llm_dart` Equivalent Areas

| Reference area | Current location | Target direction |
| --- | --- | --- |
| provider spec | `llm_dart_core` | `llm_dart_provider` |
| provider utils | mixed in provider packages, transport, and core helpers | `llm_dart_provider_utils` plus transport-owned HTTP helpers |
| app-facing AI runtime | `llm_dart_core` model runners and output helpers | `llm_dart_ai` |
| transport | `llm_dart_transport` | keep |
| chat runtime | `llm_dart_chat` | keep |
| Flutter adapter | `llm_dart_flutter` | keep |
| provider implementations | `llm_dart_openai`, `llm_dart_google`, `llm_dart_anthropic`, `llm_dart_ollama`, `llm_dart_elevenlabs`, and root legacy providers | provider packages only |
| root package | modern facade plus compatibility host plus legacy implementation tail | facade plus explicit compatibility bridge |

## Deliberate Dart Differences

`llm_dart` should keep stronger Dart-native surfaces where they are useful:

- typed provider model settings instead of only map-shaped provider options
- typed provider invocation options for per-call features
- sealed classes for shared data structures
- optional model capability descriptors for app and Flutter gating
- provider-family profiles for OpenAI-compatible providers
- provider-native helper clients for product-specific lifecycle APIs

## Reference Ideas To Adopt Carefully

### Provider Reference

Adopt a shared provider-reference concept for uploaded or hosted files:

```dart
ProviderReference({'openai': 'file-abc', 'anthropic': 'file-def'});
```

This should replace metadata-based file identity in prompt inputs.

### Layered Messages

Keep the current layered direction:

- prompt/model request messages
- model stream/result events
- UI messages and chat chunks
- provider-specific wire payloads

Do not collapse these into one universal message type.

### Runtime Above Provider Spec

Multi-step tool execution, `prepareStep`, stop policy, structured output, and
stream result facades belong above the provider model interface, not inside the
provider specification itself.

## Reference Ideas To Defer

Do not adopt these without separate product pressure:

- complete reference package-count parity
- framework packages beyond Flutter
- shared gateway abstraction
- shared video, reranking, or skills abstractions
- JavaScript-style untyped provider option maps as the only provider extension
  mechanism
