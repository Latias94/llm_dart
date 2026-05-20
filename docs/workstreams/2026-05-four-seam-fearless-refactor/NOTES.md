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
