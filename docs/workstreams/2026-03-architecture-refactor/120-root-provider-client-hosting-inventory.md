# 120. Root Provider Client Hosting Inventory

## Question

After relocating community-provider shells and compatibility HTTP scaffolding,
which remaining root provider clients still keep the root package as a real
implementation host?

More importantly:

- which families are now mostly compatibility shells
- which families still duplicate package-owned modern capabilities inside the
  root package
- which families should stay root-only for now instead of forcing new package
  symmetry

## Why This Review Matters

The root package still directly depends on `dio` and `logging`.

That is no longer mainly because of generic helper placement. The recent
relocations already moved the obvious compatibility plumbing under
`src/compatibility`.

The remaining pressure is now more honestly about root provider hosting:

- root provider clients still perform real HTTP work
- root provider classes still own broad legacy capability modules
- some provider families already have package-owned modern homes, but the root
  package still carries parallel implementations

This is the next structural gap to make explicit.

## What Was Reviewed

Root provider families and clients:

- `lib/providers/openai/**`
- `lib/providers/anthropic/**`
- `lib/providers/google/**`
- `lib/providers/deepseek/**`
- `lib/providers/groq/**`
- `lib/providers/xai/**`
- `lib/providers/phind/**`
- `lib/providers/ollama/**`
- `lib/providers/elevenlabs/**`

Compatibility routing:

- `lib/src/compatibility/providers/openai_family_compat_provider.dart`
- `lib/src/compatibility/providers/anthropic_compat_provider.dart`
- `lib/src/compatibility/providers/google_compat_provider.dart`

Package-owned modern homes:

- `packages/llm_dart_openai/lib/src/openai.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic.dart`
- `packages/llm_dart_google/lib/src/google.dart`
- `packages/llm_dart_community/lib/src/*`

## Inventory

| Family | Package-owned modern home | Root package still hosts | Current root role | Recommended direction |
| --- | --- | --- | --- | --- |
| Ollama | `llm_dart_community` chat + embeddings | residual completion, model listing, local client, fallback chat shell | compatibility-first residual shell | keep residual APIs explicit; do not reopen shared-core scope just to move `/api/generate` or model listing |
| ElevenLabs | `llm_dart_community` speech + direct-audio transcription | file transcription fallback, voice/model/user helpers, realtime/admin-style paths | compatibility-first residual shell | decide file transcription and voice/realtime/admin policy before any further package move |
| Google | `llm_dart_google` chat + embeddings + image + speech | root client plus root chat, embeddings, image, and TTS modules | duplicated modern-capability host | strongest next thinning candidate |
| Anthropic | `llm_dart_anthropic` chat + files | root client plus root chat, files, models, token counting path | hybrid transitional host | second-best thinning candidate after Google |
| OpenAI | `llm_dart_openai` chat + embeddings + image + speech + transcription | root client plus root chat, responses, embeddings, image, speech, files, moderation, assistants, completion, model listing | broad hybrid transitional host | requires explicit residual-API classification, not a blind move |
| DeepSeek | bridge-safe modern chat path via `llm_dart_openai` profile | root client, root chat, root model listing, provider-specific error path | openai-profile compatibility host | keep as profile-backed compatibility shell; do not create a dedicated package by symmetry alone |
| Groq | bridge-safe modern chat path via `llm_dart_openai` profile | root client and root chat | openai-profile compatibility host | same as DeepSeek |
| xAI | bridge-safe modern chat path via `llm_dart_openai` profile | root client, root chat, root embeddings, live-search extras | openai-profile compatibility host with provider extras | keep profile-backed direction; classify search/embedding extras before broader thinning |
| Phind | no package-owned modern home | root client and root chat only | root-only legacy host | keep root-only until a concrete migration case exists |

## What The Inventory Shows

### 1. Community providers are no longer the main root-hosting problem

Ollama and ElevenLabs still have root code, but their architecture is now much
clearer:

- shared-capability mainlines already live in `llm_dart_community`
- root provider classes now sit under explicit compatibility ownership
- the remaining root code is mostly residual provider-specific surface

That means they are no longer the most misleading part of the root package.

### 2. Google is now the clearest duplicated modern-capability host

`llm_dart_google` already owns:

- `chatModel(...)`
- `embeddingModel(...)`
- `imageModel(...)`
- `speechModel(...)`

But the root `GoogleProvider` still hosts local implementations for the same
general capability families.

That makes Google the cleanest next thinning target:

- the package-owned modern home already exists
- the duplicated capability set is easy to see
- the remaining question is mainly which legacy-only request shapes or helpers
  still need root compatibility fallback

### 3. Anthropic is more transitional than it first appears

`llm_dart_anthropic` already owns:

- `chatModel(...)`
- `files(...)`

The root `AnthropicProvider` still hosts:

- chat fallback paths
- file-management capability
- model listing
- token counting convenience

That means Anthropic is not a “package still missing the right home” problem.
It is a boundary-classification problem:

- which of those root capabilities are compatibility-only
- which deserve provider-owned package surfaces
- which should simply remain root residual APIs until removal

### 4. OpenAI remains the broadest root-hosting family

`llm_dart_openai` already covers a large modern surface, but the root
`OpenAIProvider` still owns many more capability modules and convenience APIs.

This is the broadest remaining hybrid host role in the repository.

That does **not** mean it should be the immediate next move.

It means OpenAI needs a more explicit residual-policy pass first, because a
blind relocation would mix together:

- shared-capability modern models
- provider-specific extras
- compatibility-only surfaces
- large root legacy APIs such as assistants, moderation, model listing, and
  completion

### 5. DeepSeek, Groq, and xAI should stay classified as profile-backed shells

These families already have a meaningful modern direction through the
OpenAI-family package and profile system.

The inventory therefore argues against a symmetry-driven response such as:

- create one new package for each profile-backed provider
- move each root provider wholesale just because a profile exists

The better framing is:

- keep using the package-owned OpenAI-family mainline where the protocol is
  honestly shared
- keep root compatibility shells only for the residual legacy provider surface

### 6. Phind is still intentionally root-only

Phind does not currently have:

- a dedicated package-owned modern home
- a proven bridge-safe migration target comparable to the OpenAI-family
  profiles

That means Phind should stay explicitly root-only for now instead of forcing a
premature package story.

## Dependency Pressure Summary

The root package still needs `dio` and `logging` because root provider hosting
is still real.

Examples:

- root clients for OpenAI, Anthropic, Google, DeepSeek, Groq, xAI, Phind,
  Ollama, and ElevenLabs still perform HTTP work
- multiple root clients still call compatibility wrappers such as
  `HttpResponseHandler` and `DioErrorHandler`
- several root config types still carry compatibility-era Dio override or
  extension shaping
- `core/cancellation.dart` still recognizes raw Dio cancellation exceptions for
  backward compatibility

So removing root `dio` and `logging` is still downstream work.

The honest prerequisite is shrinking the remaining root provider host role.

## Recommended Slice Order

### 1. Google next

Reason:

- package-owned modern capability coverage is already broad
- root duplication is obvious
- the compatibility fallback boundary should be easier to state than OpenAI's

### 2. Anthropic after Google

Reason:

- package-owned files already exist
- the root role is narrower than OpenAI's
- the remaining decisions are concrete: files, models, token counting, and chat
  fallback

### 3. OpenAI only after a residual-API classification pass

Reason:

- the root host role is much broader
- a premature move would blur shared modern surfaces and provider-specific
  extras again

### 4. Keep DeepSeek, Groq, and xAI on the profile-backed path

Reason:

- their honest modern direction already exists
- new package count would not solve the real ownership issue

### 5. Keep Phind explicitly root-only

Reason:

- no strong modern migration path is proven yet

## Non-Goals

This inventory does not recommend:

- copying `repo-ref/ai` package count mechanically
- creating dedicated packages for every provider family
- moving all remaining root clients out in one round
- removing root `dio` and `logging` before the provider host role actually
  shrinks

## Practical Conclusion

The next meaningful alignment step is no longer “community providers versus the
root package.”

The next meaningful step is:

- treat the root package as a shrinking compatibility host
- identify which provider families still duplicate package-owned modern
  capabilities there
- thin the cleanest duplicated family next

Based on the current inventory, that family is Google.
