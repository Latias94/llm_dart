# 172 OpenAI Language Model Support Extraction

## Why This Slice Exists

After the codec-support extractions, `openai_language_model.dart` still contained a large amount of pure orchestration support logic mixed into the transport facade:

- route selection between Responses and chat-completions
- request-model shaping for OpenRouter online mode
- provider-options normalization and validation
- model-settings resolution by profile
- request-header construction
- JSON object response decoding

That logic is important, but most of it is not transport execution itself.

## What Changed

This slice adds:

- `packages/llm_dart_openai/lib/src/openai_language_model_support.dart`

The support module now owns the pure language-model preparation layer:

- `ResolvedOpenAILanguageModelCall`
- route decision between Responses and chat-completions
- request model-id shaping
- provider-options resolution and validation
- profile-aware model-settings resolution
- default/request header builders
- shared response-format adaptation
- JSON object response decoding

`openai_language_model.dart` now reads more clearly as the transport-facing facade that:

- resolves one call plan
- delegates request encoding to the selected codec
- sends transport requests
- delegates response/stream decoding back to codecs

## Boundary Decision

This extraction does **not** create a heavy runtime abstraction or a new public routing layer.

The support file remains package-local and keeps pure preparation logic separate from:

- codec-owned request/response protocol details
- transport-owned HTTP/SSE execution
- public provider factory APIs

So the shape becomes clearer without widening the surface area.

## Why This Is Better

- makes the main language-model class easier to audit as a facade
- keeps route and option normalization logic testable and reusable
- reduces the risk of drifting request-shaping behavior between `generate(...)` and `stream(...)`
- reinforces the intended package structure:
  - request planning
  - endpoint codec logic
  - transport execution facade

## Non-Goals

This slice does not:

- change public API behavior
- change route policy between Responses and chat-completions
- introduce a generic cross-provider request planner
- move transport calls out of `OpenAILanguageModel`

## Follow-Up

The next worthwhile pass is no longer another automatic extraction. It is a short ownership audit of whether the remaining `OpenAILanguageModel` body is now at the right size and whether similar request-planning support should also exist for other provider families, but only where the same pressure actually exists.
