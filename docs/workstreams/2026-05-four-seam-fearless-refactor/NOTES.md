# Notes

## Initial observation

The repository already contains several completed AI SDK-inspired workstreams. This workstream does not restart those; it closes the four remaining seams requested in the current session.

## Reference mapping

- Vercel `@ai-sdk/provider` -> `llm_dart_provider`
- Vercel `@ai-sdk/provider-utils` -> new/explicit provider utility seam
- Vercel `ai` runtime -> `llm_dart_ai`
- Vercel provider route directories -> OpenAI package route/capability directories


## M1 decision: provider-neutral root

The root `llm_dart` package is now a provider-neutral runtime Module. It depends on shared contracts/runtime/chat/transport, but not on concrete provider Implementation packages. Concrete provider Adapters are imported directly from packages such as `llm_dart_openai`, `llm_dart_google`, and `llm_dart_anthropic`.

Rationale: this matches the Vercel AI SDK package shape more closely (`ai` runtime + provider packages), improves dependency Locality, and prevents the root Interface from growing every time a provider adds a feature.

Validation captured during M1:

- workspace dependency guard: passed
- root boundary guard: passed
- focused root/provider facade tests: passed
- `dart analyze .`: passed

## M2 decision: provider-utils owns provider-aware transport helpers

`llm_dart_transport` is now a pure transport Module. Its Interface owns HTTP/SSE/NDJSON, retry, diagnostics, cancellation, and transport exceptions only. Provider-aware helpers moved to the new `llm_dart_provider_utils` Module:

- `transportErrorToModelError`
- `decodeJsonSseLanguageModelStream`
- `bindProviderCancellationToTransport`

Rationale: this mirrors Vercel `@ai-sdk/provider-utils` and makes the transport Seam deeper. Transport no longer imports or depends on `llm_dart_provider`; provider Implementations opt into provider-utils when they need provider-stream decoding, error projection, or provider-to-transport cancellation bridging.

Validation captured during M2:

- workspace dependency guard: passed
- transport boundary guard: passed
- transport/provider-utils/tool focused tests: passed
- provider cancellation focused smoke tests: passed
- `dart analyze .`: passed
- `git diff --check`: passed

## M3 decision: OpenAI provider code is organized by route/capability

`llm_dart_openai` no longer keeps every OpenAI-family Implementation file flat under
`lib/src`. The package now uses route/capability directories:

- `provider/` for the OpenAI-family facade, profiles, settings, capability policy,
  and compatible-provider option resolvers.
- `chat_completions/` and `responses/` for the two language-model route
  Implementations.
- `assistants/`, `files/`, `embedding/`, `image/`, `moderation/`, `speech/`, and
  `transcription/` for route-specific clients/models.
- `tools/`, `custom_parts/`, and `common/` for provider-native tool definitions,
  custom content parts, shared JSON/request/stream helpers.

Rationale: this mirrors the Vercel provider package shape and improves Locality.
Maintainers can now navigate by the provider route or capability Seam instead of
scanning a 294-file flat `src` directory. The public package Interface remains stable
through `lib/llm_dart_openai.dart`; only private `src` import paths changed.

Validation captured during M3:

- `dart analyze .`: passed
- OpenAI package tests + prompt normalization + provider replay metadata guard tests:
  passed

## M4 decision: typed provider options and provider options bag now coexist

`ProviderInvocationOptions` remains the typed Dart Interface for provider-owned
request customization. A new `ProviderOptionsBag` adds the Vercel AI
SDK-style JSON Seam: an outer map keyed by provider namespace and an inner JSON
object owned by that provider. `ProviderInvocationOptionsBundle` can carry a
typed options object and a bag together; typed resolution still unwraps the
typed object, while provider Implementations can parse the bag for transport
and cross-process use cases.

OpenAI-family language, embedding, image, speech, and transcription paths now
accept bag namespaces. OpenAI-family profiles parse:

- `openai` common options.
- `openrouter` search shaping.
- `deepseek` chat-completions-specific logprob/penalty/response-format fields.
- `xai` live-search fields.

Typed values take precedence when a bundle carries both typed options and a
bag; bag values fill unset typed fields. HTTP chat transport can serialize a
`ProviderOptionsBag` without a custom encoder while continuing to require an
explicit encoder for non-projectable typed options.

Validation captured during M4:

- `dart analyze packages/llm_dart_provider packages/llm_dart_chat packages/llm_dart_openai packages/llm_dart_core`: passed
- Provider contract, OpenAI option resolver/non-text body, and HTTP chat
  transport focused tests: passed
- Workspace guards, workspace analysis, workspace tests, workspace package
  tests, and consumer smoke passed via `tool/release_readiness.dart`.
- `tool/run_workspace_publish_dry_run.dart --package=llm_dart_provider`
  repeatedly reached pub package validation and then timed out inside the Dart
  pub validator after 300/600 seconds in this Windows environment; no package
  metadata warning/error was emitted before the timeout.
- `git diff --check`: passed
