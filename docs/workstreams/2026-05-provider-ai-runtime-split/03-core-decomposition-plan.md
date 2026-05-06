# Core Decomposition Plan

## Current Pressure

`llm_dart_core` currently carries several distinct ownership groups:

- foundation/common primitives
- prompt and content models
- model specifications
- generation helpers
- multi-step runners
- structured output parsing
- stream events
- UI messages and projection
- serialization codecs

That concentration was acceptable during the first architecture split, but it
is the wrong long-term home for a breaking line that wants provider spec and AI
runtime to evolve independently.

## Proposed Extraction Order

### Step 1 - Identify Pure Provider Contracts

Move the following first into `llm_dart_provider`:

- model interfaces
- request/result structures used by provider implementations
- prompt messages and prompt parts
- content parts
- stream events
- provider metadata and provider options
- warnings, usage, response metadata, and model errors
- tools and tool choices

Acceptance:

- provider packages can compile against `llm_dart_provider`
- no generation runner is needed by provider implementations

### Step 2 - Move AI Runtime Helpers

Move app-facing runtime helpers into `llm_dart_ai`:

- `generateText`
- `streamText`
- multi-step runners
- tool execution continuation
- structured output helpers
- result accumulator if it is runtime-facing rather than provider-codec-facing

Acceptance:

- apps can use `llm_dart_ai` with any `LanguageModel`
- provider packages do not depend on `llm_dart_ai`

### Step 3 - Decide UI Placement

Choose one of two paths:

- keep UI message and projection in a focused `llm_dart_provider` entrypoint
  only if it remains a small shared contract
- split UI contracts into a separate `llm_dart_ui` package if UI projection
  keeps growing independently of provider specs

Default recommendation:

- defer a public `llm_dart_ui` package until the provider/runtime split lands
- keep UI split triggers explicit instead of doing package fragmentation for
  symmetry

Current decision:

- keep the small shared UI message and message-mapping contracts in
  `llm_dart_provider` for the first breaking preview
- keep old `llm_dart_core` UI paths as compatibility re-exports while concrete
  provider packages migrate away from core
- revisit a dedicated UI package only if UI projection grows independently from
  provider-facing stream and content contracts

### Step 4 - Move Serialization With The Owning Contract

Serialization should follow ownership:

- prompt and stream serialization stays near provider/shared contracts
- chat session snapshot serialization stays in `llm_dart_chat`
- UI message serialization stays with UI contracts

Avoid a single serialization package unless multiple packages need the same
codec ownership and the dependency graph stays clean.

## Compatibility Strategy

During migration:

- `llm_dart_core` may temporarily re-export new packages
- root `llm_dart/core.dart` may remain a compatibility convenience export
- direct imports should move toward the new owner packages in examples and
  tests

After migration:

- `llm_dart_core` remains a compatibility shell for the first breaking preview
- it should have no unique implementation ownership beyond compatibility
  re-exports and legacy-path coverage tests
- eventual removal should be a later release decision after root examples,
  migration docs, and package dependents have moved to focused entrypoints
- `tool/check_core_compatibility_shell_guard.dart` enforces this posture by
  rejecting new concrete declarations in `packages/llm_dart_core/lib`; only
  public re-exports and explicitly approved compatibility aliases are allowed

## Split Triggers

Further public package splits are justified only when:

- internal entrypoints are not enough to keep dependencies honest
- two or more packages need the same contract without accepting a broader
  dependency
- repeated bugs come from mixed ownership
- examples and user code need a smaller dependency surface

File count alone is not a sufficient split trigger.
