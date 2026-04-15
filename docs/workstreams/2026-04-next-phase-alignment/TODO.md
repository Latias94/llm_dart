# TODO

## Workstream Setup

- [x] Create the next-phase alignment workstream scaffold
- [x] Re-baseline the remaining useful gaps versus `repo-ref/ai`

## Streamed Runner Maturity

- [x] Audit the current `StreamTextRunner` surface against real app needs and
  freeze which missing behaviors are truly shared
- [x] Decide whether a `prepareStep`-style hook belongs in shared core or
  should remain app/provider-owned
- [x] Decide whether retry, model fallback, or richer stop policy belong in
  the shared runner or should stay explicitly deferred

## `llm_dart_core` Internal Boundary Hardening

- [x] Write a frozen internal sublayer map for `llm_dart_core`
- [x] Classify current `llm_dart_core` exports into specification, runtime,
  UI, and serialization ownership groups
- [x] Define the trigger conditions for any future published package split out
  of `llm_dart_core`
- [x] Add non-breaking focused `llm_dart_core` entrypoints for foundation,
  model, UI, and serialization ownership groups
- [x] Extract shared serialization JSON support for repeated metadata, usage,
  file, source, warning, and error codecs
- [x] Review the next internal `llm_dart_core` hotspot after serialization
  cleanup and identify the next likely seam
- [x] Split `ChatUiAccumulator` tool lifecycle projection into internal support
  without changing the shared event surface
- [x] Split `ChatUiAccumulator` text/reasoning lanes and metadata projection
  into internal support without changing the shared event surface
- [x] Split `ChatUiAccumulator` output projection into internal support
  without changing the shared event surface
- [x] Split `ChatUiAccumulator` seed/index hydration into internal support
  without changing the shared event surface
- [x] Split `ChatUiAccumulator` data-part upsert behavior into internal support
  without changing the shared event surface
- [x] Adopt focused core entrypoints in `llm_dart_transport`
- [x] Adopt focused core entrypoints in `llm_dart_chat`

## Root And Package Ownership

- [x] Re-audit the root package role after the latest community/package moves
- [x] Improve package-level documentation where the ownership story is still
  thin or implicit

## OpenAI Family Stream Parser

- [x] Move shared indexed tool-call delta state out of the Chat Completions and
  Responses codec paths
- [x] Document why OpenAI stream parser convergence is internal provider
  infrastructure rather than a shared event-surface expansion
- [x] Split OpenAI Chat Completions request encoding out of the main codec file
- [x] Split OpenAI Responses request encoding out of the main codec file
- [x] Split OpenAI Chat Completions response decoding out of the main codec file
- [x] Split OpenAI Responses response decoding out of the main codec file
- [x] Split OpenAI Chat Completions stream decoding out of the main codec file
- [x] Split OpenAI Responses stream decoding out of the main codec file
- [x] Split OpenAI Chat Completions request encoding by outbound concern while
  keeping the same internal request boundary
- [x] Split OpenAI Responses request encoding by outbound concern while keeping
  the same internal request boundary
- [x] Review whether remaining OpenAI non-text models justify further internal
  splitting or only small shared support extraction
- [x] Split `openai_image_model.dart` into internal request, response, and
  shared support layers without introducing a new package boundary
- [x] Extract a small shared internal shell for repeated OpenAI non-text model
  settings, headers, provider-option validation, and JSON decoding support

## Freeze Review And Next Route

- [x] Review which remaining large files are still honest boundaries rather than
  mixed architecture hotspots
- [x] Freeze which current seams should stay unchanged unless repeated product
  pressure appears
- [x] Record reopen triggers so future refactors stay evidence-driven rather
  than symmetry-driven
- [x] State the next route for the repository after this architecture-heavy
  phase

## Explicitly Deferred

- [ ] Reopen shared runner scope only when repeated cross-provider product
  pressure exists
- [ ] Reopen package splitting only when internal support extraction stops being
  sufficient
- [ ] Remove legacy compatibility surfaces only with a deliberate deprecation
  plan

## Provider Capability Discovery

- [x] Document why modern capability discovery should be model-centric rather
  than provider-level or root-compatibility-driven
- [x] Document the relationship between shared feature flags, provider-native
  feature descriptors, warnings, metadata, and custom parts
- [x] Freeze that legacy `LLMCapability` remains a compatibility adapter rather
  than the modern source of truth
- [x] Add additive core descriptor types for model capability profiles
- [x] Add provider-owned describers, starting with OpenAI
- [x] Add optional model marker interfaces for provider models that can expose
  capability profiles directly
- [x] Add Flutter/app examples for capability-gated UI affordances
