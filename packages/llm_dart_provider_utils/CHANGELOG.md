# Changelog

## [0.11.0-alpha.1] - 2026-05-21

- Alpha release of the provider utility package.
- Adds shared provider-aware transport helpers for stream decoding, transport
  error projection, and provider-to-transport cancellation bridging.
- Keeps `llm_dart_transport` provider-neutral while giving provider adapters a
  reusable utility seam.
