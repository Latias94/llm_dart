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

## Selective Provider Expansion

- [x] Re-triage Google streamed TTS after the UI/runtime contract settles
- [x] Re-triage broader OpenRouter search mapping and any xAI subset beyond the audited live-search path
