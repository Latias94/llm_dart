# Core-To-Provider SDK Alignment

## Why This Workstream Exists

`llm_dart` has already completed the most important first-order architecture
moves:

- provider-facing model contracts live in `llm_dart_provider`
- user-facing generation, streaming, output parsing, tool loops, and UI
  projection live in `llm_dart_ai`
- transport primitives live in `llm_dart_transport`
- chat and Flutter packages adapt runtime surfaces without owning concrete
  providers
- root `llm_dart` is a facade and compatibility bridge
- provider adapters have been split into request, transport, response, and
  stream modules across OpenAI, Google, Anthropic, Ollama, and ElevenLabs

The remaining risk is not a single thick model file. The remaining risk is
system drift: core contracts, runtime event semantics, provider-native options,
metadata, transport helpers, compatibility barrels, and provider parity can
evolve independently unless the project has one top-level alignment matrix.

This workstream is that matrix. It uses `repo-ref/ai` as a mature reference for
durable seams, but preserves the Dart library's own strengths: typed provider
options, capability profiles, provider-native helper clients, and a unified
Dart interface.

## Relationship To Existing Workstreams

This workstream does not replace prior work.

- `../2026-05-ai-sdk-inspired-architecture-rewrite/README.md`
  - established semantic ownership rules for user prompts, provider prompts,
    metadata replay, provider objects, and OpenAI-family policy.
- `../2026-05-sdk-aligned-fearless-refactor/README.md`
  - executed provider/runtime contract hardening and adapter module splits.

This workstream turns those completed slices into a final core-to-provider
alignment plan. It should be used to decide the next large refactor instead of
continuing with opportunistic file splitting.

## Target Architecture

The target architecture is a layered contract stack:

- `llm_dart_provider`
  - owns provider-facing model specifications, prompt/data contracts, stream
    events, usage, warnings, provider options, provider metadata, provider
    references, capability profiles, and provider object contracts
- `llm_dart_ai`
  - owns user-facing runtime helpers, prompt normalization, multi-step tool
    loops, stop conditions, output parsing, UI projection, result facades, and
    runtime-only stream events
- `llm_dart_transport`
  - owns HTTP, SSE, NDJSON/UTF-8 stream primitives, multipart bodies,
    cancellation, retry, diagnostics, and transport-to-model error projection
- provider packages
  - own provider wire codecs, provider-native typed options, provider metadata
    decoding, capability policy, native helper clients, and provider-specific
    product surfaces
- `llm_dart_chat` and `llm_dart_flutter`
  - own framework-neutral and Flutter-facing chat/UI adapters over AI runtime
    contracts
- root `llm_dart` and `llm_dart_core`
  - remain facade or compatibility layers with explicit freeze or exit policy

## Reference Lessons From `repo-ref/ai`

The reference repository is useful for seam design:

- provider model contracts are implementation-facing
- AI runtime helpers own user-facing orchestration
- model messages, provider prompts, UI messages, and wire messages are
  separate layers
- provider options are input-side controls
- provider metadata is output-side observation and replay data
- provider utilities become valuable only after repeated provider
  implementation needs prove the seam
- provider-native features stay provider-owned until a durable shared contract
  exists

The Dart implementation should not copy TypeScript overloads, web stream
types, or package count literally.

## Scope

This workstream covers:

- core provider contract audit
- AI runtime orchestration audit
- transport and provider implementation helper audit
- provider-by-provider parity matrix
- typed provider option conflict and precedence rules
- provider metadata and replay invariants
- provider object registry and model lookup posture
- root and `llm_dart_core` compatibility exit plan
- release-readiness gates for the final breaking line

## Non-Goals

This workstream should not:

- reopen package splitting that has already landed
- copy Vercel AI SDK package layout literally
- remove provider-native helper clients
- flatten provider-specific options into weak shared options
- publish `llm_dart_provider_utils` before a stable public utility contract is
  proven
- add new architectural ownership to `llm_dart_core`
- keep compatibility APIs that hide the modern ownership model

## Documents

- [GOAL.md](GOAL.md)
  - Canonical objective and completion definition.
- [TODO.md](TODO.md)
  - Executable checklist.
- [MILESTONES.md](MILESTONES.md)
  - Phase gates and acceptance criteria.
- [01-core-contract-audit.md](01-core-contract-audit.md)
  - Core provider contract gaps and first decisions.
- [02-runtime-orchestration-audit.md](02-runtime-orchestration-audit.md)
  - AI runtime seams compared with the reference runtime.
- [03-provider-parity-matrix.md](03-provider-parity-matrix.md)
  - Provider-by-provider alignment matrix.
- [04-provider-implementation-kit-audit.md](04-provider-implementation-kit-audit.md)
  - Repeated implementation helper audit and provider-utils decision.
- [05-compatibility-exit-plan.md](05-compatibility-exit-plan.md)
  - Root and `llm_dart_core` freeze, migration, and exit plan.
