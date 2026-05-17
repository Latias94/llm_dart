# Goal Completion Audit

## Objective Restated

The Wave 2 goal is to prepare the next intentional breaking line using alpha
feedback, source evidence, and the completed provider/runtime boundary as the
foundation.

The goal is not complete just because the architecture is planned. It requires
release or non-release evidence, consumer smoke evidence, modern-surface audit
evidence, root/core compatibility classification, provider helper duplication
inventory, provider-utils extraction evidence, a bounded next milestone, and a
guard against reopening the completed provider/runtime stream boundary.

## Prompt-To-Artifact Checklist

| Requirement | Evidence | Status |
| --- | --- | --- |
| Canonical goal text is recorded | `GOAL.md` | complete |
| alpha publish or explicit non-publish decision is recorded | `MILESTONES.md` and `07-release-posture-decision-gate.md` say actual publishing has not started; no maintainer non-publish decision is recorded. `dart run tool\check_pub_version_availability.dart` on 2026-05-15T20:00+08:00 confirmed `0.11.0-alpha.1` remains unpublished. | missing |
| post-publish or equivalent consumer smoke evidence is recorded | `docs/workstreams/2026-05-alpha-release-hardening/03-release-readiness-audit-2026-05-15.md` records local consumer smoke passed; this audit reran local path consumer smoke on 2026-05-15T19:45+08:00 and all 24 steps passed; full release readiness reran on 2026-05-15T19:46-19:50+08:00 and passed 13/13 steps including consumer smoke. No post-publish smoke exists because publishing has not happened. | partially covered |
| modern API docs/examples are audited for provider-facing or legacy-first usage | `02-modern-surface-audit.md`; first cleanup executed in `06-modern-surface-docs-cleanup.md` | complete |
| root and `llm_dart_core` compatibility surfaces are classified with removal blockers or review windows | `03-root-core-compatibility-inventory.md` | complete |
| provider helper duplication is inventoried across focused providers | `04-provider-helper-duplication-inventory.md` | complete |
| proposed `llm_dart_provider_utils` extraction has evidence from at least two provider packages | `04-provider-helper-duplication-inventory.md` finds no extraction justified yet | complete as a negative decision |
| next implementation milestone is selected as one bounded workstream | the docs-only modern-surface cleanup was selected and executed in `06-modern-surface-docs-cleanup.md`; a follow-up consumer smoke modern-surface cleanup was selected and executed in `08-consumer-smoke-modern-surface.md`; the next post-cleanup milestone remains gated on alpha feedback or explicit non-publish decision | partially covered |
| no task reopens completed provider/runtime stream boundary without a concrete defect | `01-architecture-blueprint.md` and `GOAL.md` both freeze this rule | complete |
| non-goals were respected: no `legacy.dart` removal | no source removal performed in this wave | complete |
| non-goals were respected: no `LLMBuilder` removal | no source removal performed in this wave | complete |
| non-goals were respected: no `llm_dart_core` deletion | no source removal performed in this wave | complete |
| non-goals were respected: no `llm_dart_provider_utils` publication | no package added or published | complete |
| non-goals were respected: no provider package layout rewrite for symmetry | no source layout changes performed | complete |
| non-goals were respected: no shared model contract widening for one provider | no source contract changes performed | complete |
| non-goals were respected: no provider/runtime stream ownership change | no source stream ownership changes performed | complete |

## Audit Result

The goal is not complete.

Missing or weakly verified items:

- maintainer has not published `0.11.0-alpha.1` and has not recorded an
  explicit non-publish decision
- post-publish consumer smoke cannot run until packages are published; current
  evidence is local consumer smoke only
- the docs-only milestone has been executed, but the next milestone after it is
  still conditional because alpha feedback does not exist yet

## Safe Next Step

Ask the maintainer for one release posture decision:

- publish `0.11.0-alpha.1` in dependency order and run
  `dart run tool\run_consumer_smoke.dart --published`
- or explicitly record that this alpha will remain unpublished and treat the
  latest local release-readiness plus the evidence inventories as the
  equivalent smoke baseline

Until that decision exists, do not mark the goal complete and do not schedule
compatibility removals.

## Latest Local Smoke Evidence

Command:

```powershell
dart run tool\run_consumer_smoke.dart
```

Run time:

- `2026-05-15T19:45+08:00`

Result:

- passed, 24/24 steps
- dependency source: local path workspace
- covered root Dart consumer, focused provider-only consumers, split-package
  consumer, and Flutter consumer

This is valid equivalent local smoke evidence for the unpublished branch, but
it is not a substitute for `--published` smoke after packages are released.

## Latest Full Release Readiness Evidence

Command:

```powershell
dart run tool\release_readiness.dart
```

Run time:

- started: `2026-05-15T19:46:41.273980`
- finished: `2026-05-15T19:50:06.055516`
- elapsed: `3m 24s`

Result:

- passed, 13/13 steps
- workspace dependency guards, root package boundary guards, core compatibility
  shell guard, provider replay metadata guard, transport boundary guard, test
  legacy-import guard, and example API guard all passed
- workspace analysis passed
- workspace tests passed
- workspace package tests passed for 11 package(s)
- consumer smoke passed all 24 local path steps
- workspace publish dry-run passed for 12 publishable package(s)
- pub.dev version availability passed and still reports `0.11.0-alpha.1` as
  available

This proves the current working tree remains locally release-ready after the
modern-surface docs cleanup and consumer-smoke modern-surface cleanup. It still
does not replace the maintainer-controlled publish or explicit non-publish
decision.

## Latest Consumer Smoke Modern-Surface Evidence

Files changed:

- `tool/run_consumer_smoke.dart`
- `test/tool/run_consumer_smoke_test.dart`

Change:

- split-package consumer smoke now constructs
  `ai.UserModelMessage.text(...)`
- split-package consumer smoke now checks `ai.ModelMessageRole.user`
- focused regression test prevents returning to `UserPromptMessage` or
  `PromptRole` in that smoke program

Commands:

```powershell
dart test test\tool\run_consumer_smoke_test.dart
dart run tool\run_consumer_smoke.dart --direct-package-config
dart run tool\run_consumer_smoke.dart
```

Run time:

- `2026-05-15T19:43+08:00` through `2026-05-15T19:45+08:00`

Result:

- `dart test test\tool\run_consumer_smoke_test.dart`: passed, 26/26 tests
- direct package-config consumer smoke: passed, 7/7 programs
- full local consumer smoke: passed, 24/24 steps

## Latest Pub Version Availability Evidence

Command:

```powershell
dart run tool\check_pub_version_availability.dart
```

Run time:

- `2026-05-15T20:00+08:00`

Result:

- passed
- `llm_dart_provider`, `llm_dart_ai`, `llm_dart_core`,
  `llm_dart_transport`, `llm_dart_chat`, `llm_dart_openai`,
  `llm_dart_google`, `llm_dart_anthropic`, `llm_dart_ollama`,
  `llm_dart_elevenlabs`, and `llm_dart_flutter` remain
  `available-new-package`
- root `llm_dart` remains `available-new-version` at `0.11.0-alpha.1`;
  latest published root version is `0.10.7`
