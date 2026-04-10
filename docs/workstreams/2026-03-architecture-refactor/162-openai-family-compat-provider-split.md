# 162 OpenAI Family Compat Provider Split

## Goal

Reduce the remaining mixed-ownership hotspot in
`lib/src/compatibility/providers/openai_family_compat_provider.dart` without
changing the legacy compatibility surface.

The target is not "fewer lines at any cost." The target is a clearer internal
shape:

1. a thin family barrel,
2. provider/profile-specific builder slices,
3. a small support module for the few still-shared legacy-shaping helpers.

## Problem

Before this split, one file mixed all of the following:

- OpenAI compatibility builder and wrapper,
- DeepSeek compatibility builder and wrapper,
- OpenRouter compatibility builder and wrapper,
- Groq compatibility builder and wrapper,
- xAI compatibility builder and wrapper,
- OpenAI/OpenRouter legacy config shaping,
- OpenRouter search-model settings shaping,
- xAI live-search compatibility shaping.

That was no longer acting like a shell. It was acting like a family-level
implementation host.

## Decision

Keep `openai_family_compat_provider.dart` as a **thin barrel** and move the
real ownership into focused slices:

- `openai_family_compat_openai.dart`
- `openai_family_compat_deepseek.dart`
- `openai_family_compat_openrouter.dart`
- `openai_family_compat_groq.dart`
- `openai_family_compat_xai.dart`
- `openai_family_compat_support.dart`

The public-internal symbols stay stable:

- `buildCompatOpenAIProvider`
- `buildCompatDeepSeekProvider`
- `buildCompatOpenRouterProvider`
- `buildCompatGroqProvider`
- `buildCompatXAIProvider`
- `CompatOpenAIProvider`
- `CompatDeepSeekProvider`
- `CompatOpenRouterProvider`
- `CompatGroqProvider`
- `CompatXAIProvider`

That means the compatibility resolver, tests, and legacy surface do not need to
change just to get the structural cleanup.

## Why This Split Is Worth It

This split improves the architecture in three ways.

### 1. Provider ownership becomes explicit

Each provider/profile now owns its own builder and compat wrapper. A future
OpenRouter-only change or xAI-only compatibility expansion no longer has to
reopen a shared bus file that also hosts four other providers.

### 2. Shared support stays deliberately narrow

The new support module contains only the truly shared helper logic that still
belongs to this family-level migration layer:

- OpenAI legacy config shaping,
- OpenRouter legacy config shaping,
- OpenRouter online-model settings shaping,
- xAI live-search option normalization and mapping.

This avoids inventing a new generic repository-wide compatibility base class.

### 3. The shell shape aligns better with the refactor direction

The internal OpenAI-family compatibility layout now reads more like:

- request encoding / parsing helpers under provider-local modules,
- provider-local compat wrappers,
- family-level export barrel.

That is materially closer to the intended "thin shell over focused helpers"
direction already established in the earlier OpenAI shell-thinning rounds.

## Non-Goals

This split does **not**:

- remove the legacy compatibility wrappers,
- change bridge gating behavior,
- change fallback semantics,
- introduce a new shared compat-provider inheritance framework,
- widen the shared core abstraction surface.

The change is structural, not behavioral.

## Result

The remaining OpenAI-family compatibility shell is now easier to reason about:

- the barrel is thin,
- provider-specific changes have a natural home,
- the still-shared helper logic is explicit and bounded,
- the legacy migration surface remains intact while implementation weight keeps
  moving downward.

## Follow-Up

After this split, the next highest-value provider-shell cleanup candidate is
still `anthropic_compat_provider.dart`, but only if new work keeps increasing
its mixed ownership instead of letting it stabilize as provider-local adapter
code.
