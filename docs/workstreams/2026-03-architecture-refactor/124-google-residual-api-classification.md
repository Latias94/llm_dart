# 124. Google Residual API Classification

## Question

After relocating the Google root shell, legacy modules, and provider-focused
entrypoints, which remaining Google APIs should still count as real migration
targets for `llm_dart_google`, and which should stay explicitly classified as
root compatibility-only residual surface?

## Why This Review Matters

The recent Google cleanup made the ownership structure much clearer:

- `llm_dart_google` already owns the modern shared-capability mainline
- the root package now visibly hosts only the compatibility-era Google surface

That still leaves an important product question:

- which remaining Google compatibility APIs are only old interface baggage
- which still reveal a real provider-owned capability gap worth closing later

Without that classification, the repository risks treating every old Google
method as unfinished migration work, which would recreate the same coupling
problem under a different directory.

## What Was Reviewed

Root compatibility-owned Google surface:

- `lib/src/compatibility/providers/google/provider_compat.dart`
- `lib/src/compatibility/providers/google/chat.dart`
- `lib/src/compatibility/providers/google/embeddings.dart`
- `lib/src/compatibility/providers/google/images.dart`
- `lib/src/compatibility/providers/google/tts.dart`
- `lib/providers/google/config.dart`
- `lib/providers/google/builder.dart`
- `lib/providers/google/google.dart`

Modern package-owned Google surface:

- `packages/llm_dart_google/lib/src/google.dart`
- `packages/llm_dart_google/lib/src/google_language_model.dart`
- `packages/llm_dart_google/lib/src/google_generate_content_codec.dart`
- `packages/llm_dart_google/lib/src/google_embedding_model.dart`
- `packages/llm_dart_google/lib/src/google_image_model.dart`
- `packages/llm_dart_google/lib/src/google_speech_model.dart`
- `packages/llm_dart_google/lib/src/google_options.dart`

Reference package signals from `repo-ref/ai`:

- `repo-ref/ai/packages/google/src/google-provider.ts`
- `repo-ref/ai/packages/google/src/google-generative-ai-language-model.ts`
- `repo-ref/ai/packages/google/src/google-generative-ai-image-model.ts`
- `repo-ref/ai/packages/google/src/google-supported-file-url.ts`

## Classification Matrix

| Legacy/root Google surface | Modern package-owned status | Classification | Recommended direction |
| --- | --- | --- | --- |
| Chat, tool calling, reasoning, structured output, Google native tools, mixed-tool replay, search options | Already owned by `Google.chatModel(...)` plus `GoogleGenerateTextOptions` | migrated modern mainline | keep only legacy `ChatCapability` and routing glue in root compatibility |
| Embeddings plus `taskType`, `title`, and dimensions shaping | Already owned by `Google.embeddingModel(...)` plus `GoogleEmbedOptions` and shared dimensions | migrated modern mainline | keep root embedding helpers as compatibility-only constructor and interface wrappers |
| Text-to-image generation | Already owned by `Google.imageModel(...)` | migrated modern mainline | keep root image-generation wrappers only for old `ImageGenerationCapability` compatibility |
| Non-streaming speech generation, including multi-speaker request shaping | Already owned by `Google.speechModel(...)` plus `GoogleSpeechOptions` and settings | migrated modern mainline | keep root `GoogleTTSCapability.generateSpeech(...)` only as legacy interface compatibility |
| Legacy `ImageEditRequest` and `ImageVariationRequest` paths | **Not** fully owned by `llm_dart_google` yet | real provider-owned gap | do not widen the shared image contract blindly; decide later whether to add a provider-owned modern image-edit helper or a richer shared image request model |
| Legacy streamed TTS events and `GoogleTTSCapability.generateSpeechStream(...)` | **Not** covered by shared `SpeechModel` | real provider-owned gap | if demand appears, add a provider-owned helper in `llm_dart_google`; do not force it into the shared `SpeechModel` first |
| Voice catalog and supported-language helpers | Only legacy static/convenience surface today | provider-specific convenience, not shared parity work | keep compatibility-only unless a concrete product need justifies provider-owned helpers |
| `GoogleFile`, `uploadFile(...)`, and `getOrUploadFile(...)` helper paths | No typed modern Dart surface today; reference package prefers supported file URLs instead of upload helpers | compatibility-only residual for now | keep out of shared core; only add a provider-owned utility later if real app usage proves a stable file-handle contract |
| Legacy `maxInlineDataSize` and old `ImageUrlMessage` fallback text behavior | tied to old `ChatMessage` compatibility semantics | compatibility-only residual | do not migrate these shapes into `llm_dart_google`; they belong to the old message surface |
| Legacy constructor/factory/builder DSL (`GoogleConfig`, `GoogleLLMBuilder`, `createGoogle*Provider(...)`) | Modern provider construction already exists via `AI.google(...)` and `llm_dart_google` | compatibility-only residual | keep on root/`legacy.dart`; do not recreate this DSL in the provider package |
| Legacy convenience methods such as `generateImage()` returning data URLs and capability getters like `supportsImageEditing` | No direct modern equivalent, and not needed for the shared model contract | compatibility-only residual | keep only while the old image capability surface exists |

## What The Matrix Shows

### 1. Most real Google migration work is already done

The large capability families that justified `llm_dart_google` already have a
clear modern home:

- chat
- embeddings
- image generation
- non-streaming speech generation

That means Google is no longer blocked by a broad modern-surface gap.

### 2. The remaining open items are narrow and provider-shaped

The real remaining Google questions are now much smaller:

- should Gemini image editing and variation gain a provider-owned modern path
- should streamed TTS gain a provider-owned modern path
- should any Google file-upload utility become a provider-owned helper at all

These are provider-shaped extras, not missing shared-capability parity.

### 3. `repo-ref/ai` points in the same direction

The reference package does **not** treat every Google-specific path as a
provider root API obligation.

Useful signals from the reference:

- the provider surface centers on model factories, not legacy config DSL
- supported Google file URLs are treated as prompt input capability, not as a
  public upload-helper API
- Gemini image editing is handled through the image model path when the request
  shape can carry files

That supports the same conclusion here:

- avoid migrating old root helper APIs mechanically
- close only the provider-owned gaps that still matter as real product APIs

### 4. The main blocker for Google image edit migration is the request contract

The current root compatibility layer exposes:

- `ImageEditRequest`
- `ImageVariationRequest`
- OpenAI-shaped image input types

But the modern shared image surface still centers on plain image generation.

So the honest next question is not “move the old methods as-is.”

It is:

- whether Google should get a provider-owned modern image-edit helper
- or whether the shared image request model should later grow file-based edit
  input in a provider-honest way

Until that is decided, `editImage(...)` and `createVariation(...)` should stay
classified as root compatibility APIs.

### 5. The main blocker for Google streamed TTS migration is the shared speech boundary

`llm_dart_google` already owns normal speech generation through the shared
`SpeechModel`.

What it does **not** own is the old streaming/evented TTS contract around:

- `GoogleTTSStreamEvent`
- `generateSpeechStream(...)`
- voice catalog convenience helpers

That is a provider-owned extension question, not a missing shared
speech-capability migration.

## Recommended Near-Term Policy

### Treat these as complete modern migrations

- chat
- embeddings
- text-to-image generation
- non-streaming speech generation

### Treat these as root compatibility-only residual APIs for now

- `GoogleConfig` and the legacy Google builder DSL
- `createGoogle*Provider(...)` preset constructors
- old `GoogleChat` helper behaviors tied to `ChatMessage` compatibility
- `GoogleFile` upload/cache helpers
- legacy image convenience getters and data-URL helpers
- voice catalog convenience helpers unless concrete app demand appears

### Treat these as explicit provider-owned gap candidates, not shared-core work

- modern Google image editing / variation
- modern Google streamed TTS
- possibly a provider-owned Google file-handle or file-upload utility

## Practical Next Slice

The next Google implementation step should **not** be another broad file move.

It should be one of these two focused decisions:

1. decide whether Google image editing deserves a provider-owned modern helper
   in `llm_dart_google`
2. or decide whether Google streamed TTS deserves a provider-owned modern
   helper outside the shared `SpeechModel`

Between those two, image editing is the better structural next slice because it
is the clearest remaining place where the reference package and our package now
diverge meaningfully.

## Conclusion

Google is now structurally close to the target architecture.

The remaining Google root surface should no longer be read as one big unfinished
migration block.

Most of it is now best classified as compatibility-only residual API, while the
real remaining migration candidates are only:

- image editing / variation
- streamed TTS
- any future provider-owned file helper

That classification should guide the next breaking-round work.
