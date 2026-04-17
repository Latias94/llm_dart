# Wave-1 Execution Decision

## Goal

Decide what should happen next with the already-landed wave-1 legacy removals
on `refactor/architecture-foundation`.

This document is not about:

- whether the removals are theoretically justified
- whether the migration notes exist

Those questions are already answered elsewhere.

This document answers the execution question:

> should this branch's wave-1 leaf removals ship now, or should they remain
> deferred off any non-breaking release line?

## Short Answer

The wave-1 removals are **release-ready only for an explicit breaking
window**.

They should **not** be folded into a normal `0.10.x` patch or minor-style
release by accident.

If the next release is not going to be communicated and treated as a deliberate
breaking release, these removals should stay deferred off that release line.

## Current Facts

The current repository state is:

- root package version is still `0.10.7`
- the branch already contains the wave-1 removal slice
- migration notes and provider-family replacement guidance already exist
- first-party docs and examples are already moved off the removed leaf APIs
- a concrete release-note draft now exists
- the broader compatibility trunks still remain in place

That means the question is no longer "is the repository ready to explain these
removals?"

The question is now only "is the next release vehicle explicitly allowed to be
breaking?"

## Why Wave 1 Is Ready For A Breaking Release

### 1. The Removed APIs Are Leaves, Not Trunks

Wave 1 removes:

- deprecated preset helper aliases
- deprecated builder web-search helpers
- `createProvider(..., extensions: ...)`
- the deprecated `CancelToken` alias

It explicitly does **not** remove:

- `legacy.dart`
- `LLMBuilder()`
- `createProvider(...)`
- non-deprecated root provider constructors
- `ai()` itself

That is already the conservative sequence this workstream wanted.

### 2. Migration Guidance Is Already In Place

The branch now already has:

- family-by-family preset-helper migration notes
- builder web-search replacement guidance
- posture notes for `ai()` and `createProvider(...)`
- a wave-1 release-note draft

This satisfies the repository's own rule that breaking removals should not
land without a clear replacement story.

### 3. First-Party Teaching Material Is Already Aligned

The migration-readiness work already moved examples and docs away from the
removed leaf APIs.

That means the repository is no longer undermining its own deprecation story by
still teaching the removed path as the default.

## Why Wave 1 Should Still Not Slip Into A Non-Breaking Release

### 1. The Published Line Is Still `0.10.7`

Even though the repository is still pre-`1.0.0`, the workstream already froze
the rule that removals should happen only in an explicit breaking window.

That means:

- do not hide breaking removals inside an ordinary patch release
- do not rely on "pre-1.0 means anything goes"
- do not merge this slice into a release train that is being communicated as
  ordinary maintenance

### 2. The Branch Already Contains Real API Removals

This is no longer a theoretical proposal.

The branch already removed public symbols that downstream code may still call.

That raises the bar for release discipline:

- explicit version choice
- explicit changelog text
- explicit migration communication

### 3. The Compatibility Trunks Are Deliberately Still Alive

Because `legacy.dart`, `LLMBuilder()`, `createProvider(...)`, and the root
provider constructors still remain, there is no reason to rush these leaf
removals through a vague release vehicle.

The removals are ready.

That does **not** mean they need to ship in the next release regardless of
release posture.

## Decision

The execution rule is now:

### If The Next Release Is An Explicit Breaking Release

Ship wave 1.

Required release actions:

- adapt `13-wave-1-release-note-draft.md` into the real `CHANGELOG.md` entry
- choose an explicit breaking version number
- call out both removed and intentionally retained compatibility surfaces
- keep the migration links visible in the release announcement

### If The Next Release Is Not An Explicit Breaking Release

Do **not** ship wave 1 in that release line.

Recommended handling:

- keep the removals on this branch only
- or defer/cherry-pick them into a later deliberate breaking branch
- but do not smuggle them into a maintenance or routine release train

## What This Decision Does Not Mean

This decision does **not** mean:

- the removals should be reverted now
- the branch is wrong
- the repository should keep the removed leaves indefinitely
- the next release must be breaking

It only means:

- the removals are justified and documented
- they are ready when the release vehicle is explicitly breaking
- they should otherwise stay deferred

## Recommended Release Posture

The cleanest posture is:

1. keep normal maintenance on the non-breaking release line when needed
2. keep wave-1 removals attached to the architecture/deprecation branch
3. ship them only when maintainers deliberately open the first conservative
   breaking window
4. observe downstream churn before considering `ai()`, `LLMBuilder`, or other
   broader compatibility trunks

## Bottom Line

Wave 1 is no longer blocked by missing migration guidance.

Wave 1 is blocked only by release posture.

That means the correct default is now simple:

- if the next release is explicitly breaking, ship wave 1
- otherwise, defer it without ambiguity
