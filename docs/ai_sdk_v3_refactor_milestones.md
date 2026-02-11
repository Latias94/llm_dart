# AI SDK v3 Parity Refactor: Milestones

Status: Draft  
Last updated: 2026-02-11

This document defines milestones for the refactor described in:

- `docs/ai_sdk_v3_refactor_purpose.md`
- `docs/ai_sdk_v3_refactor_todo.md`

The guiding rule: **internal data structures + semantics match AI SDK v3**,
while **public Dart APIs remain idiomatic**.

Current progress (as of 2026-02-11):

- M0: Achieved (guardrails + baseline docs + fixture policy)
- M1: Achieved (canonical v3 part set + v3 JSONL codec + goldens)
- M2: Achieved for streaming + tool loop (stream-start + block id normalization; tool loop emits canonical parts)
- M3: Achieved (multiple providers covered by fixture-backed v3 golden tests)
- M4/M5: In progress (expand protocol reuse + stabilize + cleanup)

Notable parity decisions (see `docs/ai_sdk_v3_refactor_purpose.md`):

- Provider-native tool `toolName` is resolved from request `providerTools[*].name` when available.
- MCP approval requests use `approvalId != toolCallId` (AI SDK semantics); tool calls use `mcp.<name>` and `dynamic=true`.
- Provider tool deltas are opt-in (`emitProviderToolDeltas=true`), default `false`.

---

## Milestone M0: Baseline alignment and guardrails

Exit criteria:

- `LLMFinishReason` unified/raw matches AI SDK v3 semantics
- Provider metadata namespacing policy is documented and tested
- Fixture sync is green (`melos run fixtures:check`)

Deliverables:

- Confirm canonical references and invariants in docs
- Identify the first provider to fully migrate (recommended: OpenAI Responses)

Acceptance use cases:

- `fixtures:check` passes and fixtures are up to date.
- Provider metadata key policy is enforced by tests (canonical + alias deep-equal).

---

## Milestone M1: Canonical v3 part set (types + codec)

Exit criteria:

- `LLMStreamPart` can represent every AI SDK v3 `type`
- JSON codec round-trips parts without loss (unit tests)
- JSONL stream dumping/reading helpers exist for golden tests

Deliverables:

- Core types updated in `llm_dart_core`
- Codec utilities in `llm_dart_core` or `llm_dart_provider_utils` (whichever fits dep rules)

Acceptance use cases:

- A unit test round-trips every canonical part through JSON encode/decode.
- A JSONL writer/reader can serialize and parse a stream deterministically.

---

## Milestone M2: Orchestration normalization (parts-first always)

Exit criteria:

- `streamChatParts` always emits:
  - one `stream-start`
  - stable non-empty block ids
  - exactly one terminal `finish`
- Tool loop streaming emits canonical tool lifecycle parts

Deliverables:

- Normalization layer in `llm_dart_ai` (id injection + finish enforcement)
- Conformance tests for ordering and boundary behavior

Acceptance use cases:

- Any provider stream missing block ids is normalized to non-empty ids.
- Exactly one `stream-start` and exactly one terminal `finish` are emitted.
- Tool loop streaming emits tool lifecycle parts in correct order.

---

## Milestone M3: First fully-migrated provider (fixture-backed)

Exit criteria:

- One provider’s streaming output matches v3 golden fixtures:
  - ordering
  - tool input/tool call semantics
  - sources/files (when present)
  - finish usage + finishReason

Recommended target:

- OpenAI Responses (richest event surface; best ROI for fixtures)

Deliverables:

- Golden tests using vendored fixtures
- Provider adapter emits canonical parts with minimal provider-specific branching

Acceptance use cases:

- At least one provider scenario passes golden `.jsonl` comparison:
  - tool input split across arbitrary boundaries
  - usage arriving late (after finish reason), if applicable
  - provider-native tool events never become locally executable tool calls

Current coverage (goldens added in this repo):

- OpenAI Responses:
  - `test/fixtures/v3_parts/openai/openai-local-shell-tool.1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-shell-tool.1.session1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-shell-tool.1.session2.jsonl`
  - `test/fixtures/v3_parts/openai/openai-code-interpreter-tool.1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-apply-patch-tool.1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-apply-patch-tool-delete.1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-error.1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-reasoning-encrypted-content.1.session1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-reasoning-encrypted-content.1.session2.jsonl`
  - `test/fixtures/v3_parts/openai/openai-reasoning-encrypted-content.1.session3.jsonl`
  - `test/fixtures/v3_parts/openai/openai-reasoning-encrypted-content.1.session4.jsonl`
  - `test/fixtures/v3_parts/openai/openai-mcp-tool-approval.1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-mcp-tool-approval.2.jsonl`
  - `test/fixtures/v3_parts/openai/openai-mcp-tool-approval.3.jsonl`
  - `test/fixtures/v3_parts/openai/openai-mcp-tool-approval.4.jsonl`
  - `test/fixtures/v3_parts/openai/openai-mcp-tool.1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-web-search-tool.1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-image-generation-tool.1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-file-search-tool.1.jsonl`
  - `test/fixtures/v3_parts/openai/openai-file-search-tool.2.jsonl`
- OpenAI Chat Completions:
  - `test/fixtures/v3_parts/openai_chat/azure-model-router.1.jsonl`
- Azure OpenAI (Responses API shape):
  - `test/fixtures/v3_parts/azure/azure-code-interpreter-tool.1.jsonl`
  - `test/fixtures/v3_parts/azure/azure-web-search-preview-tool.1.jsonl`
  - `test/fixtures/v3_parts/azure/azure-reasoning-encrypted-content.1.session1.jsonl`
  - `test/fixtures/v3_parts/azure/azure-reasoning-encrypted-content.1.session2.jsonl`
  - `test/fixtures/v3_parts/azure/azure-reasoning-encrypted-content.1.session3.jsonl`
  - `test/fixtures/v3_parts/azure/azure-reasoning-encrypted-content.1.session4.jsonl`
  - `test/fixtures/v3_parts/azure/azure-image-generation-tool.1.jsonl`
  - `test/fixtures/v3_parts/azure/openai-file-search-tool.1.jsonl`
  - `test/fixtures/v3_parts/azure/openai-file-search-tool.2.jsonl`
- Anthropic:
  - `test/fixtures/v3_parts/anthropic/anthropic-web-search-tool.1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-web-fetch-tool.1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-json-tool.1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-json-tool.2.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-json-other-tool.1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-json-output-format.1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-message-delta-input-tokens.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-mcp.1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-code-execution-20250825.1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-code-execution-20250825.2.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-code-execution-20250825.pptx-skill.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-tool-no-args.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-programmatic-tool-calling.1.session1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-tool-search-deferred-bm25.session1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-tool-search-deferred-bm25.session2.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-tool-search-deferred-bm25.session3.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-tool-search-deferred-regex.session1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-tool-search-deferred-regex.session2.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-tool-search-deferred-regex.session3.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-tool-search-bm25.1.session1.jsonl`
  - `test/fixtures/v3_parts/anthropic/anthropic-tool-search-regex.1.session1.jsonl`
- OpenAI-compatible (DeepSeek fixtures):
  - `test/fixtures/v3_parts/openai_compatible/deepseek-text.jsonl`
  - `test/fixtures/v3_parts/openai_compatible/deepseek-reasoning.jsonl`
  - `test/fixtures/v3_parts/openai_compatible/deepseek-tool-call.jsonl`
- xAI Responses:
  - `test/fixtures/v3_parts/xai/xai-text-streaming.1.jsonl`
  - `test/fixtures/v3_parts/xai/xai-text-with-reasoning-streaming.1.jsonl`
  - `test/fixtures/v3_parts/xai/xai-text-with-reasoning-streaming-store-false.1.jsonl`
  - `test/fixtures/v3_parts/xai/xai-web-search-tool.1.jsonl`
  - `test/fixtures/v3_parts/xai/xai-x-search-tool.jsonl`
- Open Responses (LMStudio fixtures):
  - `test/fixtures/v3_parts/open_responses/lmstudio-basic.1.jsonl`
  - `test/fixtures/v3_parts/open_responses/lmstudio-tool-call.1.jsonl`
  - `test/fixtures/v3_parts/open_responses/lmstudio-tool-call.2.jsonl`
- Groq (OpenAI-compatible Chat Completions; contract fixtures):
  - `test/fixtures/v3_parts/groq/groq-text.1.jsonl`
  - `test/fixtures/v3_parts/groq/groq-tool-call.1.jsonl`
- Ollama (NDJSON streaming; contract fixtures):
  - `test/fixtures/v3_parts/ollama/ollama-text-thinking.1.jsonl`
  - `test/fixtures/v3_parts/ollama/ollama-tool-call.1.jsonl`
  - `test/fixtures/v3_parts/ollama/ollama-text-length.1.jsonl`
  - `test/fixtures/v3_parts/ollama/ollama-tool-call-length.1.jsonl`
- Google (Gemini API; contract fixtures):
  - `test/fixtures/v3_parts/google/google-thinking-text.1.jsonl`
  - `test/fixtures/v3_parts/google/google-tool-call.1.jsonl`
  - `test/fixtures/v3_parts/google/google-code-execution.1.jsonl`
  - `test/fixtures/v3_parts/google/google-grounding-sources.1.jsonl`
- Google Vertex (express mode; contract fixtures):
  - `test/fixtures/v3_parts/google_vertex/google-thinking-text.1.jsonl`
  - `test/fixtures/v3_parts/google_vertex/google-tool-call.1.jsonl`
  - `test/fixtures/v3_parts/google_vertex/google-code-execution.1.jsonl`
  - `test/fixtures/v3_parts/google_vertex/google-grounding-sources.1.jsonl`
  - `test/fixtures/v3_parts/google_vertex/google-vertex-non-express-model-path.1.jsonl`
- MiniMax (Anthropic-compatible; vendored Anthropic fixtures):
  - `test/fixtures/v3_parts/minimax/anthropic-json-tool.1.jsonl`
  - `test/fixtures/v3_parts/minimax/anthropic-message-delta-input-tokens.jsonl`

---

## Milestone M4: Expand to protocol reuse layers + OpenAI-compatible baseline

Exit criteria:

- Anthropic-compatible + OpenAI-compatible streaming parsers both:
  - emit v3-consistent canonical parts
  - preserve provider-only fields via `providerMetadata`/`raw`
- Regression tests cover chunk boundary edge cases

Deliverables:

- Conformance suites under `test/protocols/...`
- Fixture-based tests for at least 2 providers

Acceptance use cases:

- Anthropic-compatible and OpenAI-compatible both pass the canonical parts contract:
  - reasoning block ordering
  - tool call parsing/invalid call behavior (best-effort)
  - finish usage + finishReason consistency

---

## Milestone M5: Cleanup and stabilization

Exit criteria:

- Provider packages no longer depend on “reserved tool name + throw” heuristics
- Tool name mapping is used consistently where provider tools exist
- Documentation updated:
  - standard surface
  - streaming semantics
  - migration notes for breaking changes

Deliverables:

- Deprecations (if any) applied and documented in `docs/migrations/`
- `CHANGELOG.md` entries for user-visible breakages

Acceptance use cases:

- Provider packages no longer use ad-hoc “reserved tool name” heuristics.
- Tool name mapping is used consistently where provider-native tools exist.
- Documentation explicitly describes the fixture alignment contract and JSONL golden format.
