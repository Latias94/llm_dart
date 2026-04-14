# TODO

## Workstream Setup

- [x] Create the post-closure workstream scaffold
- [x] Freeze the initial priority map

## Public Boundary Alignment

- [x] Re-audit the root README and package READMEs against the frozen modern-versus-compatibility boundary
- [x] Re-audit high-visibility examples and keep builder-era examples explicit on `package:llm_dart/legacy.dart`
- [x] Add a short handoff note from the closed `2026-03-architecture-refactor` workstream into this follow-up phase

## Flutter And UI Extensions

- [x] Freeze the provider-owned custom-part / summary / message-mapper contract for Flutter and other UI layers
- [x] Decide whether an additive app-owned renderer registry is justified above the shared `ChatMessageMapper`
- [x] Re-audit transient `data-*`, step-finish, and reconnect semantics before widening any UI helper surface

## Dependency And Compatibility Guardrails

- [x] Freeze package-level dependency rules for new code
- [x] Define which remaining root helpers are compatibility-only and should not receive new modern implementation weight
- [x] Consider a CI or lint guard that prevents package implementation files from importing `package:llm_dart/...`
- [x] Re-audit the remaining Anthropic compatibility request builder before
  opening another symmetry-driven helper split
- [x] Extract Google image compatibility request and response shaping out of
  the root image shell without changing public compatibility behavior
- [x] Extract ElevenLabs audio compatibility request and response shaping out
  of the root audio shell without changing bridge or fallback behavior
- [x] Thin the Ollama fallback chat module by separating facade, request
  shaping, streamed parsing, and response wrapping
- [x] Extract OpenAI image compatibility request and response shaping out of
  the root image capability shell without changing public behavior
- [x] Thin the ElevenLabs compatibility shell by separating bridge
  eligibility, bridge codec translation, and bridge response normalization
  from fallback orchestration
- [x] Extract OpenAI assistants query shaping, local utility helpers, and
  import/export parsing out of the compatibility capability shell
- [x] Thin the Anthropic compatibility adapter by separating request planning
  and role-aware prompt conversion from the bridge adapter shell
- [x] Extract OpenAI moderation request shaping and local analysis/reporting
  helpers out of the compatibility capability shell
- [x] Thin the OpenAI compatibility root provider shell by moving capability
  policy and audio convenience helpers into provider-local support
- [x] Extract OpenAI completion request shaping, parsing, presets, retry,
  batch, and token helpers out of the compatibility capability shell
- [x] Extract OpenAI Responses non-streaming lifecycle and stateful
  conversation helpers out of the public compatibility facade
- [x] Extract Anthropic chat stream SSE framing, event semantics, tool-use
  aggregation, and error mapping out of the parser facade
- [x] Extract Google chat message, tool, and tool-choice payload encoding out
  of the request-body builder

## Selective Provider Expansion

- [x] Re-triage Google streamed TTS after the UI/runtime contract settles
- [x] Re-triage broader OpenRouter search mapping and any xAI subset beyond the audited live-search path
