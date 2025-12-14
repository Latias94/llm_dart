## Releasing / Publishing (Monorepo)

This repository is a Dart **Pub Workspace** with multiple packages under `packages/`.
The root package (`llm_dart/`) is the **batteries-included** package, and the
subpackages under `packages/` can be published independently for fine-grained
dependency control.

### Goals

- Keep `llm_dart` as the “batteries-included” package.
- Allow users to depend on individual provider packages (`llm_dart_openai`, `llm_dart_google`, …) without pulling the whole stack.
- Avoid development-only dependency tricks (no committed `pubspec_overrides.yaml`, no `dependency_overrides` for workspace linking).

### Before You Publish

1) **Decide the publish set**

- Which packages are public on pub.dev?
- Which stay private/internal?

2) **Remove `publish_to: none` for publishable packages**

- In each publishable package `packages/<pkg>/pubspec.yaml`, remove `publish_to: none`.
- Keep `publish_to: none` only for packages you do not want to publish.
- If you want to publish the root `llm_dart` bundle, remove `publish_to: none`
  in the root `pubspec.yaml` as well.

3) **Ensure required package files exist**

Each publishable package directory must contain:

- `LICENSE`
- `README.md`
- `CHANGELOG.md`

4) **Versioning strategy**

Pick one and stick to it:

- **Single-version strategy**: all packages share the same version (simpler for users).
- **Independent versions**: packages version independently (more flexible but more bookkeeping).

5) **Internal dependencies must be versioned**

Ensure internal dependencies are **version constraints**, not local `path` dependencies.
In this repo, published packages should depend on other published packages via `^x.y.z`.

6) **Update changelogs**

- Update `CHANGELOG.md` (and/or per-package changelogs if you later adopt them).
- Ensure the release notes match the versions you’re about to publish.

### Suggested Release Flow (Manual)

For each package you plan to publish:

1) Validate the package locally:

```bash
dart pub get
dart analyze .
dart test
```

2) Dry-run publish (run inside the package directory):

```bash
dart pub publish --dry-run
```

3) Publish (run inside the package directory):

```bash
dart pub publish
```

4) Tag the release in git (optional but recommended):

```bash
git tag <package>-v<version>
git push --tags
```

### Using Melos (Optional)

Melos is used here as a **convenience runner** (scripts), not as the source of truth for dependency resolution.

Common commands:

```bash
dart run melos run analyze
dart run melos run test
```

If you later decide to automate versioning/publishing with Melos, document:

- The chosen versioning mode (single vs independent)
- The exact Melos commands and required configuration
- CI expectations (dry-run on PR, publish on tag)

### Preflight Checklist

- [ ] No committed `pubspec_overrides.yaml`
- [ ] No `dependency_overrides` in published packages
- [ ] `publish_to: none` removed only where intended
- [ ] Versions updated consistently (per your chosen strategy)
- [ ] `dart analyze .` clean
- [ ] `dart test` green
- [ ] `dart pub publish --dry-run` clean for each package
