# Long-Tail OpenAI-Compatible Closure Audit

## Purpose

This note closes the remaining active TODOs for the long-tail
OpenAI-compatible providers:

- whether Phind should gain a dedicated migrated path or bridge-safe subset
- whether OpenRouter search should broaden beyond the audited online-model
  subset
- whether xAI compatibility should broaden beyond the audited live-search
  subset

The goal is not to claim these providers will never grow.

The goal is to decide whether those questions still belong to active migration
debt right now.

## Current State

The current state is already much clearer than the old TODO surface suggests.

### OpenRouter

The repository already has:

- a package-owned `OpenRouterProfile`
- a stable online-model shaping contract
- audited compatibility routing for the plain chat subset
- audited compatibility routing for online-intent migration inputs that only
  preserve online-model shaping behavior

What it does **not** have is evidence for a broader stable request contract
behind legacy helpers such as:

- `searchPrompt`
- `maxSearchResults`
- `useOnlineShortcut`

### xAI

The repository already has:

- a package-owned `XAIProfile`
- typed live-search invocation options
- exact `search_parameters` encoding
- shared citation projection
- audited compatibility routing for the current live-search migration subset

What it does **not** have is evidence for a broader stable compatibility target
beyond that audited subset, especially around:

- prompt-side tool replay
- multimodal compatibility routing
- future xAI provider-defined search tools

### Phind

The repository already has:

- a facade constructor path through `PhindProfile`

But it still does **not** have:

- a validated bridge-safe legacy subset
- an audited proof that the legacy protocol is equivalent to the new
  OpenAI-family path
- a reason to assume the old provider belongs on the OpenAI-compatible bridge
  at all

## Why These Items No Longer Need To Stay Open

These providers are now in a healthier architecture state:

- the modern path exists where it is honest
- the bridge-safe subset exists where it is audited
- the rest already falls back conservatively

That means the remaining questions are no longer "missing migration pieces" in
the structural sense.

They are product- and contract-driven follow-ups.

## Provider-by-Provider Closure Verdict

### OpenRouter

The audited online-model subset is enough for the current workstream.

Broader search mapping should not remain active migration debt until the
repository has evidence for a real stable OpenRouter request contract beyond
model shaping.

### xAI

The audited live-search subset is enough for the current workstream.

Broader xAI expansion should not remain active migration debt until a concrete
provider-owned contract appears for the next subset.

### Phind

Phind should stay facade-only and legacy-fallback for now.

It should not remain active migration debt until the repository first proves
that a real migrated path is both possible and worth it.

## Reopen Thresholds

OpenRouter should reopen only if:

- a broader stable search wire contract is proven and tested
- the contract is more than online-model shaping
- the resulting API can stay provider-owned and honest

xAI should reopen only if:

- a concrete next subset is identified and audited
- that subset has a stable provider-owned contract
- broadening the compatibility bridge would still stay narrower than the old
  legacy surface

Phind should reopen only if:

- the current real Phind endpoint and protocol are re-audited
- the migrated path is shown to be semantically meaningful
- a bridge-safe subset or dedicated provider-owned path is justified by actual
  product need

## TODO Consequence

The workstream should therefore:

- close the Phind migration-path TODO as active migration debt
- close the broader OpenRouter/xAI expansion TODO as active migration debt
- keep all three as future provider-owned policy questions only

## Bottom Line

The long-tail OpenAI-compatible providers are now aligned enough for this
refactor round:

- OpenRouter has the audited online subset
- xAI has the audited live-search subset
- Phind remains an honest facade-only fallback case

That is a better stopping point than keeping speculative expansion items open
without a stronger provider contract.
