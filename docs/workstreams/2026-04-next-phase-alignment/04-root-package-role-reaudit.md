# Root Package Role Re-Audit

## Goal

Re-audit the root `llm_dart` package after the latest package moves and
documentation cleanup, then decide whether the root boundary still needs
immediate structural work.

## Current Root Shape

As of 2026-04-15, the root package now has a clearer role split than in earlier
audits:

- `llm_dart.dart`
  - default modern root entrypoint
- `ai.dart`
  - broad app-facing modern convenience shell
- `chat.dart`
  - focused pure Dart chat runtime shell
- `openai.dart`, `google.dart`, `anthropic.dart`
  - narrow provider-focused shells
- `legacy.dart`
  - explicit compatibility host

The root `pubspec.yaml` now also depends only on workspace packages rather than
directly depending on transport implementation dependencies such as `dio` or
`logging`.

That means one earlier structural concern is already resolved.

## What Improved Since Earlier Audits

### 1. Provider-Focused Root Shells Are Now Honest

The focused provider entrypoints now export provider-owned packages only:

- `openai.dart`
- `google.dart`
- `anthropic.dart`

They no longer re-export unrelated root conveniences such as:

- `AI`
- `core.dart`
- `transport.dart`

That is a meaningful ownership improvement compared with the older wider root
export graph.

### 2. The Root Modern Story Is Easier To Read

The root package now has a clearer public story:

- use `llm_dart.dart` or `ai.dart` for the broad modern app-facing path
- use provider packages or focused provider shells for provider-owned types
- use `legacy.dart` explicitly for compatibility

That is much closer to the intended architectural direction.

### 3. Root Runtime Dependencies Are No Longer The Main Concern

Because root runtime dependencies have already been slimmed back to workspace
packages, the root package is no longer carrying the same transport-level
pressure that earlier audits flagged.

The remaining root question is now mostly about export semantics and migration
timing, not runtime dependency leakage.

## What Still Stays Transitional

The root package still plays two roles at once:

- default modern facade
- compatibility host

That is still transitional, but it is now an acceptable transitional state.

Why it is still acceptable:

- the broad compatibility surface is already isolated under `legacy.dart`
- the focused provider shells are now narrower
- the modern app-facing root path is intentionally convenient for end users
- the repository still has no separate deprecation/removal plan for the
  compatibility host

## Decision

Do not force another root-slimming round right now.

Keep the root package in its current role:

- `ai.dart` remains the broad modern convenience shell
- `chat.dart` remains the convenience exception for the chat runtime
- provider-focused root shells remain narrow
- `legacy.dart` remains the explicit compatibility host

That is now a truthful, documentable boundary.

## What Should Reopen This Later

Reopen deeper root restructuring only if one of these becomes true:

1. compatibility deprecation/removal gets a concrete release plan
2. the broad modern root shell begins attracting new implementation weight
   instead of staying a facade
3. provider-focused root shells start widening again in ways that obscure
   ownership
4. publishing strategy changes so the compatibility host should move out of the
   main package entirely

## Workstream Consequence

The root-role re-audit is now complete for this phase.

The current conclusion is not "the root is perfect forever."

The conclusion is:

- the root is clear enough for the current stage
- no immediate additional slimming is required
- future work should reopen only when compatibility timing or publishing
  strategy changes

## Bottom Line

The root package is now better read as:

- a convenient modern facade for application users
- an explicit compatibility host for migration users

That is a stable enough role split for the current phase, so this topic should
leave the active backlog for now.
