# Remaining Boundary Fearless Refactor — Handoff

Status: Complete
Last updated: 2026-05-27

## Current State

The durable workstream is closed. The previous core seam refactor is closed and
committed as `13b2cb02 refactor!: deepen core seams and entrypoints`.

This lane covers the remaining boundary candidates:

- provider codec contract; completed in RBF-020 through
  `ProviderCodecContractRunner` in `llm_dart_test`;
- capability descriptor enforcement; completed in RBF-030 through
  `ProviderCapabilityGate` and `ModelCapabilityGate`;
- non-text app request seams; completed in RBF-040 through request objects for
  embedding, image, speech, and transcription helpers;
- chat turn and transport protocol; completed in RBF-050 through an internal
  `HttpChatTransportStreamSession`;
- provider options policy; completed in RBF-060 through typed OpenAI-family
  provider option namespace projections;
- serialization registry decision; completed in RBF-070 by extracting
  `VersionedJsonEnvelopeCodec` and retaining explicit codec families.

## Active Task

None. RBF-080 closeout passed.

## Decisions Since Last Update

- Open a new workstream because no existing active lane owns all six remaining
  boundary candidates.
- Do not reopen the root/app/provider-authoring seam that just closed.
- Start with provider codec contract because it has the largest repeated proof
  surface and can stay provider-owned.
- RBF-020 completed: shared fixture policy now lives in `llm_dart_test` via
  `ProviderCodecContractRunner`; OpenAI, Anthropic, Google, and Ollama fixture
  contracts use it. Provider codecs, warning generation, native replay, and
  error projection remain provider-owned.
- RBF-030 completed: capability gating now has one foundation Interface with
  hard requirement versus affordance modes. Inferred descriptors can surface in
  UI/discovery but do not satisfy hard runtime requirements.
- RBF-040 completed: non-text helpers now have app request seams and
  `*ForRequest(...)` variants. Existing convenience helpers are retained and
  delegate through those request objects.
- RBF-050 completed: HTTP transport stream consumption now routes through
  `HttpChatTransportStreamSession`, which owns frame projection, replay/resume
  mutation, terminal clearing, stream termination, and caught transport error
  recovery. A separate chat turn protocol was rejected because
  `DefaultChatSessionActiveTurn` already owns active turn ordering and
  completion lifecycle with good locality.
- RBF-060 completed: OpenAI-family typed provider options now own their
  provider namespace bag projection, matching the Vercel AI SDK providerOptions
  namespace shape while preserving typed option validation. Route codecs and
  compatibility warning Modules were retained as route-local policy.
- RBF-070 completed: a full serialization registry was rejected because
  explicit prompt/event/part/body codec families remain the deeper Interface.
  The shared repeated seam is only the schema-versioned envelope, now owned by
  `VersionedJsonEnvelopeCodec`.
- RBF-080 completed: final analyze, boundary guards, example guard, and
  whitespace checks passed. No required follow-on was split.
- Existing unrelated user changes in the working tree must not be reverted,
  formatted, or committed by accident.

## Blockers

- None known.

## Residual Risks

- Provider-specific error golden contracts remain intentionally local. Add a
  shared runner only after repeated provider error fixtures prove the policy is
  stable.
- Provider fixture expansion beyond OpenAI, Anthropic, Google, and Ollama can
  proceed opportunistically as new providers add golden fixtures.
- Commit staging must stay path-precise because the working tree contains
  unrelated pre-existing edits outside this lane.

## Next Recommended Action

- Stage only the lane's code, tests, and workstream docs; review the staged
  diff; then commit with a conventional commit message.
