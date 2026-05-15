# Milestones

## M1 - Anthropic Fixture Contract Baseline

Goals:

- extend provider-local fixture contracts from OpenAI to Anthropic
- add high-value Anthropic request and stream goldens
- preserve public API and package graph
- audit repeated patterns without extracting a shared package

Acceptance criteria:

- `docs/workstreams/2026-05-anthropic-fixture-contracts/` exists
- Anthropic package has fixture JSON files under
  `packages/llm_dart_anthropic/test/fixtures/anthropic/`
- Anthropic has a focused fixture contract test
- the first fixture set covers request body encoding, request metadata,
  stream event projection, tool replay, reasoning, and provider metadata
- focused fixture tests pass
- existing focused Anthropic tests pass with the new fixture tests
- Anthropic package analysis passes
- workspace dependency guards pass
- commit is created

Current status:

- Complete.
- Workstream documentation is initialized.
- Fixture scope and repetition audit are defined.
- Anthropic request body, request metadata, replay request body, and stream
  event golden fixtures are in place.
- Focused fixture tests, existing focused Anthropic tests, Anthropic package
  analysis, and workspace dependency guards pass as of
  2026-05-15 13:40 +08:00.
