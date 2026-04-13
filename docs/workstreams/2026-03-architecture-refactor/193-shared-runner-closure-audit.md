# Shared Runner Closure Audit

## Purpose

This note closes the last broad shared-runner follow-up questions for the
current refactor scope:

- should the shared runner expand into approval-safe or provider-executed
  continuation soon
- should the streamed runner add a constrained pre-step hook soon

The goal is not to say these questions can never reopen.

The goal is to decide whether they should remain active migration debt right
now.

## Current Shared Runner Scope

The shared runner stack now already covers the intended narrow common subset:

- `GenerateTextRunner` for non-streaming multi-step orchestration
- `StreamTextRunner` / `streamTextRun(...)` for additive streamed
  multi-step orchestration
- explicit app-supplied execution for declared common function tools
- replay-safe step snapshots through `GenerateTextStepResult`
- small lifecycle callbacks through `GenerateTextStepStartEvent`,
  `onStepFinish`, and `onFinish`

The current implementation also already makes its limits explicit in code:

- tool approval continuation throws unsupported
- provider-executed tools throw unsupported
- dynamic tools throw unsupported
- undeclared tools throw
- missing executors stop honestly instead of pretending continuation exists

That means the current shared runner is already honest about what it owns.

## Why Shared Runner Expansion Is Not Ready

The promotion criteria for shared continuation still are not met.

The existing provider matrix shows that richer continuation remains materially
provider-shaped:

- OpenAI Responses has provider-owned approval and MCP continuation families
- Anthropic mixes request-side shared tools with provider-executed native
  result and replay families
- Google native tool circulation and mixed-tool policy remain provider-owned

Those families still differ on:

- approval semantics
- replay rules
- provider-native item/result payloads
- when continuation is model-gated or request-gated
- whether provider-owned side channels are required

That is not yet a replay-safe common continuation contract across two provider
families.

So the current TODO should not remain phrased like pending near-term work.

It should become a future policy rule:

- do not expand the shared runner until at least two provider families prove
  the same stable continuation contract without widening shared events, prompt
  models, or UI vocabularies

## Why A Constrained Pre-Step Hook Is Also Not Ready

The evidence for a shared pre-step hook is even weaker.

The current repository usage shows:

- `runTextGeneration(...)` and `streamTextRun(...)` are currently only used in
  focused core tests and workstream docs
- there are no current shared production call paths that repeatedly need
  per-step mutation above the existing request construction
- no existing app/runtime layer is rebuilding the same pre-step wrapper on top
  of both runner variants

So the “two concrete shared call paths” threshold is not met either.

Adding a constrained pre-step hook now would therefore freeze mutation surface
before real shared usage has proven:

- what actually needs to be mutable
- whether the need is runner-owned or app-owned
- whether the hook should only observe, or also narrow tools/options/prompt

That is exactly the kind of premature API expansion this refactor has been
trying to avoid.

## Closure Verdict

Both remaining runner follow-up items should now be considered closed for the
current refactor scope.

They are no longer active migration blockers.

They are future demand-driven policy questions.

## Reopen Thresholds

Shared runner expansion should reopen only if:

- at least two provider families prove the same replay-safe continuation
  contract
- that contract fits the current shared prompt/content/result models
- no provider-owned approval, storage, or admin side channel is required
- the shared event and UI vocabulary does not need widening

A constrained pre-step hook should reopen only if:

- at least two real shared call paths need the same per-step mutation or
  narrowing hook
- the hook can stay smaller than full `prepareStep`
- the need cannot be expressed cleanly in app-owned code around the runner

## TODO Consequence

The workstream should therefore:

- close the remaining shared-runner expansion TODO
- close the remaining constrained pre-step hook TODO
- keep both questions documented as future policy rather than active debt

## Bottom Line

The shared runner is now complete at the right scope for this refactor round.

It already covers the honest common function-tool loop, and it already stops
honestly when richer provider-native continuation would require a broader
contract.

That is a healthier architecture state than keeping speculative runner
expansion items open indefinitely.
