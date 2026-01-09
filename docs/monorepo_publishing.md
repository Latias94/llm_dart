# Monorepo Publishing & Local Development (llm_dart)

This repo is a Dart monorepo that ships:

- A convenient “suite” package: `llm_dart` (in `packages/llm_dart`)
- Many pick-and-choose subpackages: `packages/llm_dart_*`

The primary constraint is **publishability**:

- Published `pubspec.yaml` files must not contain `path:` dependencies to other local packages.

This document describes the strategy used in this repository.

---

## 1) Rule: internal deps use versions

All internal dependencies use version constraints:

- Example: `llm_dart_core: ^0.10.5`

This applies to:

- `packages/llm_dart/pubspec.yaml` (the umbrella suite)
- All `packages/llm_dart_*` packages

This ensures every package can be published independently.

---

## 2) Local development: Dart pub workspaces

For local development in this repo, we use Dart pub workspaces:

- The repo root `pubspec.yaml` declares the workspace members via `workspace:`.
- Each workspace member package includes `resolution: workspace` in its `pubspec.yaml`.

This keeps all `pubspec.yaml` files publishable (no `path:` deps), while still
linking internal packages from source during development.

---

## 3) Optional tooling: Melos

This repo includes `melos.yaml` for optional scripting/versioning workflows,
but it is not required for dependency linking (pub workspaces already handle that).

Melos is pinned as a dev dependency in the repo root, so you can run it without a
global install via:

```bash
dart run melos --version
dart run melos run test
```

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
