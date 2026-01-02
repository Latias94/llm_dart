# Versioning (llm_dart)

This repository is a monorepo that publishes multiple Dart packages under
`packages/`.

## Goals

- Keep the "suite" (`packages/llm_dart`) convenient and consistent.
- Allow provider packages to ship targeted bugfix releases without forcing a
  full repo-wide release every time.
- Keep versioning non-interactive and CI-friendly.

## Policy (0.x)

We treat **patch** releases as bugfix-only, and **minor** releases as the
release train for any new functionality.

- Bugfix only (no public API change): `0.11.0 -> 0.11.1` (patch).
- New features: `0.11.x -> 0.12.0` (minor).
- Breaking changes: `0.11.x -> 0.12.0` (minor) and use Conventional Commits `!`.

## Recommended workflow

### 1) Bugfix release for a single package

Set the target package version explicitly:

```bash
dart run tool/bump_version.dart set --package llm_dart_openai --version 0.11.1
```

Then validate and publish that package.

### 2) Feature release (minor)

Keep the repo consistent by bumping all packages to the same version:

```bash
dart run tool/bump_version.dart set-all --version 0.12.0
```

This also updates internal dependency constraints to `^0.12.0`.

## Melos scripts (optional)

You can run the same commands via Melos:

```bash
melos run version:set-all -- --version 0.12.0
melos run version:set -- --package llm_dart_openai --version 0.11.1
```

