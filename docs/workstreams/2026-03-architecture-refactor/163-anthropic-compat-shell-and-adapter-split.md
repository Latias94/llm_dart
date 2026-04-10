# 163 Anthropic Compat Shell And Adapter Split

## Goal

Re-evaluate whether `lib/src/compatibility/providers/anthropic_compat_provider.dart`
should receive the same kind of shell cleanup as the recent OpenAI-family
compatibility builder split.

The answer is: **yes, but only partially**.

Anthropic still benefits from a thinner shell, but its remaining weight is not
the same kind of mixed family-level ownership that previously justified the
OpenAI-family split.

## Key Difference From The OpenAI-Family Case

The old OpenAI-family file mixed several provider routes in one place:

- OpenAI
- OpenRouter
- DeepSeek
- Groq
- xAI

That was a family-level bus-file smell.

The Anthropic file had a different problem. Most of its remaining size came
from one provider-local concern:

- replay-safe legacy block analysis and prompt conversion

That is real Anthropic-specific compatibility logic, not accidental
cross-provider mixing.

## Decision

Split the file into:

- `anthropic_compat_provider.dart` as a thin barrel
- `anthropic_compat_shell.dart` for:
  - `buildCompatAnthropicProvider`
  - `CompatAnthropicProvider`
  - builder-time Anthropic option shaping
- `anthropic_compat_adapter.dart` for:
  - `AnthropicLegacyChatCapabilityAdapter`
  - role-aware legacy block conversion
  - tool-result replay naming and cache metadata helpers

## What This Split Intentionally Does Not Do

This split does **not** try to atomize Anthropic replay logic into many tiny
files or invent a generic compatibility-adapter framework.

That would not improve the real architecture much, because the heavy part here
is still one coherent provider-local translation boundary.

So the new shape is:

- thin shell,
- explicit adapter,
- provider-local replay logic kept together.

## Why This Is The Right Amount Of Refactor

### 1. The shell becomes honest again

The entry file and shell file now read like compatibility routing and builder
wiring, instead of also hosting the full replay conversion implementation.

### 2. Provider-local conversion remains coherent

The Anthropic replay path still needs to reason about:

- raw legacy content blocks,
- cache metadata,
- tool-use descriptors,
- custom replay payloads,
- role-aware prompt projection.

Keeping that together inside one adapter file is easier to review and safer to
change than scattering it into generic helper layers.

### 3. The refactor stays aligned with the migration policy

The compatibility layer remains explicit, while real implementation weight keeps
moving downward or into provider-local helpers where that helps clarity.

This is consistent with the frozen legacy-retention policy: keep the surface,
shrink the shell weight, and avoid accidental new abstraction frameworks.

## Result

Anthropic compatibility now has a clearer internal shape without pretending that
its replay converter is just boilerplate shell code.

This makes a future Anthropic-only compatibility adjustment less likely to
re-bloat the shell file while still respecting the fact that Anthropic replay
conversion is legitimate provider-local complexity.

## Follow-Up

Do **not** schedule another Anthropic split just because the adapter file is
still non-trivial.

Only reopen that adapter if one of these becomes true:

1. a new provider-local subdomain grows large enough to deserve a dedicated
   helper file, such as execution replay or cache/tool policy reconciliation,
2. the adapter starts mixing request shaping, replay conversion, and UI helper
   concerns in the same file,
3. a concrete product need proves that one subsection has become reusable on
   more than one Anthropic-owned path.
