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
