# Provider Transport Helper Extraction Status

## Goal

Narrow the remaining root-local helper dependencies that still block a staged
community-provider migration.

This note follows the dependency-direction audit and the community migration
boundary freeze. The immediate question is not whether Ollama and ElevenLabs
should move today. The immediate question is which shared helper pieces can
already move downward into `llm_dart_transport` without dragging root
compatibility surfaces with them.

## What Has Landed So Far

### 1. The shared Dio cancellation adapter now lives in `llm_dart_transport`

That means:

- `bindDioCancellation(...)` is owned by the transport package
- `DioTransportClient` uses the same helper instead of keeping a private copy
- root/provider code now imports the transport helper directly
- the old root-local `lib/src/dio_cancellation_adapter.dart` file is now only a
  compatibility re-export

### 2. The reusable configurable Dio setup path now also lives in transport

The repository now has transport-owned:

- `DioHttpClientConfig`
- `DioHttpClientFactory`
- transport-owned platform adapter helpers for IO and web

That means:

- reusable Dio setup logic no longer lives only under the root package
- root `HttpConfigUtils` is now a thin compatibility mapper from `LLMConfig`
  into a transport-owned configuration object
- the old root-local platform adapter helper files are no longer needed

### 3. Root `DioClientFactory` no longer depends on `BaseHttpProvider`

The remaining compatibility-oriented provider factory still lives in the root
package, but it now builds configured Dio instances through the transport-owned
factory instead of routing through `BaseHttpProvider.createConfiguredDio(...)`.

### 4. Provider-facing Dio strategy and factory abstractions now live in
`llm_dart_transport`

The transport package now also owns:

- `ProviderDioStrategy`
- `BaseProviderDioStrategy`
- `DioEnhancer`
- `ProviderDioClientFactory`
- `DioClientOverrides`

That means:

- provider `dio_strategy.dart` files no longer need a root-local utility import
- provider clients can build configured Dio instances through transport-owned
  APIs directly
- the root `DioClientFactory` is now a compatibility wrapper instead of the
  implementation home

### 5. The shared UTF-8 streaming decoder now also lives in
`llm_dart_transport`

The transport package now also owns:

- `Utf8StreamDecoder`
- `Utf8StreamDecoderExtension`

That means:

- provider clients no longer need a root-local UTF-8 streaming helper
- the root `utils/utf8_stream_decoder.dart` file is now only a compatibility
  re-export

### 6. Log sanitization and JSON-object response decoding primitives now also
live in `llm_dart_transport`

The transport package now also owns:

- `LogSanitizer`
- `JsonObjectResponseDecoder`

That means:

- sensitive-request logging rules no longer need to live only in the root
  package
- JSON-object response parsing no longer needs to be implemented only inside
  root `HttpResponseHandler`
- root `utils/log_sanitizer.dart` is now a compatibility re-export
- root `HttpResponseHandler` is now a narrower compatibility wrapper around
  transport-owned parsing plus root-owned `LLMError` mapping

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

After these moves, current provider code no longer needs:

- a root-local `src/dio_cancellation_adapter.dart` implementation
- a root-local reusable Dio setup implementation
- root-local platform adapter helper implementations for configurable Dio setup
- a root-local provider-facing Dio strategy/factory implementation

This matters because Ollama and ElevenLabs had both depended on that root-local
transport-ish utility layer before any package move could even be discussed.

The moves do not make them ready for `llm_dart_community`, but they remove two
clear false dependencies from the path:

- request cancellation binding
- reusable configurable Dio setup

## What Still Cannot Move Yet

### `DioClientFactory`

`lib/utils/dio_client_factory.dart` is now only a compatibility wrapper, but
the root compatibility layer still owns legacy override shaping through:

- `LLMConfig`
- legacy config accessors such as custom transport and raw Dio overrides

That means provider clients no longer need this file directly, but the old
root compatibility surface still does.

### `HttpResponseHandler`

`lib/utils/http_response_handler.dart` still maps failures into root `LLMError`
types.

So it is not only transport logic. It still belongs to the root compatibility
layer until error ownership is narrowed further.

## Recommended Next Step

The next step should not reopen the already-landed transport-helper work.

It should narrow the remaining compatibility ownership:

1. decide whether the new root `legacy_dio_client_overrides` shaping should
   remain a compatibility-only mapper or be replaced by provider-owned modern
   config/override surfaces
2. decide whether `HttpResponseHandler` stays compatibility-owned because of
   `LLMError`, or whether provider packages should eventually own more of their
   response/error mapping directly

## Status

The transport-helper extraction is now materially landed.

Current state:

- cancellation binding is transport-owned
- configurable Dio setup is transport-owned
- provider-facing Dio strategy/factory abstractions are transport-owned
- the shared UTF-8 stream decoder is transport-owned
- shared log sanitization and JSON-object response decoding are transport-owned
- root `HttpConfigUtils` is now a compatibility mapper, not the implementation
- root `DioClientFactory` is now a compatibility wrapper, not the
  implementation home
- Ollama and ElevenLabs now also own their local default values instead of
  importing root `provider_defaults.dart`
- remaining root-local blockers are now more clearly narrowed to compatibility
  config shaping around custom transport/Dio overrides and the remaining
  root-owned `LLMError` mapping
