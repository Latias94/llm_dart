# Release Readiness Report

- Repository: `F:/SourceCodes/Github/llm_dart`
- Version: `0.11.0-alpha.1`
- Started: `2026-05-12T22:41:38.407833`
- Finished: `2026-05-12T22:46:44.162209`
- Elapsed: `5m 5s`
- Result: `passed`

## Steps

| Step | Status | Exit Code | Elapsed |
| --- | --- | ---: | ---: |
| Workspace dependency guards | passed | 0 | 446ms |
| Root package boundary guards | passed | 0 | 408ms |
| Core compatibility shell guard | passed | 0 | 213ms |
| Provider replay metadata guard | passed | 0 | 187ms |
| Transport boundary guard | passed | 0 | 220ms |
| Test legacy-import guard | passed | 0 | 239ms |
| Example API guard | passed | 0 | 248ms |
| Workspace analysis | passed | 0 | 2.549s |
| Workspace tests | passed | 0 | 48.127s |
| Workspace package tests | passed | 0 | 43.686s |
| Consumer smoke | passed | 0 | 1m 28s |
| Workspace publish dry-run | passed | 0 | 1m 47s |
| Pub version availability | passed | 0 | 13.872s |

## Publish Order

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

## Post-Publish Consumer Smoke

- Repeat consumer smoke against the published pub.dev versions after the packages are released with `dart tool/run_consumer_smoke.dart --published`.
- Validate clean root Dart, OpenAI-only, split-package, and Flutter consumers without local path overrides.
- Keep `test(...)` for pure controller/import smoke tests; reserve `testWidgets(...)` for tests that pump widgets.
