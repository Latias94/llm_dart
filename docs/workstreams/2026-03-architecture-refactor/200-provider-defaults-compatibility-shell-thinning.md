# 200 Provider Defaults Compatibility Shell Thinning

## Why This Slice Exists

After the recent root-shell thinning rounds, `lib/src/provider_defaults.dart`
was no longer a large implementation hotspot, but it still mixed two different
roles:

- active shared default constants through `ProviderDefaults`
- a legacy map-based OpenAI-compatible catalog through
  `OpenAICompatibleDefaults`

Those are not the same abstraction level.

`ProviderDefaults` is still used as a root compatibility helper for default
URLs, models, and capability sets. By contrast, `OpenAICompatibleDefaults` is a
legacy compatibility catalog whose modern typed replacement is already
`OpenAICompatibleConfigs`.

So the structural problem was no longer "too many lines", but "one file still
hosts both an active defaults helper and a residual compatibility catalog".

## What Changed

This slice keeps the public compatibility import path stable while narrowing the
ownership boundary:

- `ProviderDefaults` stays in `lib/src/provider_defaults.dart`
- `OpenAICompatibleDefaults` moves into
  `lib/src/compatibility/openai_compatible_defaults.dart`
- `lib/src/provider_defaults.dart` now re-exports
  `OpenAICompatibleDefaults` as a thin compatibility shell

That means external callers can still import the same stable path, while the
source layout becomes more honest about which surface is still compatibility
only.

## Why This Is Better

- keeps `ProviderDefaults` focused on active shared defaults instead of mixed
  compatibility catalogs
- makes the map-based OpenAI-compatible catalog explicitly compatibility-owned
- keeps the modern typed direction with `OpenAICompatibleConfigs` unchanged
- avoids another breaking import-path change while still improving structure

## Boundary Decision

This change does **not** remove `OpenAICompatibleDefaults` yet.

Even though the repository itself no longer depends on that map-based catalog,
it is still part of the public compatibility surface. The safer step today is
to relocate it behind a compatibility shell instead of deleting it
immediately.

The intended layering is now clearer:

- typed modern OpenAI-compatible discovery lives in
  `OpenAICompatibleConfigs`
- shared default values live in `ProviderDefaults`
- legacy map-based OpenAI-compatible defaults live under `src/compatibility/`

## Why This Matches The Reference Direction

The useful lesson from `repo-ref/ai` is ownership, not package-count symmetry.

Provider-family configuration catalogs should not stay mixed into unrelated
root helper files once the typed provider path already exists elsewhere.

Moving the legacy map-based OpenAI-compatible catalog under a compatibility
subdirectory follows that ownership rule without copying the reference
repository's exact file layout.

## Validation

This slice is validated with:

- `dart analyze lib/src/provider_defaults.dart lib/src/compatibility/openai_compatible_defaults.dart test/core/provider_defaults_test.dart`
- `dart test test/core/provider_defaults_test.dart`

## Follow-Up

After this slice, `capability_management.dart` is **not** the next best split
candidate.

That file is still small enough that further fragmentation would look more like
copying the reference repository's file granularity than solving a real local
problem.

The next worthwhile cleanup should instead continue targeting mixed-ownership
compatibility hotspots or stale compatibility facades, not tiny already-cohesive
root files.
