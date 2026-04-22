# Wave-1 Release Vehicle And Checklist

## Goal

Turn the abstract "breaking release only" rule for the already-landed wave-1
removals into a concrete Dart/pub-compatible release vehicle, versioning
posture, and execution checklist.

This note answers:

> if maintainers do decide to publish wave 1 before `1.0.0`, what is the
> honest Dart package version to use, and what must be true before that release
> happens?

## Short Answer

The default release vehicle for the current wave-1 removals should be:

- `0.11.0-alpha.1` for the root `llm_dart` package

It should **not** be:

- a routine `0.10.x` maintenance release
- a silent breaking `0.11.0` stable release without a pre-release cycle
- an unnecessary forced jump to `1.0.0` when the package is not yet claiming
  stable API maturity

The recommended sequence is:

1. keep `0.10.x` for normal non-breaking maintenance
2. publish wave 1 as `0.11.0-alpha.1`
3. publish follow-up alphas/betas/RCs if migration feedback is still needed
4. publish `0.11.0` stable only when maintainers are comfortable with that
   breaking window

## Why `0.11.0-alpha.1` Fits Dart / Pub

### 1. Dart Uses SemVer For Packages, Including Pre-`1.0.0`

The official Dart pub versioning guide states that semantic versioning still
applies before `1.0.0`, but with the interpretation shifted down one slot:

- for a package below `1.0.0`, the "minor version is incremented for breaking
  changes"

That matches the release shape here:

- pre-preview starting point: `0.10.7`
- next breaking line: `0.11.0`

### 2. The Dart Tooling Confirms The Same Bump

Running the local tool against the current root package version confirms the
same interpretation:

```bash
dart pub bump breaking --dry-run
```

Current output on this branch:

```text
Would update version from 0.10.7 to 0.11.0.
```

That is the clearest tooling-level confirmation that a breaking bump from the
current line belongs on `0.11.0`, not `1.0.0`.

### 3. Pub Explicitly Supports Pre-Release Suffixes

The official pubspec guide explicitly documents pre-release suffixes such as:

- `-dev.4`
- `-alpha.12`
- `-beta.7`
- `-rc.5`

That means a release vehicle such as `0.11.0-alpha.1` is a normal, idiomatic
pub version, not a workaround.

### 4. Pub Also Treats Pre-Releases As Opt-In

The official publishing guide notes that pre-release packages are supported,
but users only get pre-releases if they explicitly ask for them through their
version constraints.

That is exactly what this repository wants for wave 1:

- breaking removals are publishable
- early adopters can validate migration
- routine stable consumers do not get the breaking slice by accident

## What This Changes In Repository Policy

The earlier architecture workstream froze a conservative rule that removals
should happen no earlier than `1.0.0`.

After checking Dart/pub versioning rules, this workstream now refines that
policy more precisely:

- removals still must not ship in routine maintenance releases
- removals still require migration docs and explicit release notes
- but the first conservative removal wave may ship in an explicit pre-`1.0.0`
  breaking pre-release such as `0.11.0-alpha.1`

In other words:

- the real guardrail was always "no silent routine removal"
- not "force every first breaking wave to wait for `1.0.0`"

## Recommended Versioning Strategy

### Maintenance Line: `0.10.x`

Use the `0.10.x` line only for:

- fixes
- docs
- examples
- diagnostics
- deprecation annotations
- other clearly non-breaking cleanup

Do **not** publish the current wave-1 removals on `0.10.x`.

### Breaking Preview Line: `0.11.0-alpha.x`

Use `0.11.0-alpha.1` as the default first release vehicle for wave 1.

What this release should communicate:

- this is an intentional breaking preview
- the removed APIs are leaves, not compatibility trunks
- migration guidance is already in place
- downstream validation is wanted before a stable `0.11.0`

### Stable Breaking Line: `0.11.0`

Publish `0.11.0` only after the preview cycle is good enough.

That does **not** require:

- jumping to `1.0.0`
- removing `legacy.dart`
- removing `LLMBuilder()`
- removing `createProvider(...)`
- removing non-deprecated root provider constructors
- removing `ai()` in the same wave

This is still a conservative removal wave, just in a Dart-idiomatic pre-`1.0`
version train.

## Workspace Package Versioning Posture

Before a real wave-1 release is published, the workspace also needs a coherent
dependency version story.

Current state:

- root `pubspec.yaml` now targets `^0.11.0-alpha.1` for the publishable direct
  workspace packages
- local workspace linking should now come from workspace-generated
  `pubspec_overrides.yaml`, not from checked-in runtime `path:` dependencies

That is much closer to a real alpha publication plan, but it still requires the
packages to be published in a coherent order.

### Minimum Required Publication Rule

If root `llm_dart` publishes `0.11.0-alpha.1`, every direct dependency that
will be resolved from pub must also have a publishable non-`dev` version, and
the root dependency ranges must be updated accordingly.

At minimum, that means:

- remove `-dev` suffixes from the publishable workspace packages the root
  package depends on
- publish those package versions before or together with the root package
- update the root dependency constraints to those published versions

### Recommended Default For Workspace Package Numbers

The simplest release posture is to align the publishable direct workspace
dependencies with the same preview line for this wave:

- root package: `0.11.0-alpha.1`
- direct published workspace dependencies: `0.11.0-alpha.1`

This is not mathematically required by SemVer, but it reduces avoidable release
coordination noise for the first breaking preview.

If maintainers later want different package-specific version cadences, that can
still be revisited after the architecture transition settles.

## Release Checklist

Use this checklist before turning the staged `[Unreleased]` changelog section
into a real release.

### 1. Confirm The Vehicle

- confirm that wave 1 is shipping as the first deliberate breaking preview
- confirm that the preview vehicle is `0.11.0-alpha.1`
- confirm that routine `0.10.x` maintenance releases remain removal-free

### 2. Confirm The Scope

- confirm that wave 1 still contains only the already-agreed leaf removals
- confirm that `legacy.dart`, `LLMBuilder()`, `createProvider(...)`,
  non-deprecated root provider constructors, and `ai()` retention remain
  unchanged
- confirm that no new trunk removals were accidentally added after the
  wave-1 freeze

### 3. Finalize Version Numbers

- choose the root release version and date
- choose the publishable non-`dev` versions for root dependencies
- update root dependency constraints in `pubspec.yaml`
- update workspace package versions where needed

### 4. Finalize Public Release Text

- ensure `CHANGELOG.md` carries the explicit pre-release heading and date
- keep the migration summary in the real changelog
- keep the "Removed", "Deprecated", and "Kept" sections explicit
- make sure release notes still say this wave removes leaves, not trunks

### 5. Validate The Workspace

Run the repository-wide validation commands from the workspace root:

```bash
melos analyze
melos test
```

If publication dry-runs are part of the release flow, also run dry-runs for the
root package and the publishable workspace packages that the root release now
depends on.

### 6. Publish And Tag Deliberately

- publish the required workspace dependency packages in the chosen order
- publish the root package only after dependency versions are resolvable
- tag the pre-release with the final version
- announce the release as a conservative breaking preview, not as a trunk
  cleanup

### 7. Decide The Exit From Preview

After `0.11.0-alpha.1` ships:

- gather downstream migration feedback
- decide whether another alpha/beta/RC is needed
- publish `0.11.0` stable only when the preview feedback is good enough
- keep future compatibility-trunk removal discussion out of this first preview
  wave

## Official References

- Dart pub versioning:
  <https://dart.dev/tools/pub/versioning>
- Dart pubspec version field and pre-release examples:
  <https://dart.dev/tools/pub/pubspec>
- Dart package publishing and pre-release behavior:
  <https://dart.dev/tools/pub/publishing>

## Bottom Line

The repository no longer lacks release-note text for wave 1.

The remaining release question is now narrower:

- ship the already-prepared leaf-removal slice as `0.11.0-alpha.1`
- or keep it deferred until maintainers are ready for that preview

What should not happen is the ambiguous middle:

- silently ship wave 1 on `0.10.x`
- or force a premature `1.0.0` just to justify a conservative first breaking
  preview
