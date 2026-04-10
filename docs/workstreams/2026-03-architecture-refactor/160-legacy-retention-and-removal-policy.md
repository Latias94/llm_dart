# 160 Legacy Retention And Removal Policy

## Why

The repository has now reached a point where "remove legacy" is no longer a
useful blanket instruction.

There are two different things hiding behind the word "legacy":

- the legacy **surface**
- the legacy **implementation weight**

Those should not be treated the same way.

If we remove the surface too early, we break migration-era users before the
modern provider-owned path fully covers the real repository use cases.

If we keep the implementation weight in the legacy layer for too long, the new
architecture never becomes honest: provider-owned packages stay secondary while
the root compatibility layer keeps acting like the real implementation home.

The repository therefore needs a frozen policy that says both:

- the legacy compatibility surface still stays alive for now,
- but the legacy layer must keep getting thinner over time.

## Decision

Keep the legacy compatibility surface, but keep shrinking its implementation
weight.

In practical terms:

- keep explicit migration entrypoints such as `legacy.dart`,
- keep root compatibility provider shells,
- keep builder/factory compatibility paths,
- keep flat legacy config and extension reads where migration still depends on
  them,
- but do not treat those layers as the long-term implementation home.

The compatibility layer should increasingly behave like:

- an adapter,
- a fallback boundary,
- a migration shell,
- and a deprecation surface.

It should increasingly stop behaving like:

- the main home for request codecs,
- the main home for stream parsing,
- the main home for transport plumbing,
- or the main home for new provider-specific product features.

## Frozen Rules

### 1. Keep The Legacy Surface Explicit

The legacy surface should remain explicit rather than implicit.

That means the repository should keep:

- `package:llm_dart/legacy.dart` as the broad compatibility import target,
- compatibility provider subclasses returned by legacy builder/factory flows,
- root compatibility provider shells for residual migration-era APIs,
- compatibility routing for request shapes that still need fallback.

This is important because explicit compatibility surfaces are easier to
document, deprecate, and eventually remove than accidental compatibility spread
across the default root entrypoint.

### 2. Keep Moving Implementation Weight Downward

The legacy layer should continue shedding real implementation weight into:

- provider-owned modern packages,
- shared core helpers,
- shared transport helpers,
- or focused provider-local compatibility support modules.

Recent OpenAI cleanup already demonstrates the intended pattern:

- request mechanics moved behind provider-local helpers,
- request-body shaping moved into a local shared support file,
- streamed parsing state moved into a local shared support file,
- bridge/fallback routing moved out of the public provider shell and into a
  dedicated local facade.

That is the right direction for the rest of the repository as well.

### 3. New Stable Features Do Not Belong To Legacy By Default

A new feature should not automatically land in the legacy layer just because
the old provider API still exists.

The default rule is:

- provider-owned modern path first,
- compatibility adapter only when migration needs it,
- legacy-only implementation only when there is no honest modern replacement
  yet and the feature is explicitly compatibility-scoped.

### 4. Legacy May Gain Thin Adapters, Not New Heavy Subsystems

The legacy layer may still gain:

- thin routing helpers,
- compatibility config adapters,
- bridge-safe request guards,
- deprecations,
- migration docs,
- and narrow fallback support.

It should avoid gaining:

- new heavy transport logic,
- new duplicated request codecs,
- new duplicated stream codecs,
- or new repository-wide abstractions invented only to keep legacy code alive.

### 5. Removal Timing Stays Conservative

This policy works together with `34-legacy-api-removal-window.md`.

The removal timing remains:

- no earlier than `1.0.0`,
- only after modern replacements are real,
- only after examples and migration docs exist,
- only after the repository can explain exactly which compatibility APIs are
  disappearing and what replaces them.

## What This Means For Refactoring

When evaluating a legacy compatibility file, the main question is now:

> Is this file preserving migration-era public surface, or is it still hosting
> too much real implementation?

If it is mostly public-surface preservation, keeping it is acceptable.

If it is still hosting too much real implementation, the next move should be to
extract, delegate, or relocate that implementation rather than debating whether
the public compatibility shell should disappear immediately.

That is why the current repository direction should be:

- preserve the shell,
- reduce the weight,
- document the migration,
- then remove only when coverage and timing are honest.

## Architectural Effect

This policy clarifies a repository-wide rule that was already emerging through
the refactor:

- legacy survives as a migration boundary,
- not as the long-term center of gravity.

That keeps the architecture aligned with the same principle we keep borrowing
from `repo-ref/ai`:

- stable public layers may survive for compatibility,
- but real implementation ownership should move to the modern, narrower,
  provider-owned layers over time.
