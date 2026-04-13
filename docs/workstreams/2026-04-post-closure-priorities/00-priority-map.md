# Post-Closure Priority Map

## Why A New Phase Exists

The previous workstream closed the large architecture questions. That is a good
outcome, but it also changes what “progress” means.

The next phase should not behave like another open-ended architecture audit.
The next phase should convert the frozen boundaries into:

- clearer public guidance
- clearer implementation guardrails
- a smaller, better-ordered backlog

## What Is Already Good Enough

The following areas are no longer the main structural problem:

- workspace package splitting
- shared prompt/result/stream/UI data structures
- the minimal chat runtime split across `llm_dart_chat` and
  `llm_dart_flutter`
- the broad OpenAI-family migration umbrella
- the broad community-provider decoupling umbrella
- event-model completeness versus `repo-ref/ai`

That means the next step should not be “find more architecture debt” in those
same areas unless a new repeated concrete problem appears.

## Priority 1 - Public Boundary Alignment

### Why It Matters

The architecture is much healthier than the public story around it.

Without a tighter public story, users can still misread:

- which entrypoint is recommended
- which API is transitional
- when to use `llm_dart`
- when to use provider-owned packages
- how Flutter code should combine the shared mapper with provider-owned helpers

### Deliverables

- root README follow-up references
- package README alignment
- example guidance alignment

### Risk If Skipped

The codebase can become structurally cleaner while still feeling confusing to
users, which then creates pressure to add the wrong compatibility shortcuts.

## Priority 2 - Provider UI Extension Contract

### Why It Matters

The remaining UI question is not about adding more shared events. The shared
event and UI-part model is already broad enough for the current scope.

The real remaining question is how richer provider-owned UI behavior should be
consumed consistently.

### What Already Exists

Today, the codebase already shows a usable pattern:

- shared `ChatMessageMapper` for stable cross-provider summaries
- `GoogleCustomPart`, `GoogleCustomPartSummary`, and `GoogleMessageMapper`
- `OpenAICustomPart`, `OpenAICustomPartSummary`, and `OpenAIMessageMapper`

This is already close to the right direction.

### What Still Needs To Be Frozen

- whether that provider-owned helper trilogy is the intended pattern
- whether an additive app-owned registry is worth adding later
- where transient `data-*` and reconnect-only UI details should stay out of
  persisted shared message state

## Priority 3 - Dependency Direction And Compatibility Containment

### Why It Matters

The current dependency direction is strong, but it is still easy to regress if
new modern implementation code drifts back into the root package or if new
third-party dependencies spread without a policy.

### Verified Current Facts

On 2026-04-13, the workspace dependency graph is:

- `llm_dart_core`
  - no runtime package dependencies
- `llm_dart_transport`
  - depends on `llm_dart_core`, `dio`, and `logging`
- provider packages
  - depend only on `llm_dart_core` and `llm_dart_transport`
- `llm_dart_chat`
  - depends only on `llm_dart_core` and `llm_dart_transport`
- `llm_dart_flutter`
  - depends on `flutter`, `llm_dart_chat`, and `llm_dart_core`

An implementation-import audit also shows that package implementation files do
not currently import `package:llm_dart/...`.

### What Should Happen Next

- write the dependency rules down as an explicit policy
- treat root helpers as compatibility-owned by default unless proven otherwise
- consider lightweight enforcement in CI

## Priority 4 - Selective Provider Expansion

### Why It Matters

Some provider-specific topics are still worth revisiting, but only after the
public guidance and guardrails are stable.

### Recommended Order

1. Re-triage Google streamed TTS
2. Re-triage broader OpenRouter search mapping
3. Re-triage any xAI scope beyond the audited live-search subset

### Important Constraint

Each reopened item should show a concrete product need, repeated integration
need, or replay-fidelity need. Symmetry with another provider is not enough.

## What Should Not Be Done Next

The following moves would be low-value or actively harmful in this phase:

- splitting `llm_dart_community` into many small packages just because
  `repo-ref/ai` has finer provider granularity
- widening the shared event model to carry provider-local replay payloads
- adding provider-specific UI rendering logic directly into `llm_dart_flutter`
- adding new modern provider implementation logic into root compatibility files
