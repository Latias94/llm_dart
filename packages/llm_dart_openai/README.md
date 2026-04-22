# llm_dart_openai

OpenAI-family provider implementations for `llm_dart`.

This package owns the provider-native modern surfaces for:

- OpenAI
- OpenRouter
- DeepSeek
- Groq
- xAI
- Phind compatibility facades on the OpenAI-family transport boundary

Use this package when you want provider-owned OpenAI-family settings, native
tools, custom parts, profiles, and direct model entrypoints outside the broad
root compatibility shell.

The root `llm_dart` package re-exports the main focused entrypoint through:

- `package:llm_dart/openai.dart`

For the full repository-level migration and architecture story, start with the
root package README.
