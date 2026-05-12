# Provider Contract And Prompt Boundary Refactor

## Why This Workstream Exists

The previous SDK-aligned refactor established the right package graph:
provider specifications, AI runtime orchestration, transport, chat, Flutter
adapters, provider packages, and a root facade now have visible ownership
boundaries.

The next useful breaking line is narrower and stricter. The package graph is
mostly correct, but several data and method names still let user-facing runtime
semantics leak back into provider contracts:

- non-text model contracts still expose user-facing method names such as
  `embed`, `generate`, `generateSpeech`, and `transcribe`
- prompt parts still carry `ProviderMetadata`, even though metadata is
  documented as output-side provider observation
- some provider codecs still read input request controls from prompt
  `providerMetadata`
- user prompt ergonomics and provider-facing prompt contracts are still mostly
  the same data layer
- the root compatibility surface remains large enough to pull architecture
  decisions back toward legacy builder-era shapes

This workstream is the second boundary-hardening pass. It uses the mature
lessons from `repo-ref/ai` while keeping `llm_dart`'s Dart-specific strengths:
typed provider options, capability profiles, provider-native helper clients,
OpenAI-compatible family profiles, and a unified model-first runtime.

## Goal

Deliver a breaking API line where provider specifications are consistently
implementation-facing and where input-side provider customization is separate
from output-side provider metadata.

The target outcome:

- every model contract in `llm_dart_provider` uses implementation-facing
  method names
- user-facing helpers stay in `llm_dart_ai`
- prompt input customization uses typed provider options or provider-owned
  part options, not `ProviderMetadata`
- `ProviderMetadata` is reserved for response observations, replay details,
  provider raw values, and UI inspection
- user-facing prompt ergonomics can evolve without changing provider codecs
- root legacy compatibility no longer dictates new architecture decisions

## Reference Lessons From `repo-ref/ai`

The useful reference lessons are architectural, not package-count goals:

- all model specifications use `do*` methods for implementation calls:
  `doGenerate`, `doStream`, and `doEmbed`
- user helpers such as `generateText`, `streamText`, `embedMany`,
  `generateImage`, `generateSpeech`, and `transcribe` live above provider
  specifications
- provider-facing prompts are distinct from user-facing prompt inputs
- prompt parts carry `providerOptions` for input-side provider customization
- provider metadata is output-side data returned by model calls and stream
  parts
- provider utilities are extracted only when repeated provider implementation
  code proves a stable helper boundary
- provider-native features are not flattened into weak common abstractions

## What To Preserve

The refactor must keep the features that make this package useful:

- a unified Dart API that can call multiple providers through shared runtime
  helpers
- typed provider invocation options for discoverability
- typed provider model settings
- capability profiles for model-centric feature discovery
- provider-owned helper clients for files, moderation, images, speech,
  transcription, voices, local catalogs, and other native APIs
- OpenAI-family profiles for OpenRouter, DeepSeek, Groq, xAI, Phind, and
  future compatible providers
- framework-neutral chat runtime and Flutter adapters that do not depend on
  concrete provider packages

## Target Boundary Rules

- `llm_dart_provider` owns provider-facing model specifications and stable
  wire-neutral data contracts.
- `llm_dart_ai` owns user-facing runtime helpers, prompt normalization,
  multi-step loops, structured output, and future user-prompt convenience
  shapes.
- Provider packages implement provider contracts and own provider-specific
  request/response codecs, typed options, native tools, and helper clients.
- Input-side provider controls use typed provider options or provider-owned
  prompt part options.
- Output-side provider observations use `ProviderMetadata`.
- Root `llm_dart` remains a modern facade. Legacy builder compatibility must
  not define new provider/runtime contracts.

## Documents

- [GOAL.md](GOAL.md)
  - Canonical goal statement and non-goals.
- [TODO.md](TODO.md)
  - Executable implementation checklist.
- [MILESTONES.md](MILESTONES.md)
  - Milestones, acceptance criteria, and validation gates.
- [01-reference-gap-audit.md](01-reference-gap-audit.md)
  - Current source audit against `repo-ref/ai` lessons.
- [02-target-contracts.md](02-target-contracts.md)
  - Target provider contract and method naming decisions.
- [03-prompt-boundary-plan.md](03-prompt-boundary-plan.md)
  - Provider options versus provider metadata migration plan.
- [04-legacy-exit-plan.md](04-legacy-exit-plan.md)
  - Root compatibility and legacy surface exit strategy.
- [05-completion-audit.md](05-completion-audit.md)
  - Prompt-to-artifact completion audit, validation evidence, and blocked
    release-readiness gates.
