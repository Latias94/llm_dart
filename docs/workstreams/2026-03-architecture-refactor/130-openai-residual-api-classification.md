# 130. OpenAI Residual API Classification

## Question

After the OpenAI-family chat migration, native-tool additions, persistence
subset, and output-helper work landed in `llm_dart_openai`, which remaining
root OpenAI APIs should still count as real migration targets for
`llm_dart_openai`, and which should stay explicitly classified as
compatibility-only residual surface?

## Why This Review Matters

OpenAI is now the broadest remaining hybrid host in the root package.

That makes it easy to misread the remaining root surface as one large unfinished
migration block, even though it now actually mixes four different categories:

- already-migrated shared-capability modern surfaces
- provider-owned modern extras already landed in `llm_dart_openai`
- genuine provider-owned modern gaps that may still be worth closing
- broad compatibility-only residual APIs that should not be copied into the new
  package mechanically

Without that classification, a future OpenAI thinning pass would likely blur
shared-capability models, provider-specific extras, and legacy interfaces again.

## What Was Reviewed

Root compatibility-owned OpenAI surface:

- `lib/providers/openai/provider.dart`
- `lib/providers/openai/chat.dart`
- `lib/providers/openai/responses.dart`
- `lib/providers/openai/embeddings.dart`
- `lib/providers/openai/images.dart`
- `lib/providers/openai/audio.dart`
- `lib/providers/openai/files.dart`
- `lib/providers/openai/models.dart`
- `lib/providers/openai/moderation.dart`
- `lib/providers/openai/assistants.dart`
- `lib/providers/openai/completion.dart`
- `lib/providers/openai/openai.dart`
- `lib/providers/openai/builtin_tools.dart`

Modern package-owned OpenAI surface:

- `packages/llm_dart_openai/lib/src/openai.dart`
- `packages/llm_dart_openai/lib/src/openai_language_model.dart`
- `packages/llm_dart_openai/lib/src/openai_chat_completions_codec.dart`
- `packages/llm_dart_openai/lib/src/openai_responses_codec.dart`
- `packages/llm_dart_openai/lib/src/openai_embedding_model.dart`
- `packages/llm_dart_openai/lib/src/openai_image_model.dart`
- `packages/llm_dart_openai/lib/src/openai_speech_model.dart`
- `packages/llm_dart_openai/lib/src/openai_transcription_model.dart`
- `packages/llm_dart_openai/lib/src/openai_native_tools.dart`
- `packages/llm_dart_openai/lib/src/openai_custom_part.dart`
- `packages/llm_dart_openai/lib/src/openai_message_mapper.dart`

Reference package signals from `repo-ref/ai`:

- `repo-ref/ai/packages/openai/src/openai-provider.ts`
- `repo-ref/ai/packages/openai/src/chat/*`
- `repo-ref/ai/packages/openai/src/responses/*`
- `repo-ref/ai/packages/openai/src/image/openai-image-model.ts`
- `repo-ref/ai/packages/openai/src/tool/*`

## Classification Matrix

| Legacy/root OpenAI surface | Modern package-owned status | Classification | Recommended direction |
| --- | --- | --- | --- |
| Chat-completions and Responses text generation, reasoning compatibility, `systemMessageMode`, `serviceTier`, `logprobs`, user multimodal subset, Responses persistence subset, native-tool declarations, and OpenAI custom output helpers | Already owned by `OpenAI.chatModel(...)`, `OpenAIGenerateTextOptions`, native-tool types, and OpenAI custom parser/mapper helpers | migrated modern mainline | keep only legacy `ChatCapability` routing, compatibility gating, and old `ChatMessage` replay glue in root |
| Embeddings | Already owned by `OpenAI.embeddingModel(...)` | migrated modern mainline | keep root embedding helpers only for old capability interfaces and compatibility wrappers |
| Text-to-image generation | Already owned by `OpenAI.imageModel(...)` | migrated modern mainline | keep root image-generation wrappers only for old `ImageGenerationCapability` compatibility |
| Speech generation and transcription | Already owned by `OpenAI.speechModel(...)` and `OpenAI.transcriptionModel(...)` | migrated modern mainline | keep root audio wrappers only for old audio capability interfaces and convenience methods |
| OpenAI built-in tool declarations (`web_search`, `file_search`, `computer_use`, `image_generation`, `mcp`, `code_interpreter`) | Already owned by `llm_dart_openai` | migrated provider-owned modern extras | keep root built-in tool DSL only as compatibility duplicate while old builder/config flows still exist |
| OpenAI image editing and variation (`editImage`, `createVariation`, mask support) | **Not** mirrored by `llm_dart_openai`; `repo-ref/ai` image model already supports `/images/edits` | real provider-owned gap | do not widen shared `ImageModel` blindly; consider a provider-owned modern edit helper on the concrete `OpenAIImageModel` |
| Generic file CRUD (`uploadFile`, `listFiles`, `deleteFile`, content download, storage helpers) | **Not** present in `llm_dart_openai`; not part of `repo-ref/ai` provider baseline either | compatibility-only residual for now | keep out of shared core; only add a provider-owned utility later if concrete app usage proves a stable file-management contract is worth it |
| Responses lifecycle CRUD (`getResponse`, `deleteResponse`, `listInputItems`, continue/fork helpers) | Persistence policy is package-owned, but explicit response CRUD helpers are still root-only | provider-specific convenience, not migration-critical | keep compatibility-only for now unless a concrete app need appears for a typed provider-owned response-management helper |
| Moderation APIs | **Not** present in `llm_dart_openai`; not part of `repo-ref/ai` provider baseline | compatibility-only residual for now | keep out of the modern package unless a dedicated provider-owned moderation helper is justified by product demand |
| Assistants CRUD | **Not** present in `llm_dart_openai`; not part of the modern reference provider surface | compatibility-only residual | keep on root/`legacy.dart`; do not treat Assistants as unfinished shared-capability migration work |
| Legacy completions endpoint (`CompletionCapability`, `/completions`) | `repo-ref/ai` still has a completion model, but `llm_dart` intentionally has no shared `CompletionModel` modern path | compatibility-only residual under current architecture | keep compatibility-only unless the project later decides to add a provider-owned or shared completion model intentionally |
| Model listing and model-catalog helpers | **Not** present in `llm_dart_openai`; not part of the normal reference provider surface | provider-specific convenience, not shared parity work | keep compatibility-only for now; only add a provider-owned catalog helper if real product need appears |
| Voice catalogs, supported-language helpers, embedding-dimensions convenience, `checkModel()`, and suggestion generation | convenience-only root helpers | compatibility-only residual | keep only while the legacy root provider surface exists; do not recreate them in the provider package automatically |
| Legacy config/builder/factory DSL and preset constructors (`OpenAIConfig`, `OpenAIBuilder`, `createOpenAIProvider`, Azure/Copilot/Together helpers, etc.) | Modern provider construction already exists via `AI.openAI(...)`, profiles, and `llm_dart_openai` | compatibility-only residual | keep on root/`legacy.dart`; do not recreate this DSL in the provider package |

## What The Matrix Shows

### 1. Most real OpenAI migration work is already done

The broad capability families that justified `llm_dart_openai` already have a
clear modern home:

- chat-completions
- Responses
- embeddings
- image generation
- speech
- transcription
- OpenAI built-in tool declaration surfaces
- OpenAI output parsing and Flutter/app-facing helper mapping

That means OpenAI is no longer blocked by a broad shared-capability migration
gap.

### 2. The remaining root OpenAI surface is heterogeneous, not uniformly "unfinished"

The root OpenAI provider still looks large because it mixes:

- old capability interfaces
- convenience helpers
- provider-specific admin or storage APIs
- long-tail legacy endpoints

Those do not all deserve package migration.

### 3. `repo-ref/ai` points toward restraint, not blanket surface cloning

The reference provider does expose a broad OpenAI package, but its center of
gravity is still:

- text models
- embeddings
- images
- speech and transcription
- provider-owned built-in tools

It does **not** treat these as default provider-package obligations:

- generic file CRUD
- moderation
- Assistants CRUD
- model listing

It does still expose completion and image editing, which makes those two items
more important to classify carefully instead of by symmetry.

### 4. OpenAI image editing is the clearest remaining modern-gap candidate

The root compatibility layer still exposes:

- `editImage(...)`
- `createVariation(...)`
- mask-aware image editing

`repo-ref/ai` already supports image editing through its modern OpenAI image
model path, while `llm_dart_openai` currently only exposes generation on
`OpenAIImageModel`.

That makes image editing the clearest remaining OpenAI feature where:

- the root surface still carries real user-facing value
- the reference package already treats it as part of the modern provider-owned
  image layer
- our current package still lacks an equivalent provider-owned modern path

### 5. OpenAI completion should stay a deliberate non-migration item for now

The reference package still exposes a completion model, but this repository has
already made a broader architectural decision:

- there is no shared modern `CompletionModel`
- completion is not one of the core Flutter-chat-first capability families
- several providers do not have a meaningful modern completion story anymore

Under that direction, treating root OpenAI completion as "unfinished migration"
would push the architecture backward.

So completion should stay compatibility-only unless the project later chooses a
real completion-model strategy intentionally.

### 6. Persistence policy being package-owned does not imply response CRUD must migrate

`llm_dart_openai` already owns the important OpenAI persistence policy:

- `previousResponseId`
- `store`
- `conversation`
- `item_reference` replay branching

That does **not** automatically mean the package now also needs:

- response retrieval
- response deletion
- input-item listing

Those are provider-specific management helpers. They may still be useful later,
but they are not required to complete the modern text boundary.

## Recommended Near-Term Policy

### Treat these as complete modern migrations

- chat-completions and Responses text generation
- reasoning compatibility and persistence subset
- embeddings
- image generation
- speech and transcription
- OpenAI built-in tool declaration APIs
- OpenAI output parsing and message-mapper helpers

### Treat these as root compatibility-only residual APIs for now

- generic file CRUD
- moderation
- Assistants CRUD
- model listing
- voice/language convenience helpers
- embedding-dimension convenience helpers
- `checkModel()` and suggestion helpers
- legacy completion endpoint
- legacy config/builder/factory DSL and preset constructors

### Treat these as explicit provider-owned gap candidates, not shared-core work

- modern OpenAI image editing and variation
- possibly a later provider-owned Responses management helper, but only if a
  concrete app need appears

## Practical Next Slice

The next OpenAI implementation step should **not** be another broad file move.

It should be one of these two focused decisions:

1. decide whether OpenAI image editing and variation should gain a
   provider-owned modern helper on `OpenAIImageModel`
2. or stop there and keep the remaining OpenAI root APIs explicitly classified
   as compatibility-only or optional provider-owned extras

Between those two, image editing is the better structural next slice because it
is the clearest remaining place where the reference package and our package now
still diverge meaningfully.

## Conclusion

OpenAI remains the largest root hybrid host, but it is no longer one large
unfinished migration block.

Most of the remaining root OpenAI surface is now best classified as
compatibility-only residual API, while the clearest real remaining modern-gap
candidate is:

- image editing / variation

That classification should guide the next OpenAI breaking-round work and keep
the repository from re-expanding the shared core just to chase surface parity.
