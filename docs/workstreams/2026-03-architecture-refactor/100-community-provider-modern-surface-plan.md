# Community Provider Modern Surface Plan

## Goal

Define the next truthful migration step for Ollama and ElevenLabs after the
transport/helper cleanup and config-adapter extraction work.

The main question is no longer "can we remove one more import?".

The real question is:

> Which parts of these providers should become package-owned modern APIs, and
> which parts should remain root-owned legacy compatibility shells?

## Current Reality

The recent cleanup rounds already removed several false blockers:

- provider-local defaults are no longer imported from root
- provider-side Dio override data is now transport-owned
- legacy `LLMConfig` adaptation now lives in explicit compatibility adapters
- Ollama no longer depends on root `HttpResponseHandler`

One initial modern toe-hold has now also landed:

- `llm_dart_community` now exposes a package-owned `Ollama.embeddingModel(...)`
  surface backed by `EmbeddingModel`
- `llm_dart_community` now also exposes a package-owned `Ollama.chatModel(...)`
  surface backed by `LanguageModel`

What remains is more fundamental:

- Ollama legacy modules still implement root `ChatCapability`,
  `CompletionCapability`, `EmbeddingCapability`, and `ModelListingCapability`
- ElevenLabs legacy modules still implement root `AudioCapability` and the
  placeholder root `ChatCapability`
- Ollama still consumes root `ChatMessage` and root `Tool`
- ElevenLabs still consumes root audio request/response models
- both providers still depend on root-owned error types and compatibility
  message/capability surfaces

This means the next blocker is no longer transport helper ownership.
It is API ownership.

## What We Should Not Do

We should not continue chasing "package move readiness" by deleting imports one
file at a time while the public behavior still fundamentally belongs to the old
root compatibility contracts.

That would create a misleading state:

- provider internals would look cleaner
- but the actual public API would still be compatibility-shaped
- and `llm_dart_community` would still not own a real modern surface

This would spend effort without changing architectural truth.

## Frozen Recommendation

Use a three-layer split for community providers.

### 1. Provider-Owned Lower Layer

This should eventually live in `llm_dart_community` and depend only on lower
layers:

- provider config
- provider client
- request/response codecs
- provider-specific typed settings
- provider-specific result helpers

This layer should not implement root compatibility interfaces.

### 2. Root Legacy Compatibility Shell

This should remain in the root package for the migration window:

- `OllamaProvider`
- `ElevenLabsProvider`
- builder/factory wiring
- compatibility message/audio adapters
- legacy capability interfaces

This layer is where root `ChatMessage`, root `Tool`, root `AudioCapability`,
and other compatibility-era types should stay.

### 3. Package-Owned Modern Community Surface

This is the missing piece that should make `llm_dart_community` a real package.

Recommended first targets:

- Ollama `LanguageModel` plus `EmbeddingModel`
- ElevenLabs `SpeechModel` plus `TranscriptionModel`

These should use shared modern contracts rather than legacy root capability
interfaces.

## Why This Matches The `repo-ref/ai` Direction

The reference does not treat every compatibility-era provider wrapper as the
real architectural center.

Instead, the important line is:

- provider-owned modern model APIs are primary
- old adapters are transitional

We should copy that ownership rule without copying the full package granularity
of the reference repository.

## Migration Options

### Option A. Migrate ElevenLabs First

Pros:

- shared `SpeechModel` and `TranscriptionModel` surfaces already exist
- audio use cases are narrower than chat
- lower risk than reworking a chat provider first

Cons:

- less leverage for Flutter chat applications
- does not validate the local-chat/community-provider story as strongly as
  Ollama

### Option B. Migrate Ollama First

Pros:

- highest product leverage for local chat apps
- validates the community-provider package on the most visible provider
- creates the strongest proof that provider-owned modern surfaces can replace
  compatibility-era chat wrappers over time

Cons:

- larger surface area because chat, streaming, tools, embeddings, and model
  listing are all nearby
- request/replay mapping questions are broader than ElevenLabs audio

### Option C. Keep Only Cleaning Legacy Shells

Pros:

- low short-term risk

Cons:

- does not create a real package-owned community API
- delays the actual architectural turning point
- risks spending multiple rounds on cleanup without gaining a stable new public
  surface

## Recommendation

Use a hybrid sequence:

1. Freeze the legacy-shell split now.
2. Use the landed package-owned Ollama embedding/chat slices as the pattern
   baseline.
3. Expand the Ollama modern slice with local-chat value next:
   - keep the existing shared `LanguageModel`
   - keep the existing `EmbeddingModel`
   - broaden prompt/stream/tool replay coverage only where the shared contract
     is truthful
   - keep provider-owned typed Ollama settings and invocation options
   - do not reintroduce legacy builder/factory behavior in the package-owned
     layer
4. Move ElevenLabs next as the first package-owned audio-focused community
   slice:
   - shared `SpeechModel`
   - shared `TranscriptionModel`
   - provider-owned voice/settings helpers

This sequence gives higher product leverage without pretending that the legacy
root provider wrappers are the right long-term abstraction.

## Flutter Implications

For Flutter chat integration, the important outcome is not whether the old
`OllamaProvider` file lives under root or under `llm_dart_community`.

The important outcome is:

- Flutter chat/runtime code can target shared `LanguageModel`
- provider-native extras remain typed and provider-owned
- local chat applications do not need the broad root compatibility builder
  surface just to use Ollama

That makes the modern Ollama slice the better next structural payoff even
though ElevenLabs audio may still be the easier provider to modernize.

## Acceptance Criteria For The Next Real Milestone

We should consider `llm_dart_community` to have become a real package only when
all of the following are true:

- it owns at least one package-owned public modern model surface
- that surface depends only on lower-layer packages
- root legacy provider wrappers become optional migration shells rather than the
  only usable API
- provider-specific extras are exposed through typed provider-owned options
  instead of root extension maps

Until then, more local cleanup is useful, but it is still preparation rather
than the actual migration.
