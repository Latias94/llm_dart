# Release Posture Decision Gate

## Objective

Close the remaining Wave 2 evidence gap before scheduling additional
implementation refactors.

The project needs one maintainer-controlled release posture decision:

- publish `0.11.0-alpha.1` in dependency order, then validate pub.dev consumers
- or explicitly keep `0.11.0-alpha.1` unpublished and treat local release
  readiness plus local consumer smoke as the equivalent evidence baseline for
  this wave

## Current Evidence

Full release readiness was rerun after the modern-surface docs cleanup and
consumer-smoke modern-surface cleanup:

```powershell
dart run tool\release_readiness.dart
```

Result:

- run window: `2026-05-15T19:46:41.273980` to
  `2026-05-15T19:50:06.055516`
- elapsed: `3m 24s`
- passed, 13/13 steps
- consumer smoke passed all 24 local path steps
- workspace publish dry-run passed for 12 publishable package(s)
- pub.dev version availability still reports `0.11.0-alpha.1` as available

Local consumer smoke was rerun:

```powershell
dart run tool\run_consumer_smoke.dart
```

Result:

- run time: `2026-05-15T19:45+08:00`
- passed, 24/24 steps
- dependency source: local path workspace
- covered root Dart consumer, focused provider-only consumers, split-package
  consumer, and Flutter consumer

Pub version availability was rerun:

```powershell
dart run tool\check_pub_version_availability.dart
```

Result:

- run time: `2026-05-15T20:00+08:00`
- passed
- all focused packages remain `available-new-package` at
  `0.11.0-alpha.1`
- root `llm_dart` remains `available-new-version`; latest published root
  version is `0.10.7`

This confirms the alpha line is still unpublished.

## Option A - Publish Alpha

If the maintainer chooses to publish:

1. Re-run release readiness immediately before publishing:

   ```powershell
   dart run tool\release_readiness.dart
   ```

2. Publish in the dependency-aware order recorded by release readiness:

   - `llm_dart_provider`
   - `llm_dart_ai`
   - `llm_dart_core`
   - `llm_dart_transport`
   - `llm_dart_chat`
   - `llm_dart_openai`
   - `llm_dart_google`
   - `llm_dart_anthropic`
   - `llm_dart_ollama`
   - `llm_dart_elevenlabs`
   - `llm_dart_flutter`
   - `llm_dart`

3. Run published consumer smoke:

   ```powershell
   dart run tool\run_consumer_smoke.dart --published
   ```

4. Record alpha feedback as release blocker, migration gap, docs gap, or future
   refactor candidate.

## Option B - Explicit Non-Publish

If the maintainer chooses not to publish this alpha:

1. Record the decision in this file and `MILESTONES.md`.
2. Treat the latest local release readiness and local consumer smoke as the
   equivalent consumer evidence for the unpublished branch.
3. Keep compatibility removals blocked until there is either alpha feedback or
   a separate removal-specific workstream with its own migration proof.

## Decision Record

Fill this section when the maintainer decision is made.

Decision:

- `pending`

Decision time:

- `pending`

Decision owner:

- `pending`

Evidence:

- If publishing: link the publish log or package versions and the
  `dart run tool\run_consumer_smoke.dart --published` result.
- If not publishing: link the latest local release readiness result and record
  that local consumer smoke is the accepted equivalent evidence baseline for
  this wave.

Follow-up milestone:

- `pending`

## Gate Status

Status: waiting on maintainer decision.

Do not mark the Wave 2 goal complete until either Option A or Option B is
recorded with evidence.
