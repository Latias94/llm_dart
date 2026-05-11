# Priority Map

## P0 - Alpha Release Handoff

Finish the `0.11.0-alpha.1` handoff before opening another broad structural
change.

Required evidence:

- final release readiness passes immediately before publishing
- packages publish in dependency order
- clean consumers are revalidated against pub.dev versions after publication
- any publish blocker is fixed in the smallest release-hardening slice

Stop condition:

- do not start second-wave removals while the alpha release is still blocked by
  package metadata, publish dry-run, consumer smoke, or version availability.

## P0 - Release Gate Completeness

Root `dart test` is not enough evidence for the split architecture. The gate
must also run package-local test suites for the focused packages and the
Flutter adapter.

Default gate coverage should include:

- root guards
- root analysis
- root tests
- focused package tests
- clean Dart and Flutter consumer smoke
- workspace publish dry-run
- pub.dev version availability

Stop condition:

- if package-local tests are skipped, the report must make that explicit
  through `--skip-tests`; package tests should not be a separate manual memory
  step.

## P1 - Legacy Trunk Classification

Keep compatibility trunks classified before removing anything:

- `legacy.dart`: migration-only compatibility host
- `LLMBuilder`: frozen compatibility trunk for builder-era users
- `ai()`: soft-deprecated alias with one migration cycle before removal review
- root provider constructors: frozen compatibility host
- `createProvider(...)`: frozen generic compatibility helper
- `HttpConfig`: tied to the builder decision

Next action:

- collect alpha feedback and usage evidence
- update migration recipes where users still need a short modern replacement
- only schedule removal candidates that already have clear replacements

Non-goal:

- do not remove `legacy.dart`, `LLMBuilder`, or root provider constructors in
  this wave.

## P1 - Root Facade Thinness

Root `llm_dart` may depend outward as a facade, but it should not regain
implementation ownership.

Allowed root ownership:

- modern convenience facade
- focused public entrypoints
- explicit compatibility bridge
- migration documentation

Review targets:

- any new root-local provider implementation
- any new shared model contract placed in root
- any compatibility helper that can be moved into a provider package without
  breaking the public migration path

Stop condition:

- if a root change is needed only for compatibility, keep it named and tested
  as compatibility code.

## P2 - Core Compatibility Shell Decision

`llm_dart_core` is currently guarded as a compatibility shell. The next wave
should not delete it by default.

Next action:

- keep guards that reject new implementation ownership in `llm_dart_core/lib`
- record import telemetry from examples, tests, and alpha feedback
- decide later whether keeping the shell costs less than removing it

Removal review can start only when:

- modern packages and root facade cover the common import paths
- compatibility users have documented replacements
- package consumers no longer need broad `llm_dart_core` imports for migration

## P2 - Provider Utils Extraction Criteria

Reserve `llm_dart_provider_utils`, but do not publish it just because the target
graph names it.

Extract only when at least two provider packages need the same stable helper
contract in one of these areas:

- JSON-safe normalization
- provider-reference resolution
- media-type helpers
- schema normalization
- warning builders
- codec support that does not own transport

Non-goals:

- no Dio, retry, SSE, or Flutter ownership
- no provider-native lifecycle APIs
- no broad "common provider implementation" bucket

## P3 - Provider-Specific Expansion

New provider features should be demand-driven.

Prefer:

- provider-owned typed settings
- provider-owned helper clients
- provider-owned custom parts and summaries
- capability profiles that describe support without forcing shared APIs

Avoid:

- widening shared stream events for one provider
- copying reference repository packages for symmetry
- turning model catalogs, files, moderation, voices, or lifecycle APIs into
  common abstractions without repeated product pressure
