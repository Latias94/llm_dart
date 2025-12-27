# Monorepo Publishing & Local Development (llm_dart)

This repo is a Dart monorepo that ships:

- A convenient “suite” package: `llm_dart`
- Many pick-and-choose subpackages: `packages/llm_dart_*`

The primary constraint is **publishability**:

- Published `pubspec.yaml` files must not contain `path:` dependencies to other local packages.

This document describes the strategy used in this repository.

---

## 1) Rule: internal deps use versions

All internal dependencies use version constraints:

- Example: `llm_dart_core: ^0.10.5`

This applies to:

- `pubspec.yaml` at the repo root (`llm_dart`)
- All `packages/llm_dart_*` packages

This ensures every package can be published independently.

---

## 2) Local development: use `pubspec_overrides.yaml` (not published)

For local development in this repo, the root package uses `pubspec_overrides.yaml`
to redirect internal dependencies to local paths:

- `pubspec_overrides.yaml` (repo root)

Notes:

- `pubspec_overrides.yaml` is **not** published to pub.dev.
- This keeps local development fast and consistent while preserving publishability.

This repo also includes `pubspec_overrides.yaml` in each `packages/llm_dart_*`
subpackage so `dart pub get` works from within subpackage directories during
development (these override files are not published).

---

## 3) Optional: workspace tooling with Melos

This repo includes `melos.yaml` so maintainers can use `melos` for:

- bootstrapping local overrides across all packages
- running scripts across packages
- versioning and publishing workflows (if adopted later)

This repo does not require `melos` for end users.

Common commands (maintainers):

- `melos bootstrap`
- `melos run test`
- `melos run format`

---

## 4) Publishing checklist

Before publishing:

1. Ensure all packages share the intended version (this repo currently uses a single version across packages).
2. Confirm no `path:` dependencies exist in any `pubspec.yaml`.
3. Run tests at the repo root: `dart test -j 1`
4. Publish packages in dependency order (examples):
   - `llm_dart_core`
   - `llm_dart_provider_utils`
   - `llm_dart_builder`
   - protocol reuse packages (`llm_dart_openai_compatible`, `llm_dart_anthropic_compatible`)
   - provider packages (`llm_dart_openai`, `llm_dart_google`, ...)
   - task layer (`llm_dart_ai`)
   - suite (`llm_dart`)

---

## 5) Why this mirrors Vercel AI SDK

Vercel AI SDK is also a monorepo where:

- package splits are “real” and publishable
- internal dependencies are versioned for publishing
- local development uses workspace tooling to link packages

We mirror this approach to keep “suite + composability” sustainable long-term.
