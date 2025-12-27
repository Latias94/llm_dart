# llm_dart_core

Core interfaces and shared models for the `llm_dart` ecosystem.

This package contains:

- Shared request/response models (messages, tools, usage)
- Stream part types
- Provider registry abstractions and config primitives

It intentionally does **not** include:

- Provider implementations
- HTTP/SSE client code

## Install

```bash
dart pub add llm_dart_core
```

Most users should prefer `llm_dart` (suite) or `llm_dart_ai` (task APIs).

