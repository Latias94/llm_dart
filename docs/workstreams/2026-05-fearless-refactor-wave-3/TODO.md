# Fearless Refactor Wave 3 — TODO

Status: Closed
Last updated: 2026-05-23

## M0 — Scope And Evidence Freeze

- [x] FR3-010 [owner=planner] [deps=none] [scope=docs/workstreams/2026-05-fearless-refactor-wave-3]
  Goal: Freeze the five refactor candidates, dependency order, non-goals, and
  evidence anchors.
  Validation: workstream docs exist and agree.
  Evidence: `docs/workstreams/2026-05-fearless-refactor-wave-3/DESIGN.md`
  Handoff: Start with chat session turn lifecycle because it has the strongest
  depth and locality payoff.

## M1 — Chat Session Turn Lifecycle

- [x] FR3-020 [owner=codex] [deps=FR3-010] [scope=packages/llm_dart_chat/lib/src/default_chat_session*.dart,packages/llm_dart_chat/test/default_chat_session_test.dart]
  Goal: Deepen the `DefaultChatSession` turn lifecycle so the public chat
  session adapter delegates command and continuation state transitions to a
  focused internal implementation.
  Validation: `dart analyze packages/llm_dart_chat` and
  `dart test packages/llm_dart_chat/test/default_chat_session_test.dart`
  Review: verify public `ChatSession` behavior and exports remain stable.
  Evidence: `EVIDENCE_AND_GATES.md`
  Handoff: DONE. `DefaultChatSessionTurnLifecycle` now owns turn commands and
  continuation policy while `DefaultChatSession` remains the public adapter.

## M2 — OpenAI-Family Options Compatibility Mass

- [x] FR3-030 [owner=codex] [deps=FR3-020] [scope=packages/llm_dart_openai/lib/src/provider/openai_provider_options_bag*.dart,packages/llm_dart_openai/lib/src/provider/openai_family_invocation_options.dart,packages/llm_dart_openai/test/openai_family_option_resolver_test.dart]
  Goal: Make typed OpenAI-family option resolution the clear primary path and
  localize compatibility bag transport behind a narrower internal seam.
  Validation: `dart analyze packages/llm_dart_openai` and
  `dart test packages/llm_dart_openai/test/openai_family_option_resolver_test.dart`
  Review: preserve compatibility behavior and public exports.
  Evidence: `EVIDENCE_AND_GATES.md`
  Handoff: DONE. Invocation resolution now owns typed/bag merge while
  `openai_provider_options_bag*.dart` stays focused on compatibility bag
  parse/encode transport.

## M3 — Provider Fixture Parity

- [x] FR3-040 [owner=codex] [deps=FR3-030] [scope=packages/llm_dart_ollama/test,packages/llm_dart_ollama/lib/src,packages/llm_dart_openai/test,packages/llm_dart_openai/lib/src]
  Goal: Fill the highest-value provider-local fixture gaps, starting with
  Ollama request/stream/replay behavior and OpenAI native lifecycle behavior
  only where fixture contracts improve refactor safety.
  Validation: focused fixture contract tests for touched providers plus package
  analysis.
  Review: keep fixtures provider-local unless a repeated helper proves a real
  seam.
  Evidence: provider fixture JSON files and `EVIDENCE_AND_GATES.md`
  Handoff: DONE. Ollama now has provider-local golden fixtures for request
  body projection, compatibility warnings, and stream event decoding.

## M4 — Serialization Protocol Families

- [x] FR3-050 [owner=codex] [deps=FR3-040] [scope=packages/llm_dart_provider/lib/src/serialization,packages/llm_dart_provider/test]
  Goal: Preserve `SerializationJsonSupport` source compatibility while moving
  protocol-family implementation details into clearer modules with stronger
  locality.
  Validation: `dart analyze packages/llm_dart_provider` and
  `dart test packages/llm_dart_provider/test`
  Review: ensure provider prompt-part options and stream envelope behavior stay
  byte-compatible.
  Evidence: `EVIDENCE_AND_GATES.md`
  Handoff: DONE. `SerializationJsonSupport` remains the stable compatibility
  facade while provider internals now depend on narrower metadata, media, and
  tool support modules. A boundary test prevents internal JSON codecs from
  depending back on the wide facade.

## M5 — Root Legacy Classification

- [x] FR3-060 [owner=codex] [deps=FR3-050] [scope=lib,packages/*/lib,examples,docs/workstreams/2026-04-legacy-deprecation-planning,docs/workstreams/2026-05-root-legacy-prompt-options-breaking-line,tool]
  Goal: Finish the post-alpha root legacy classification path by encoding the
  chosen keep/remove/document decisions in docs, examples, and guards.
  Validation: relevant guard scripts, workspace analysis smoke, and focused
  tests affected by root exports.
  Review: separate product/release decisions from internal implementation
  cleanup.
  Evidence: `EVIDENCE_AND_GATES.md`
  Handoff: Publish-side feedback remains outside this lane unless the user
  explicitly asks to run release side effects.

## M6 — Closeout

- [x] FR3-070 [owner=planner] [deps=FR3-060] [scope=docs/workstreams/2026-05-fearless-refactor-wave-3]
  Goal: Close the lane or split any incomplete remainder into narrower
  follow-ons.
  Validation: final touched-package gates, workspace guards, release-readiness
  smoke where practical, and `git diff --check`.
  Review: workstream compliance and code-quality review before closeout.
  Evidence: `EVIDENCE_AND_GATES.md`, `WORKSTREAM.json`
  Handoff: DONE. All five refactor slices are complete, and the remaining
  release/publish work belongs to a separate lane or explicit maintainer
  follow-on.
