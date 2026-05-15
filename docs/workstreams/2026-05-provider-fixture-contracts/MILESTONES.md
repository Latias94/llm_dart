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

## M2 - Google Fixture Contrast

Goals:

- apply the same provider-local fixture convention to a non-OpenAI provider
- lock high-value Google GenerateContent request and stream contracts without
  adding shared fixture infrastructure
- prove the convention works across providers while keeping provider behavior
  provider-owned

Acceptance criteria:

- Google package has fixture JSON files under
  `packages/llm_dart_google/test/fixtures/google/`
- Google has a focused fixture contract test
- the fixture set covers request body encoding and stream event projection
- the request fixture covers media inputs, file references, function-call id
  replay, server-side tool replay, native tools, structured output, safety
  settings, reasoning, and multimodal tool results
- the stream fixture covers response metadata, usage, reasoning, tool calls,
  executable code, code execution results, server-side tool calls/responses,
  file output, grounding, URL context, safety ratings, and finish metadata
- focused fixture tests pass
- Google package analysis passes
- workspace dependency guards pass

Current status:

- Complete.
- Google request body and stream event golden fixtures are in place.
- The full release readiness gate passed at 2026-05-15 17:29 +08:00, including
  Google fixture contracts, package analysis, workspace guards, consumer smoke,
  publish dry-runs, and pub.dev version availability checks.
