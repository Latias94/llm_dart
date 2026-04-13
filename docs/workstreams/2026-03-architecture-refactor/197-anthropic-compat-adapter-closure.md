# Anthropic Compatibility Adapter Closure

## Purpose

This note closes the remaining Anthropic adapter follow-up item.

The question is not whether the Anthropic compatibility adapter is small.

The real question is:

- does the current Anthropic compatibility adapter still represent active
  refactor debt
- or is it now a provider-local compatibility file that should only split again
  under concrete pressure

## Current State

The recent shell split already landed the important structural move:

- the Anthropic compatibility entry is now a thinner shell
- the heavy compatibility conversion logic lives in one explicit
  provider-local adapter

That adapter still owns one coherent concern:

- Anthropic-specific replay-safe legacy block analysis and prompt conversion

It is not a family-level bus file.

It is not evidence that the repository needs a generic compatibility framework.

## Why Another Split Is Not Worth Keeping Open

The remaining adapter weight is mostly legitimate provider-local complexity:

- role-aware block conversion
- cache metadata handling
- native tool replay payload shaping
- custom replay payload handling

Splitting that further now would likely create one of two bad outcomes:

- tiny helper files created only for symmetry
- a generic compatibility abstraction that hides provider-specific replay rules

Neither is a worthwhile current migration target.

## Closure Verdict

This TODO should now close.

The Anthropic compatibility adapter is no longer active migration debt.

It is a future provider-local cleanup question only.

## Reopen Threshold

The adapter should reopen only if one of these becomes true:

- a new provider-local subdomain becomes large enough to deserve its own file
- the adapter starts mixing request shaping, replay conversion, and UI/helper
  concerns in one place
- a concrete product need proves that one subsection is reused on more than one
  Anthropic-owned path

Absent that, more splitting would mostly be symmetry-driven churn.

## TODO Consequence

The workstream should therefore:

- close the remaining Anthropic compatibility-adapter TODO
- keep any later split as future provider-local cleanup only

## Bottom Line

The current Anthropic compatibility shape is already the right amount of split:

- thin shell
- one explicit provider-local adapter
- no new generic compatibility framework
