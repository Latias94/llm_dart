# Milestones

## M0 - Architecture Decision Freeze

Goals:

- freeze this workstream as the controlling plan for the breaking refactor
- decide final provider implementation method naming
- decide provider options versus provider metadata semantics
- decide which compatibility surfaces are intentionally kept for the breaking
  line

Acceptance criteria:

- target ownership rules are documented
- non-goals are explicit
- related workstreams are linked
- open decisions have owners or review gates

Exit gate:

- no implementation slice starts until provider/runtime/root boundaries are
  written down and accepted.

## M1 - Provider Contract Hardening

Goals:

- make provider model contracts clearly implementation-facing
- prevent provider contracts from being mistaken for user-facing AI functions
- keep provider specifications free from runtime orchestration

Acceptance criteria:

- `LanguageModel` generation and streaming methods use implementation-facing
  names
- all provider packages compile against the hardened contract
- AI runtime runners call the new provider method names
- direct provider contract tests cover request/result behavior without tool-loop
  orchestration
- migration notes explain old direct-call replacements

Exit gate:

- dependency guards and provider package tests pass after the contract rename.

## M2 - AI Runtime Consolidation

Goals:

- keep user-facing generation helpers in `llm_dart_ai`
- centralize multi-step tool orchestration and structured output behavior
- prevent provider packages from depending on runtime or UI helpers

Acceptance criteria:

- `generateText`, `streamText`, object generation, and tool loops live in
  `llm_dart_ai`
- provider packages do not have production dependencies on `llm_dart_ai`
- chat/UI projection helpers are runtime-owned, chat-owned, or provider-owned
  without reverse dependencies
- focused runtime tests cover single-step, multi-step, streaming, structured
  output, and tool continuation flows

Exit gate:

- runtime package tests pass and provider package dependency guards reject
  runtime/UI dependencies.

## M3 - Provider Options And Metadata Boundary

Goals:

- make input-side customization explicit through provider options
- reserve provider metadata for output-side observations and replay details
- preserve typed provider-native options

Acceptance criteria:

- shared provider option contracts are documented
- typed provider options remain provider-owned where the feature is not shared
- raw option escape hatches are namespaced
- `ProviderMetadata` no longer carries request configuration
- tests cover option mapping, unsupported option warnings, and metadata output
  shape

Exit gate:

- migration recipes exist for old metadata-driven request configuration.

## M4 - Shared Generation Option Completion

Goals:

- fill durable shared LLM knobs that modern providers commonly expose
- map unsupported or partially supported options predictably
- avoid moving provider-specific features into the shared contract too early

Acceptance criteria:

- shared options include presence penalty, frequency penalty, seed, reasoning,
  and raw chunk inclusion where applicable
- unsupported shared options produce warnings or clear errors according to the
  provider contract
- reasoning configuration has provider-default behavior and explicit effort
  levels
- tests cover native support, coercion, and unsupported mappings

Exit gate:

- at least OpenAI, Anthropic, Google, and one OpenAI-compatible profile have
  audited mappings or documented non-support.

## M5 - Provider Package Decoupling

Goals:

- keep concrete providers as provider contract implementations
- preserve provider-native product features
- remove runtime/UI/root dependencies from provider packages

Acceptance criteria:

- OpenAI, Anthropic, Google, Ollama, ElevenLabs, and OpenAI-compatible packages
  have no production dependency on `llm_dart_ai`, chat, Flutter, root, or core
  compatibility packages
- provider-owned helper clients remain available
- repeated provider helper duplication is either accepted locally or promoted
  only after the `llm_dart_provider_utils` criteria are met
- dependency guards enforce the package graph

Exit gate:

- package-local tests and workspace dependency guards pass.

## M6 - Root, Legacy, And Migration Hardening

Goals:

- keep root as a facade and explicit compatibility bridge
- remove obsolete compatibility APIs when migration paths are documented
- make the breaking line understandable for existing users

Acceptance criteria:

- root does not own new implementations
- `llm_dart_core` remains compatibility-only or has a documented removal path
- examples prefer modern focused entrypoints
- migration docs include before/after code for provider calls, runtime helpers,
  provider options, metadata, and imports
- changelog calls out all breaking changes

Exit gate:

- clean consumer smoke tests pass for focused package imports, modern root
  facade imports, and any explicitly retained legacy imports.

## M7 - Release Readiness

Goals:

- prove the refactor with repeatable validation
- make the breaking release line publishable
- keep future regressions blocked by tooling

Acceptance criteria:

- workspace dependency guards pass
- root and core boundary guards pass
- package analysis and tests pass for touched packages
- Flutter adapter validation passes if runtime/chat contracts changed
- publish dry-run and consumer smoke instructions are updated
- release notes explain the migration strategy

Exit gate:

- the breaking line is ready for maintainer release decision with no hidden
  architecture exceptions.

## M8 - Post-Closure Structured Output Deepening

Goals:

- align `llm_dart_ai` structured output internals with the reference output
  strategy and stream event shape
- keep the existing `OutputSpec` public seam stable
- improve locality for JSON parsing, strategy selection, runner glue, and
  stream result replay

Acceptance criteria:

- `output_spec.dart` is a facade over focused structured output modules
- JSON helper functions remain internal rather than becoming public utility
  contracts
- `generateOutput`, `streamOutput`, `generateObject`, and `streamObject`
  keep their current behavior
- focused tests cover preserved structured output behavior and immutable JSON
  partial output

Exit gate:

- `llm_dart_ai` focused tests, `llm_dart_core` compatibility tests, package
  analysis, workspace analysis, and whitespace checks pass after the split.

## M9 - Post-Closure Text Call Result Runner Split

Goals:

- align text call internals with the reference generate/stream text
  result-versus-runner split
- keep `text_call.dart` as the stable public seam
- improve locality for result facade behavior and runner dispatch

Acceptance criteria:

- text call result facades live outside the runner glue module
- `generateTextCall` and `streamTextCall` keep their current public behavior
- raw stream collection and structured output adaptation remain covered by
  focused text call tests
- `llm_dart_core` compatibility exports continue to resolve the same names

Exit gate:

- `llm_dart_ai` text call tests, structured output tests, core compatibility
  tests, package analysis, workspace analysis, and whitespace checks pass.

## M10 - Post-Closure Stream Text Result Cancellation Split

Goals:

- align stream text internals with the reference stream result and event
  lifecycle split
- keep `stream_text_runner.dart` as the stable public stream run seam
- improve locality for stream result accessors and provider cancellation
  plumbing

Acceptance criteria:

- `StreamTextRunResult` lives outside the stream run loop implementation
- provider cancellation stream support lives outside the stream run loop
  implementation
- `streamTextRun` and `streamText` keep their current event ordering and final
  result behavior
- `llm_dart_core` compatibility exports continue to resolve the same stream
  runner names

Exit gate:

- stream runner focused tests, language model stream boundary tests, core
  compatibility stream runner tests, package analysis, workspace analysis, and
  whitespace checks pass.
