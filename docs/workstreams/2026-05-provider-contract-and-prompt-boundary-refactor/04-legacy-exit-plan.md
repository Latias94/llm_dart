# Legacy Exit Plan

## Current State

The root package is now guarded as a facade, but the explicit legacy surface is
still large:

- `lib/legacy.dart`
- `lib/builder`
- `lib/models`
- `lib/providers`
- `lib/src/compatibility`

This is acceptable during migration, but it should not define the next
architecture line.

## Policy

Legacy compatibility is a release-window bridge. It is not a permanent design
input for provider contracts, prompt data, or AI runtime helpers.

New work should follow these rules:

- no new provider implementation ownership in root `lib/providers`
- no new model contracts in root `lib/models`
- no new builder-era configuration APIs
- no new request features exposed only through compatibility extension bags
- no new examples using `package:llm_dart/legacy.dart` unless the example is
  explicitly a migration guide

## Exit Options

### Option A - Delete Legacy In The Breaking Line

Remove root legacy implementation and keep only migration docs.

Pros:

- largest complexity reduction
- no mixed architecture in the package
- easiest to explain long term

Cons:

- highest user migration cost
- requires complete before/after examples
- may need a final compatibility release before the break

Recommended when the next line is an intentional major or clearly breaking
minor alpha.

### Option B - Move Legacy To A Separate Package

Create a separate compatibility package that depends on modern packages.

Pros:

- root package becomes clean
- users can opt into migration support
- legacy code no longer shapes root public API

Cons:

- more publish and maintenance overhead
- may preserve too much old behavior
- requires a clear sunset policy

Recommended only if there is strong user demand for extended migration.

### Option C - Keep Legacy But Freeze It Harder

Keep `lib/legacy.dart`, but add stricter guards and remove internal exports over
time.

Pros:

- lowest immediate breakage
- less publishing complexity

Cons:

- preserves maintenance cost
- keeps root package noisy
- easiest option to let architecture drift back

Recommended only as a short transition step.

## Recommendation

Use Option C only until the provider contract and prompt boundary refactor is
complete. Then choose Option A for the next intentional breaking line unless
there is clear user evidence that Option B is worth the maintenance cost.

## Exit Checklist

- migration guide covers old builder to modern provider factories
- migration guide covers old direct provider calls to runtime helpers
- migration guide covers old metadata request controls to provider options
- examples no longer import `legacy.dart` except migration examples
- guards reject new root provider implementation files
- guards reject new builder-era config APIs
- changelog clearly identifies removed compatibility surfaces
