# 115. Root Error Handler Compatibility Ownership

## Question

Should root `HttpResponseHandler` and root `DioErrorHandler` now be split into:

- provider-owned parsing and error mapping everywhere
- or a more transport-owned generic failure layer

so the root package can remove more of its residual Dio-based compatibility
infrastructure immediately?

## Conclusion

For this refactor stage, `HttpResponseHandler` and `DioErrorHandler` should stay
root compatibility-owned.

More precisely:

- transport should continue owning transport infrastructure such as cancellation
  binding, configurable Dio setup, logging sanitization, and JSON-object decode
- provider packages should continue owning their modern request/response/error
  handling inside package-owned model implementations
- root `HttpResponseHandler` and root `DioErrorHandler` should remain the
  compatibility bridge for root legacy providers that still map into root
  `LLMError` types

So the next step is **not** to promote these handlers into a new shared
transport abstraction.

## Why

## 1. Their Remaining Responsibility Is No Longer Transport Infrastructure

The transport-owned parts have already been extracted.

Today, `llm_dart_transport` already owns the reusable lower-level pieces:

- `bindDioCancellation(...)`
- `DioHttpClientFactory`
- `ProviderDioClientFactory`
- `LogSanitizer`
- `JsonObjectResponseDecoder`

That means the remaining value inside root `HttpResponseHandler` and root
`DioErrorHandler` is not “how to send HTTP requests” or “how to decode bytes”.

Their remaining value is compatibility-specific mapping into:

- root `LLMError`
- root legacy provider behavior
- root compatibility request/response flows

That is compatibility ownership, not transport ownership.

## 2. Modern Provider Packages Already Avoid This Layer

The workspace provider packages under `packages/` do not depend on these root
error helpers.

Their modern model implementations already live outside the root package and use
their own package-owned request/response logic above the shared core and
transport layers.

That is an important signal:

- these root handlers are not missing shared infrastructure for the modern API
- they are residual compatibility utilities for the root package

## 3. Current Usage Is Concentrated In Root Legacy Providers

Current usage is still concentrated in root compatibility-era clients such as:

- `lib/providers/google/client.dart`
- `lib/providers/anthropic/client.dart`
- `lib/providers/groq/client.dart`
- `lib/providers/xai/client.dart`
- `lib/providers/deepseek/client.dart`
- `lib/providers/openai/client.dart`
- `lib/providers/ollama/client.dart`
- root Ollama compatibility modules

This is exactly the usage pattern we should expect from a compatibility-owned
utility layer.

It is also why removing these helpers prematurely would not simplify the modern
architecture. It would mostly just force a large legacy-client rewrite before
the compatibility layer is ready to disappear.

## 4. Promoting Them Into Transport Would Mix Layers Again

If root `HttpResponseHandler` or root `DioErrorHandler` were moved downward into
`llm_dart_transport`, transport would again become aware of compatibility-era
error semantics such as:

- root `LLMError`
- root `AuthError`
- root `RateLimitError`
- root `QuotaExceededError`
- root `ModelNotAvailableError`

That would re-couple transport to a root compatibility contract.

The transport package should stay lower-level than that.

## 5. Forcing Immediate Provider-Wide Splits Would Also Be Premature

The opposite extreme would also be wrong:

- rewrite every root legacy provider client to own all parsing/error mapping
  separately right now

That would create a lot of duplicate migration churn in code that is already on
the compatibility side of the architecture.

The more honest rule is:

- modern provider packages own modern mapping
- root compatibility providers may continue sharing a root compatibility error
  layer until the migration window narrows further

## 6. This Also Matches The Useful `repo-ref/ai` Lesson

The useful reference lesson is again ownership, not identical file structure.

In `repo-ref/ai`, provider-specific request shaping and failure handling live in
provider packages rather than inside one broad app-facing compatibility layer.

For our repository, the closest honest mapping is:

- provider packages own modern model-path behavior
- root compatibility handlers exist only for the root legacy layer

That means these root handlers should shrink in relevance over time, but they
should not be elevated into a new cross-workspace shared abstraction.

## What Should Happen Next

The repository should treat these handlers as:

- compatibility-only utilities
- allowed for root legacy providers
- not a design basis for new package-owned APIs

If desired later, their code location may become more explicitly
compatibility-namespaced, but that is a presentation cleanup, not a boundary
change.

## What Should Not Happen

Do not:

- move root `LLMError` mapping into `llm_dart_transport`
- make modern provider packages depend on root `HttpResponseHandler`
- reopen provider-package design just to reuse a root legacy error helper
- spend the breaking window duplicating all legacy-provider error mapping only
  for cosmetic dependency slimming

## Recommended Follow-Up Order

After freezing this boundary, the next cleanup order should be:

1. keep shrinking the root compatibility/provider implementation footprint
2. remove root `dio` / `logging` only after those legacy users are gone
3. optionally relabel or relocate these handlers under clearer compatibility
   ownership if that improves code readability during the migration window

## Impact On The Workstream

This closes the remaining error-handler question more explicitly:

- root `HttpResponseHandler` remains compatibility-owned
- root `DioErrorHandler` remains compatibility-owned
- transport keeps only lower-level transport primitives
- modern provider packages should keep owning their own modern error behavior
  instead of depending on root compatibility handlers
