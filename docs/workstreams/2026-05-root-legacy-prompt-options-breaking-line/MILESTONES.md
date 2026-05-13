# Milestones

## M1 - Direction Freeze

Goals:

- freeze the purpose and scope of the next breaking line
- choose the root legacy exit strategy
- confirm that the current package graph remains the base

Acceptance criteria:

- GOAL, README, TODO, milestones, and gap audit exist
- root legacy exit has a delete/relocate/freeze decision
- non-goals explicitly prevent package-count parity with `repo-ref/ai`
- first implementation slices are documented

Current status:

- frozen: direct root legacy deletion is the default path; no compatibility
  package unless later implementation evidence justifies one
- first implementation slices documented in
  `02-breaking-decision-and-first-slices.md`

## M2 - Root Legacy Exit

Goals:

- remove root-package implementation ownership
- keep the root package as a modern facade and documented migration vehicle

Acceptance criteria:

- root `lib/providers`, `lib/models`, `lib/builder`, and compatibility internals
  are deleted, relocated, or reduced to explicit migration hooks
- root boundary guards reject new implementation ownership
- migration docs cover removed or moved APIs

Current status:

- implemented and under release-readiness validation
- root `lib/legacy.dart`, `lib/builder`, `lib/models`, `lib/providers`, and
  root compatibility/bootstrap internals have been deleted
- root boundary guard rejects legacy implementation ownership and enforces the
  thin facade layout
- consumer smoke no longer imports `package:llm_dart/legacy.dart` or constructs
  `LLMBuilder`
- retained OpenAI Assistants and raw Responses lifecycle APIs moved into
  `llm_dart_openai` as focused provider clients
- examples have been migrated off root legacy subpaths and the example guard no
  longer has compatibility allowlists
- test legacy import guard now rejects root legacy subpath imports by default;
  `--allow-root-legacy-subpaths` remains only as an explicit migration-inventory
  escape hatch

## M3 - Prompt Surface Convergence

Goals:

- make user-facing prompt construction clearly app-facing
- keep provider-facing prompts as advanced/provider-contract data

Acceptance criteria:

- common runtime docs and examples use `ModelMessage` or shorthand prompts
- provider-facing `PromptMessage` inputs are documented as advanced
- prompt normalization and validation stay in `llm_dart_ai`
- provider codecs receive normalized provider prompts

Current status:

- implemented at the runtime layer; `ModelMessage` is the app-facing prompt
  layer, `PromptMessage` remains the advanced provider-contract path, and
  `llm_dart_ai` normalization plus validation feeds provider codecs
  normalized prompts
- README, getting-started examples, and common core examples now teach
  `messages:` / `ModelMessage` for app code; provider-facing `PromptMessage`
  appears only in advanced/provider-contract documentation

## M4 - Metadata And Options Boundary

Goals:

- remove ordinary request-side metadata inputs
- keep replay metadata explicit and typed

Acceptance criteria:

- prompt and tool-output input types no longer expose ordinary
  `ProviderMetadata`
- output metadata remains available for results, stream events, UI projection,
  and replay observations
- replay paths use `ProviderReplayPromptPartOptions` or provider-owned typed
  replay helpers
- guards reject metadata-driven request configuration outside approved replay
  helpers

Current status:

- complete for the request/replay boundary slice
- request-side `ProviderMetadata` has been removed from prompt parts and
  structured tool-output content parts
- replay metadata now flows through `ProviderReplayPromptPartOptions` or
  provider-owned typed replay helpers
- dedicated replay guard and focused tests now cover the new boundary

## M5 - Prompt Surface, Provider Options, And Structured Results

Goals:

- freeze the app-facing prompt surface and advanced provider-prompt boundary
- preserve typed provider discoverability while supporting future composition
- freeze the long-term structured text/object result direction

Acceptance criteria:

- common docs and examples use `ModelMessage` or shorthand prompts
- provider-facing `PromptMessage` inputs are documented as advanced
- `generateTextCall` / `streamTextCall` are the documented combined text and
  structured-output result path
- `generateObject` / `streamObject` remain wrappers or migration helpers
- provider options bag or equivalent policy is documented and tested
- raw provider option escape hatch is scoped and namespaced
- existing provider-native options and helper clients remain available

Current status:

- implemented and under release-readiness validation
- prompt-surface and structured-result facade decisions are documented in
  `05-prompt-surface-and-result-facade-freeze.md`
- the raw provider option escape hatch policy is scoped there: no shared raw
  request map, only provider-owned raw fields on concrete typed option objects
- existing typed-option tests cover missing, incompatible, and merge behavior;
  provider-owned raw tests remain conditional on a provider exposing a raw
  request field
- common examples have been cleaned up so app-facing text calls use
  `messages:` / `ModelMessage`

## M6 - Release Readiness

Goals:

- prove the breaking line with automation and migration docs

Acceptance criteria:

- guards pass
- affected package tests and analysis pass
- root and migration tests reflect the final legacy outcome
- examples and README use the new default path
- consumer smoke and publish dry-runs pass

Current status:

- passed for the breaking-line scope
- guards, focused package tests, root facade tests, prompt normalization
  integration tests, affected package analysis, consumer smoke, and workspace
  publish dry-runs have passed
- workspace publish dry-run reports 0 warnings for all 12 publishable packages;
  only expected local workspace override hints are suppressed by the tool
