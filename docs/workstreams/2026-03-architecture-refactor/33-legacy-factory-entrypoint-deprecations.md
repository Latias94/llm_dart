# Legacy Factory Entrypoint Deprecations

## Goal

This note freezes which root-package factory-style convenience helpers should now be treated as deprecated.

These helpers are not the same as the base compatibility constructors.

The target is narrower:

- keep one honest compatibility constructor per legacy provider family where the old root surface is still needed
- stop recommending the extra preset helpers that only encode chat-model shortcuts or legacy convenience profiles

## 1. Why These Deprecations Exist

The repository now has a stable primary chat entry:

- `AI.openai(...)`
- `AI.openRouter(...)`
- `AI.deepSeek(...)`
- `AI.groq(...)`
- `AI.xai(...)`
- `AI.phind(...)`
- `AI.google(...)`
- `AI.anthropic(...)`

Those facades already replace many old root-package chat preset helpers that used to exist only to:

- pick a default model
- preconfigure a reasoning/chat/vision/code preset
- hide provider-family selection behind extra root-package constructors

Keeping every one of those preset helpers as if they were still stable design guidance would blur the architecture boundary:

- the stable primary path is the `AI` facade plus package-owned `chatModel(...)`
- the old root-package provider constructors are compatibility surfaces
- the extra preset helpers are compatibility conveniences on top of compatibility surfaces

So they should now start warning callers away.

## 2. Deprecated Now

The following preset helpers should now carry `@Deprecated` markers.

### OpenAI-family preset aliases in `providers/openai/openai.dart`

- `createOpenRouterProvider()`
- `createGroqProvider()`
- `createDeepSeekProvider()`

Reason:

- the stable root facade already exposes `AI.openRouter(...)`, `AI.groq(...)`, and `AI.deepSeek(...)`
- these old helpers are only compatibility aliases over the old `OpenAIProvider` surface

### Anthropic preset helpers

- `createAnthropicChatProvider()`
- `createAnthropicReasoningProvider()`

Reason:

- the stable path is `AI.anthropic(...).chatModel(...)`
- the preset helpers only encode model-selection and reasoning convenience on the old provider surface

### Google preset helpers

- `createGoogleChatProvider()`
- `createGoogleReasoningProvider()`
- `createGoogleVisionProvider()`

Reason:

- the stable path is `AI.google(...).chatModel(...)`
- these helpers are chat preset shortcuts, not stable architecture primitives

### DeepSeek preset helpers

- `createDeepSeekChatProvider()`
- `createDeepSeekReasoningProvider()`

Reason:

- the stable path is `AI.deepSeek(...).chatModel(...)`
- the preset helpers are legacy shortcuts over the old provider class

### Groq preset helpers

- `createGroqChatProvider()`
- `createGroqFastProvider()`
- `createGroqVisionProvider()`
- `createGroqCodeProvider()`

Reason:

- the stable path is `AI.groq(...).chatModel(...)`
- these helpers are only old model-preset wrappers

### xAI preset helpers

- `createGrokVisionProvider()`

Reason:

- the stable path is `AI.xai(...).chatModel(...)`
- the old helper is only a legacy Grok vision preset

The xAI legacy search helpers were already deprecated earlier:

- `createXAISearchProvider()`
- `createXAILiveSearchProvider()`

### Phind preset helpers

- `createPhindCodeProvider()`
- `createPhindExplainerProvider()`

Reason:

- the stable path is `AI.phind(...).chatModel(...)`
- these helpers only encode old prompt/model presets for the legacy provider surface

### Ollama preset helpers

- `createOllamaChatProvider()`
- `createOllamaVisionProvider()`
- `createOllamaCodeProvider()`
- `createOllamaEmbeddingProvider()`
- `createOllamaCompletionProvider()`
- `createOllamaReasoningProvider()`

Reason:

- `llm_dart_community` now owns real package-owned modern Ollama shared-capability
  surfaces for chat and embeddings
- the remaining preset helpers are still compatibility conveniences on top of
  the old root provider surface
- callers that still need the old root provider should use
  `createOllamaProvider(...)` directly instead of another preset wrapper

### ElevenLabs preset helpers

- `createElevenLabsTTSProvider()`
- `createElevenLabsSTTProvider()`
- `createElevenLabsCustomVoiceProvider()`
- `createElevenLabsStreamingProvider()`

Reason:

- `llm_dart_community` now owns real package-owned modern ElevenLabs shared-capability
  surfaces for speech generation and transcription
- the remaining preset helpers are compatibility conveniences on top of the old
  root provider surface
- callers that still need the old root provider should use
  `createElevenLabsProvider(...)` directly instead of another preset wrapper

## 3. Not Deprecated Yet

The following surfaces should stay available without new deprecation markers for now:

- the base compatibility constructors such as `createAnthropicProvider()`, `createGoogleProvider()`, `createDeepSeekProvider()`, `createGroqProvider()`, `createPhindProvider()`, and `createXAIProvider()`
- `createOpenAIProvider()` because the root package still owns old non-chat OpenAI capabilities that the new primary API does not replace yet
- `createGoogleImageGenerationProvider()` and `createGoogleEmbeddingProvider()` because the stable primary API does not yet replace those old root-package entry paths
- `buildOpenAIResponses()` because the new stable root facade does not yet replace the old Responses-oriented root provider surface
- `buildGoogleTTS()` because the new stable root facade does not yet replace the old Google TTS root provider surface

This is intentional.

Deprecation should only happen where the architectural replacement is already real.

## 4. Migration Direction

When a deprecated preset helper is encountered, the migration order should be:

1. Prefer the stable `AI.*(...).chatModel(...)` path when the caller only needs migrated chat behavior.
2. If the caller still depends on the old root-package provider surface, move to the base compatibility constructor for that provider family.
3. Stop adding new examples, README snippets, or tests that teach the deprecated preset helper as the recommended API.

## 5. Current Conclusion

The repository should now distinguish clearly between:

- stable primary chat entrypoints
- base compatibility constructors
- deprecated compatibility preset helpers

That split is more honest than keeping every historical root helper equally blessed.
