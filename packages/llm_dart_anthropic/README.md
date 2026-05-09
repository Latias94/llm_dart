# llm_dart_anthropic

Anthropic provider implementations for `llm_dart`.

This package owns the provider-native Anthropic chat/files/tooling surfaces,
typed Anthropic options, and Anthropic-specific request/response codecs.

Use this package when you want the focused Anthropic package boundary directly
instead of the broader root facade.

It can be consumed without a dependency on the root `llm_dart` package. Add
`llm_dart_ai` only when you want the shared generation helper calls.

## Installation

```yaml
dependencies:
  llm_dart_anthropic: ^0.11.0-alpha.1
  llm_dart_ai: ^0.11.0-alpha.1
```

The root `llm_dart` package re-exports the main focused entrypoint through:

- `package:llm_dart/anthropic.dart`
  - includes the `anthropic(...)` factory plus provider-owned Anthropic types

For the larger repository architecture and migration story, start with the root
package README.

## Files

`anthropic(...).files()` is the focused provider-owned file lifecycle surface
for Anthropic beta files:

- `uploadFile(...)` / `uploadBytes(...)`
- `listFiles(...)`
- `getFile(...)`
- `downloadFile(...)`
- `deleteFile(...)`

This is intentionally not a shared cross-provider file-management abstraction.
File IDs, beta headers, download behavior, and lifecycle semantics remain
Anthropic-owned.
