# Provider Transport Helper Extraction Status

## Goal

Narrow the remaining root-local helper dependencies that still block a staged
community-provider migration.

This note follows the dependency-direction audit and the community migration
boundary freeze. The immediate question is not whether Ollama and ElevenLabs
should move today. The immediate question is which shared helper pieces can
already move downward into `llm_dart_transport` without dragging root
compatibility surfaces with them.

## What Landed First

The shared Dio cancellation adapter now lives in `llm_dart_transport`.

That means:

- `bindDioCancellation(...)` is owned by the transport package
- `DioTransportClient` uses the same helper instead of keeping a private copy
- root/provider code now imports the transport helper directly
- the old root-local `lib/src/dio_cancellation_adapter.dart` file is now only a
  compatibility re-export

This is the first real reduction in provider dependence on root-local
`src/` transport-ish code.

## Why This Helper Belonged In Transport

`bindDioCancellation(...)` only does one thing:

- adapt shared transport cancellation to Dio request cancellation

It does not depend on:

- `LLMConfig`
- legacy extension keys
- provider defaults
- root compatibility models
- root error mapping

That makes it transport infrastructure, not root compatibility logic.

## What This Change Unblocked

After this move, current provider code no longer needs a root-local
`src/dio_cancellation_adapter.dart` implementation file.

This matters because Ollama and ElevenLabs had both depended on that root-local
helper before any package move could even be discussed.

The move does not make them ready for `llm_dart_community`, but it removes one
clear false dependency from the path.

## What Still Cannot Move Yet

### `DioClientFactory`

`lib/utils/dio_client_factory.dart` still depends on root-local compatibility
shaping through:

- `LLMConfig`
- legacy config accessors such as custom transport and raw Dio overrides
- `BaseHttpProvider.createConfiguredDio(...)`

So even though it is transport-heavy code, it is not transport-package-ready
yet.

### `HttpConfigUtils`

`lib/utils/http_config_utils.dart` and its platform-specific adapter helpers
still read root compatibility configuration directly from `LLMConfig` and
legacy extension accessors.

That means the shared HTTP client setup logic is still mixed with root
compatibility configuration ownership.

### `HttpResponseHandler`

`lib/utils/http_response_handler.dart` still maps failures into root `LLMError`
types.

So it is not only transport logic. It still belongs to the root compatibility
layer until error ownership is narrowed further.

## Recommended Next Step

The next extraction should not be another blind helper move.

It should be a small transport-owned configuration object for Dio setup, so the
shared HTTP client creation path can stop reading `LLMConfig` directly.

That would allow the repository to:

1. keep root `LLMConfig` and legacy extension parsing in a thin compatibility
   mapper
2. move the reusable Dio setup implementation into `llm_dart_transport`
3. reduce the remaining reasons why community providers still need root-local
   utility files

## Status

The transport-helper extraction is now in progress, not only planned.

Current state:

- cancellation binding is transport-owned
- remaining root-local blockers are now more clearly narrowed to config shaping,
  configurable Dio creation, and root error mapping
