# llm_dart_google

Google provider implementations for `llm_dart`.

This package owns the provider-native Google/Gemini model surfaces, typed
Google options, message mapping helpers, Google-specific replay/runtime
behavior, and additive provider-owned image-editing helpers.

Use this package when you want direct access to the focused Google package
boundary instead of the broader root facade.

That includes:

- `Google(...).chatModel(...)`, `embeddingModel(...)`, `imageModel(...)`, and
  `speechModel(...)`
- Google-owned options such as `GoogleGenerateTextOptions`,
  `GoogleImageOptions`, `GoogleEmbedOptions`, and `GoogleSpeechOptions`
- provider-aware UI helpers such as `GoogleMessageMapper`
- provider-owned image editing and variation through
  `GoogleImageModel.edit(...)` and `createVariation(...)`

The root `llm_dart` package re-exports the main focused entrypoint through:

- `package:llm_dart/google.dart`

For the larger repository architecture and migration story, start with the root
package README.
