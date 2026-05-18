# Provider Implementation Kit Audit

## Current Source Findings

The adapter splits have made repeated provider implementation needs visible:

- provider option type resolution
- header merging
- base URL normalization
- route URI construction
- JSON object coercion
- byte and base64 response decoding
- multipart body construction
- media type and filename inference
- response metadata construction
- provider metadata namespace construction
- SSE, NDJSON, and UTF-8 stream decoding
- transport error projection

The previous policy deferred publishing `llm_dart_provider_utils` until at
least two providers proved a stable seam. That threshold is now met for some
helpers, but not all helpers should become public API.

## Reference Comparison Targets

Use these `repo-ref/ai` areas as comparison material:

- `packages/provider-utils/src/post-to-api.ts`
- `packages/provider-utils/src/response-handler.ts`
- `packages/provider-utils/src/parse-json.ts`
- `packages/provider-utils/src/parse-json-event-stream.ts`
- `packages/provider-utils/src/convert-to-form-data.ts`
- `packages/provider-utils/src/media-type-to-extension.ts`
- `packages/provider-utils/src/without-trailing-slash.ts`
- `packages/provider-utils/src/parse-provider-options.ts`

## Candidate Helper Categories

### Strong Candidates For Internal Shared Helpers

- JSON object response coercion with provider-specific response names
- case-insensitive header lookup
- immutable provider metadata namespace construction helpers
- media type to file extension inference
- base64 and byte list validation helpers
- header merge helpers that preserve provider defaults and call overrides

These already appear across multiple providers and have low provider-specific
policy content.

### Keep Local For Now

- route URI construction
- model-family route selection
- provider-specific request body construction
- provider-specific response metadata field names
- provider-specific warning policy
- provider-specific option conflict rules

These encode product policy and should stay close to the provider adapter.

### Public Utility Package Candidates

No helper should be made public until:

- at least two provider packages use it
- tests define the helper contract independently from one provider
- the helper has no hidden provider policy
- publishing it would reduce user-facing or provider-author friction

The likely path is an internal implementation kit first, then public
`llm_dart_provider_utils` only if external provider authors need the same
contract.

## Proposed First Slice

Write a helper inventory table before extracting code:

- helper name
- current duplicate locations
- proposed owner
- public/private status
- tests needed
- reason not to keep local

This avoids extracting shallow pass-through modules that merely move complexity
away from the provider that owns it.
