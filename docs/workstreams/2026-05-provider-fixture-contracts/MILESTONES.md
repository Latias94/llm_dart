# Milestones

## M1 - Fixture Contract Foundation

Goals:

- create a provider-local fixture convention
- add the first OpenAI request and stream golden tests
- preserve public API and package graph

Acceptance criteria:

- `docs/workstreams/2026-05-provider-fixture-contracts/` exists
- OpenAI package has fixture JSON files under
  `packages/llm_dart_openai/test/fixtures/openai/`
- OpenAI has a focused fixture contract test
- the first fixture set covers request body encoding, stream event projection,
  tool replay, MCP behavior, and provider metadata
- focused fixture tests pass
- OpenAI package analysis passes
- workspace dependency guards pass

Current status:

- Complete.
- Workstream documentation is initialized.
- Fixture layout and naming rules are defined.
- OpenAI request body and stream event golden fixtures are in place.
- Focused fixture tests, existing focused OpenAI request/stream/language-model
  tests, OpenAI package analysis, and workspace dependency guards pass as of
  2026-05-15 13:19 +08:00.
