# Main Text API Naming Freeze

## Goal

This note closes the naming question that remained after the additive
`generateTextCall(...)` / `streamTextCall(...)` layer landed:

> Should the additive call-result layer fold back into `generateText(...)` and
> `streamText(...)`, or should the low-level helpers keep their current names?

## Decision

The current refactor round should freeze the split as:

- `generateTextCall(...)` and `streamTextCall(...)` are the recommended
  application-facing text call helpers
- `generateText(...)` and `streamText(...)` remain the low-level raw single-step
  helpers

We should not fold the additive layer back into the old helper names in the
current architecture round.

## Why

### 1. The Low-Level Names Already Mean Something Precise

In `llm_dart_core`, the old helper names already carry a clear architectural
meaning:

- one provider call
- one provider stream
- no richer result-placement promises
- no buffered partial-output side channels

Changing those names to mean a richer call surface would blur a boundary that
we already spent several rounds making explicit.

### 2. The Additive Layer Is The Right Product Surface

`generateTextCall(...)` and `streamTextCall(...)` now provide the productized
behavior that application code actually wants:

- delegated common getters
- optional parsed output
- final result futures
- partial structured-output streams
- array element streams
- stream-compatible iteration for raw text events

That is the better application surface.

### 3. We Avoid A Misleading Rename

If we folded the additive layer into `generateText(...)` /
`streamText(...)` now, we would create a semantic mismatch with the still-raw
`LanguageModel.generate(...)` / `LanguageModel.stream(...)` foundation.

That would make the codebase harder to reason about, not easier.

## Frozen Rule

From this point in the architecture workstream:

- examples and docs should prefer `generateTextCall(...)` /
  `streamTextCall(...)` for app-facing text generation
- `generateOutput(...)`, `streamOutput(...)`, and `streamOutputResult(...)`
  remain focused structured-output convenience surfaces
- `generateText(...)` and `streamText(...)` stay public, but they are the raw
  lower-level helpers rather than the preferred app-facing entry

## Future Rename Policy

If we ever want shorter primary names later, that should only happen through a
separate deliberate breaking round, for example:

- first rename the current low-level helpers to explicit raw names
- then promote the higher-level call layer

We should not silently repurpose the existing names while they still anchor the
low-level boundary elsewhere in the architecture docs and code.

## Conclusion

The naming question is now closed for the current refactor round:

- keep `generateText(...)` / `streamText(...)` as raw low-level helpers
- promote `generateTextCall(...)` / `streamTextCall(...)` as the application
  text API

That keeps the architecture honest and keeps the public guidance aligned with
the actual layering in the codebase.
