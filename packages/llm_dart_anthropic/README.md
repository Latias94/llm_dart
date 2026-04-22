# llm_dart_anthropic

Anthropic provider implementations for `llm_dart`.

This package owns the provider-native Anthropic chat/files/tooling surfaces,
typed Anthropic options, and Anthropic-specific request/response codecs.

Use this package when you want the focused Anthropic package boundary directly
instead of the broader root facade.

The root `llm_dart` package re-exports the main focused entrypoint through:

- `package:llm_dart/anthropic.dart`

For the larger repository architecture and migration story, start with the root
package README.
