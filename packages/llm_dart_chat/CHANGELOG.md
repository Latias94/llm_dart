# Changelog

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the pure Dart chat runtime package.
- Use this package directly for chat sessions, transports, reader helpers, and
  persistence support outside Flutter.
- Flutter apps can use `llm_dart_flutter` when they want controller adapters on
  top of this runtime.
- Keeps chat sessions on the AI helper layer instead of concrete provider
  implementations, preserving the provider/runtime boundary introduced in this
  alpha.
