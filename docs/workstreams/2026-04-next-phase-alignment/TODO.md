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
