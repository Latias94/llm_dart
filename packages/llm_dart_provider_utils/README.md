# llm_dart_provider_utils

Provider implementation utilities for `llm_dart` adapters.

## What This Package Owns

This package owns provider-facing helpers that sit between provider
implementations and lower-level transport code:

- mapping transport failures into provider `ModelError` values
- decoding JSON SSE language-model streams into provider stream events
- bridging provider cancellation to transport cancellation

## Why This Package Exists

`llm_dart_transport` stays focused on transport-level concerns such as HTTP,
SSE framing, retries, diagnostics, and cancellation primitives. Provider-aware
behavior belongs here so concrete provider packages can share it without making
the transport module depend on provider contracts.

This mirrors the provider utility seam used by mature AI SDKs: transport stays
small and provider-neutral, while provider adapters opt into shared utilities
when they need provider-specific projections.

## Typical Consumers

Use this package when you are implementing a provider package and need to:

- translate `TransportException` into `ModelError`
- decode provider JSON SSE envelopes into `LanguageModelStreamEvent` values
- bind `ProviderCancellation` to a transport request

Application code usually should not import this package directly. Start with
`package:llm_dart/llm_dart.dart`, focused provider packages, or
`llm_dart_chat` unless you are writing a provider adapter.
