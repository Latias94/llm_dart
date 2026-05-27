# Pre-Release Boundary Freeze — Handoff

Status: Complete
Last updated: 2026-05-27

## Current State

The lane is complete. The repository was clean before opening this lane. Recent
commits before this workstream:

- `d37259ff docs: record release migration state`
- `234ddf05 refactor!: harden remaining architecture boundaries`
- `13b2cb02 refactor!: deepen core seams and entrypoints`

## Active Task

None. PRF-070 is complete.

## Decisions Since Last Update

- Open a new workstream because the five requested deliverables are release
  freeze work, not another provider/runtime rewrite.
- Keep the lane narrow: proof, manifests, policy, and navigation.
- Start with release ledger so later tasks can add evidence to one publish
  home.
- PRF-020 completed: release ledger and guard now validate publish posture,
  package pubspec names, workstream status alignment, gate tool existence, and
  known deferrals.
- PRF-030 completed: ElevenLabs provider-local fixture contracts now lock
  speech JSON transport requests and transcription multipart semantic fields.
- PRF-040 completed: app facade exports are classified in
  `docs/release/app_facade_exports.json`, and
  `tool/check_app_facade_exports.dart` enforces root directives plus
  `llm_dart_ai/app.dart` provider foundation symbol drift.
- PRF-050 completed: HTTP chat transport protocol policy is frozen in code and
  release docs; v2 is the default and missing legacy stream protocol decodes as
  v1.
- PRF-060 completed: OpenAI Responses projection families now have a
  package-private ownership index with tests that check family ids and file
  references.
- PRF-070 completed: final gates passed, the workstream status is complete, and
  the release ledger is `release_ready` while publish remains a manual
  maintainer action.

## Blockers

- None known.

## Publish Blockers

- None from this architecture lane.
- Actual `pub publish` is intentionally not automated and still requires
  maintainer approval.

## Post-Alpha Follow-Ons

- Revisit app facade symbol removals only on a later breaking line with
  migration notes.
- Expand provider error goldens after a second provider repeats the same error
  projection fixture needs.
- Revisit an OpenAI Responses runtime registry only if multiple new native
  projection families repeat dispatcher complexity.

## Next Recommended Action

- Review the final diff and publish manually when the maintainer is ready.
