# Fearless Refactor Wave 3 — Milestones

Status: Closed
Last updated: 2026-05-23

## M0 — Scope And Evidence Freeze

Exit criteria:

- The five refactor candidates are ordered.
- Non-goals and public behavior constraints are explicit.
- First executable task is chosen.

Primary evidence:

- `docs/workstreams/2026-05-fearless-refactor-wave-3/DESIGN.md`
- `docs/workstreams/2026-05-fearless-refactor-wave-3/TODO.md`

Current status:

- Completed on 2026-05-23.

## M1 — Chat Session Turn Lifecycle

Exit criteria:

- `DefaultChatSession` delegates turn lifecycle implementation behind a clearer
  internal seam.
- Existing chat session behavior, tool continuation behavior, resume behavior,
  and transient data behavior remain stable.
- Focused chat package analysis and tests pass.

Primary gates:

- `dart analyze packages/llm_dart_chat`
- `dart test packages/llm_dart_chat/test/default_chat_session_test.dart`

Current status:

- Completed on 2026-05-23.

## M2 — OpenAI-Family Options Compatibility Mass

Exit criteria:

- Typed OpenAI-family option resolution is the obvious primary path.
- Compatibility bag parsing and encoding remain supported but more local.
- Existing option resolver tests pass without public export churn.

Primary gates:

- `dart analyze packages/llm_dart_openai`
- `dart test packages/llm_dart_openai/test/openai_family_option_resolver_test.dart`

Current status:

- Completed on 2026-05-23.

## M3 — Provider Fixture Parity

Exit criteria:

- At least one missing high-value provider fixture gap is closed.
- Fixture contracts remain provider-local.
- Touched provider analysis and focused fixture tests pass.

Primary gates:

- Provider-specific fixture contract tests added or updated in the touched
  package.
- Touched provider package analysis.

Current status:

- Completed on 2026-05-23.

## M4 — Serialization Protocol Families

Exit criteria:

- `SerializationJsonSupport` remains source-compatible.
- Protocol-family implementation locality improves inside
  `llm_dart_provider`.
- Provider prompt-part option encoding and stream envelope behavior remain
  stable.

Primary gates:

- `dart analyze packages/llm_dart_provider`
- `dart test packages/llm_dart_provider/test`

Current status:

- Completed on 2026-05-23.

## M5 — Root Legacy Classification

Exit criteria:

- Keep/remove/document decisions for remaining root legacy concerns are
  explicit.
- Docs, examples, and guards encode the chosen behavior.
- Product/release follow-ons are split from internal cleanup.

Primary gates:

- Relevant guard scripts.
- Workspace analysis smoke when exports or examples move.

Current status:

- Completed on 2026-05-23.

## M6 — Closeout

Exit criteria:

- All slices are complete or split.
- Evidence is current.
- `WORKSTREAM.json` status is updated.
- Remaining risks and follow-ons are recorded in `HANDOFF.md`.

Primary gates:

- Final touched-package gates.
- Workspace guards.
- `git diff --check`.

Current status:

- Completed on 2026-05-23.
