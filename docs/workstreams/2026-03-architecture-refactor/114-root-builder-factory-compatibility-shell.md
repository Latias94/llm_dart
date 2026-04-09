# 114. Root Builder And Factory Compatibility Shell

## Question

Now that the repository already has modern typed provider namespaces such as:

- `AI.openai(...)`
- `AI.google(...)`
- `AI.anthropic(...)`
- `OpenAI(...)`
- `Google(...)`
- `Anthropic(...)`
- `Ollama(...)`
- `ElevenLabs(...)`

should the remaining root builder and factory adaptation path still survive as
an explicit compatibility shell, or should it be replaced by new provider-owned
modern config constructors built around the old root builder/factory machinery?

## Conclusion

The root builder/factory path should survive only as a compatibility shell.

The modern direction should remain:

- provider-owned typed constructors in provider packages
- the root `AI.*(...)` facade as a thin convenience layer above those package
  namespaces
- root `LLMBuilder`, root factories, and root `LLMConfig` adaptation only for
  migration-era compatibility

So the repository should **not** try to turn the remaining root builder/factory
path into the design basis for modern provider construction again.

## Why

## 1. The Modern Provider Constructor Layer Already Exists

The modern path is no longer hypothetical.

Current package-owned constructors already exist for the main provider families:

- `packages/llm_dart_openai/lib/src/openai.dart`
- `packages/llm_dart_google/lib/src/google.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic.dart`
- `packages/llm_dart_community/lib/src/ollama.dart`
- `packages/llm_dart_community/lib/src/elevenlabs.dart`

These constructors already own the right modern inputs:

- API key or provider authentication
- optional transport injection
- optional base URL override
- typed per-model settings through provider-owned model constructors

That is already the correct modern ownership boundary.

Rebuilding another root-owned modern constructor layer on top of the old
builder/factory path would only duplicate a surface that now already exists in
the right place.

## 2. The Root Builder/Factory Path Is Still Structurally Legacy-Shaped

The current root builder/factory path still depends on compatibility-era
concepts such as:

- `LLMConfig`
- `BaseProviderFactory`
- root capability interfaces such as `ChatCapability`
- legacy extension-key reads and config adaptation
- root compatibility provider subclasses

Examples:

- `lib/providers/factories/base_factory.dart`
- `lib/providers/factories/ollama_factory.dart`
- `lib/providers/factories/elevenlabs_factory.dart`

That path is useful for migration, but it is not the right foundation for the
modern package graph.

If provider-owned modern constructors were forced to align back to this root
path, provider packages would again become shaped by:

- root compatibility config semantics
- root capability naming
- root extension-map history

That would reverse the direction the refactor already established.

## 3. This Better Matches `repo-ref/ai`

The useful lesson from `repo-ref/ai` is not package-count symmetry.

The useful lesson is ownership:

- provider packages expose provider-owned constructors such as
  `createOpenAI(...)`, `createAnthropic(...)`, and
  `createGoogleGenerativeAI(...)`
- those constructors directly own provider auth, base URL, fetch/transport, and
  provider-specific options
- the modern provider surface is not rebuilt around one cross-provider legacy
  builder

Our Dart shape is intentionally different in naming, but the same structural
rule should apply:

- modern provider creation belongs to provider packages and the thin `AI`
  facade
- root builder/factory compatibility belongs to `legacy.dart`

## 4. This Keeps Dependency Direction Honest

The repository already fixed the earlier `llm_dart_core <-> llm_dart_transport`
cycle and established a one-way package graph.

The remaining root dependency pressure now comes mostly from compatibility-era
provider hosting and builder/factory adaptation.

That means the next dependency cleanup should happen by confining the old
builder/factory path more clearly, not by promoting it back into the modern
design.

If the project instead rebuilt modern constructors around root factory logic,
then:

- provider packages would stay conceptually downstream from root compatibility
- root-local `dio` / `logging` pressure would remain harder to remove
- `llm_dart_community` would keep looking less like a real package-owned home

## 5. Community Providers Especially Need This Boundary

This matters most for Ollama and ElevenLabs.

Their package-owned modern surfaces now already exist in `llm_dart_community`,
while the root factories still adapt:

- `LLMConfig`
- legacy extension keys
- compatibility provider shells

If the repository tried to make those root factories the long-term constructor
story again, `llm_dart_community` would remain architecturally subordinate to
the root compatibility layer.

That would undermine the whole point of the community-package migration.

## What Should Survive

The following pieces should survive for the compatibility window:

- `LLMBuilder`
- root provider factories
- `LLMConfig` compatibility shaping
- compatibility provider subclasses returned by `LLMBuilder.build()`
- explicit `legacy.dart` exports for migration-era code

But they should survive with one interpretation only:

- compatibility support
- migration continuity
- no claim of being the preferred modern construction path

## What Should Not Happen

Do not:

- add new stable provider features to the root builder/factory path first
- make provider packages accept `LLMConfig`
- move provider-owned typed settings back into root extension maps just for
  constructor symmetry
- add a second root-owned typed constructor layer that mirrors the provider
  packages
- treat root builder convenience as a reason to keep modern package ownership
  fuzzy

## Recommended Next Steps

After freezing this boundary, the next structural cleanup should focus on:

1. root error ownership, especially the remaining compatibility role of
   `HttpResponseHandler` and `DioErrorHandler`
2. removing root `dio` / `logging` runtime dependencies only after more
   compatibility/provider implementation weight leaves the root package
3. auditing whether provider-focused root entrypoints should stop re-exporting
   unrelated modern shells once the migration window tightens further

## Impact On The Workstream

This closes the current builder/factory question more explicitly:

- root builder/factory adaptation remains a compatibility shell
- provider-owned modern constructors remain the long-term API direction
- new modern ergonomics should be added in provider packages or the thin `AI`
  facade, not by reviving the root compatibility builder as a primary design
  surface
