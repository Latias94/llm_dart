# Milestones

## M1 - Hotspot And Boundary Freeze

Goals:

- audit the largest provider implementation files
- freeze the first decomposition order
- define helper publication criteria

Acceptance criteria:

- hotspot audit exists
- non-goals are explicit
- first provider slice is selected
- shared helper extraction criteria are written down

Current status:

- workstream scaffold created
- initial hotspot audit recorded from current source shape
- reference lessons from `repo-ref/ai` recorded without copying its package
  graph blindly

## M2 - OpenAI Responses First Slice

Goals:

- split one OpenAI Responses responsibility out of the large codec
- keep behavior unchanged
- strengthen fixture-based tests around the extracted boundary

Acceptance criteria:

- focused OpenAI tests pass
- extracted helper has a single reason to change
- public OpenAI facade remains stable
- release readiness remains green

Current status:

- OpenAI Responses codec boundary audit is documented.
- Request encoding has moved into provider-local
  `openai_responses_request_codec.dart`.
- `OpenAIResponsesCodec` remains the package-private facade used by
  `OpenAILanguageModel`.
- Focused OpenAI request, stream, language-model integration tests, package
  analysis, and workspace dependency guards pass for this slice.

## M3 - Second Provider Contrast Slice

Goals:

- apply the same boundary discipline to a non-OpenAI provider
- prove the pattern is not OpenAI-specific

Preferred candidates:

- Anthropic message/content/tool replay boundary
- Google content/tool/file projection boundary
- Ollama chat request/stream parser boundary

Acceptance criteria:

- focused provider tests pass
- provider-native behavior remains provider-owned
- no new provider runtime dependency violations

Current status:

- Anthropic was selected as the non-OpenAI contrast provider.
- Anthropic tool configuration has moved into provider-local
  `anthropic_tool_configuration.dart`.
- `AnthropicMessagesCodec` still owns message body assembly, prompt block
  projection, tool result replay, files, cache-control scanning, and beta
  discovery.
- Focused Anthropic messages tests, language-model integration tests, package
  analysis, workspace dependency guards, root boundary guard, and core
  compatibility guard pass for this slice.

## M4 - Provider Implementation Kit Decision

Goals:

- inventory helper duplication after at least two implementation slices
- decide internal-only versus public utility package

Acceptance criteria:

- repeated helpers are listed with provider users
- public `llm_dart_provider_utils` is either deferred with rationale or
  designed with a stable scope
- no utility package is created for one-provider convenience

Current status:

- pending

## M5 - Release Readiness And Closure

Goals:

- validate the provider-internal refactor across the whole workspace
- close the workstream with migration notes if public behavior changed

Acceptance criteria:

- focused provider tests pass
- workspace dependency guards pass
- full release readiness passes
- any public migration notes are updated

Current status:

- pending
