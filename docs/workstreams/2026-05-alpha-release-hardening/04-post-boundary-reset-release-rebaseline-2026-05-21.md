# Post-Boundary-Reset Release Rebaseline — 2026-05-21

## Objective

Rebaseline the alpha release-hardening lane after the fearless boundary reset.
The reset intentionally changed the release graph:

- removed `packages/llm_dart_core`
- removed the core compatibility shell guard
- added `llm_dart_provider_utils` as a shared provider-implementation utility
  package
- moved OpenAI routing, provider specifications, provider transport calls, and
  AI stream JSON composition behind deeper seams

## Package Graph Decision

The publishable package order is now:

1. `llm_dart_provider`
2. `llm_dart_ai`
3. `llm_dart_transport`
4. `llm_dart_provider_utils`
5. `llm_dart_chat`
6. `llm_dart_openai`
7. `llm_dart_google`
8. `llm_dart_anthropic`
9. `llm_dart_ollama`
10. `llm_dart_elevenlabs`
11. `llm_dart_flutter`
12. `llm_dart`

`llm_dart_core` must not be published for this line. Keeping a deprecated
package would preserve a misleading ownership boundary, so the correct alpha
contract is explicit removal plus migration guidance.

`llm_dart_provider_utils` is publishable because provider packages now depend
on it for shared send/stream/cancellation/error choreography. It is not an
application-facing package; it is a stable enough provider-adapter seam for the
alpha.

## API Surface Audit

Current public posture:

- root `llm_dart` exports provider-neutral runtime surfaces only
- concrete provider construction lives in direct provider packages
- `package:llm_dart/core.dart` re-exports `llm_dart_ai` as the focused shared
  runtime surface
- migration docs describe `llm_dart_core` as removed
- compatibility builder/root provider/model paths remain removed
- clean consumer smoke must validate root, focused packages, split packages,
  and Flutter without reintroducing legacy imports

## Validation Run

Fast gate:

```powershell
dart --suppress-analytics run tool/release_readiness.dart --skip-tests --skip-consumer-smoke --skip-publish-dry-run --report=build/release_readiness_post_fbr_fast.md
```

Result: passed.

This proves guard wiring and analyzer state, but it does not replace the full
publish gate.

Full gate:

```powershell
dart --suppress-analytics run tool/release_readiness.dart --report=build/release_readiness_post_fbr_full.md
```

Result: passed, 14/14 steps in 6m 41s.

Evidence:

- `build/release_readiness_post_fbr_full.md`
- guards passed
- workspace analysis passed
- workspace tests passed
- focused workspace package tests passed
- clean consumer smoke passed
- publish dry-runs passed for 12 packages with 0 warnings
- pub.dev version availability passed

## Required Before Publishing

The updated package graph has a fresh full release gate. Publish only with
explicit maintainer approval, then run post-publish consumer smoke against
pub.dev versions.
