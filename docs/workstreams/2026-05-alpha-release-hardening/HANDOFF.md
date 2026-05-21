# Alpha Release Hardening — Handoff

Status: Active
Last updated: 2026-05-21

## Current State

The fearless boundary reset has already landed. The release-hardening lane is
now rebaselined around the new package graph:

- `llm_dart_core` is deleted and must not appear in publish order.
- `llm_dart_provider_utils` is a real publishable provider-implementation
  utility package.
- root imports are provider-neutral; concrete providers are imported from
  direct provider packages.

## Completed In This Rebaseline

- Updated release-hardening docs that still referred to core compatibility.
- Added machine-readable `WORKSTREAM.json` and this handoff file.
- Added the current evidence ledger.
- Ran a fast readiness gate:
  `dart --suppress-analytics run tool/release_readiness.dart --skip-tests --skip-consumer-smoke --skip-publish-dry-run --report=build/release_readiness_post_fbr_fast.md`
  — passed.
- Ran targeted tooling tests — passed, 58 tests.
- Ran focused publish dry-runs for `llm_dart_provider_utils`,
  `llm_dart_chat`, and `llm_dart` — passed with zero warnings and only
  expected workspace override hints.
- Ran the full release gate:
  `dart --suppress-analytics run tool/release_readiness.dart --report=build/release_readiness_post_fbr_full.md`
  — passed 14/14 steps in 6m 41s.

## Next Task

Publish only after explicit maintainer approval, in this dependency order:

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

After publishing:

```powershell
dart --suppress-analytics run tool/run_consumer_smoke.dart --published
```

If pub.dev or Flutter network checks fail because of local network/proxy, retry
with `--proxy=http://127.0.0.1:10809`.

## Publish Posture

The branch is locally release-ready after the package graph changed. It is not
published yet.
