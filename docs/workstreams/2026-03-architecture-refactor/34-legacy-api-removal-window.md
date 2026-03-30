# Legacy API Removal Window

## Goal

This note freezes the removal window for the old root-package compatibility surface.

The repository is still mid-migration, but callers now need a predictable answer to this question:

> When can deprecated root-package compatibility APIs actually disappear?

## 1. Scope

This policy covers the old root-package compatibility surface, including:

- `ai()` and the legacy builder-centric provider flow
- legacy provider subclasses returned by `LLMBuilder.build()`
- deprecated preset helpers on top of those legacy providers
- the old `ChatCapability` / `ChatStreamEvent` compatibility APIs

It does **not** mean every one of those APIs is deprecated today.

It means they now share one removal policy.

## 2. Frozen Removal Window

The old root-package compatibility surface should not be removed before `1.0.0`.

That means:

- deprecations may be added during the `0.x` line
- migration docs may keep getting stricter during the `0.x` line
- examples and new docs should move to the `AI` facade during the `0.x` line
- but the actual removal of deprecated compatibility APIs should wait until the first `1.0.0` breaking release at the earliest

## 3. Preconditions For Removal

Even at `1.0.0`, removal should happen only after the repository has all of the following:

1. a published migration guide for the old root-package surface
2. rewritten minimal examples that use the stable primary API
3. stable package-owned replacements for the specific deprecated entrypoints being removed
4. release notes that explicitly list the removed compatibility APIs

If those conditions are not ready, the deprecated compatibility APIs should stay longer.

## 4. What Callers Should Expect During `0.x`

During the remaining `0.x` line:

- deprecated preset helpers should keep working
- compatibility routing may still improve internally
- unsupported legacy request shapes may still fall back to old provider implementations
- new stable examples should stop teaching deprecated compatibility helpers

In other words:

- `0.x` is for migration pressure
- `1.0.0` is the earliest removal point

## 5. Why This Window Is Conservative

The repository is still migrating several important areas:

- OpenAI non-chat endpoints
- Google non-chat coverage
- Anthropic broader provider-native features
- community-provider strategy
- Flutter example cleanup
- migration-guide publishing

Removing old compatibility APIs earlier would force users off the old surface before the new architecture covers enough of the real repository use cases.

That would create churn, not clarity.

## 6. Current Conclusion

The repository now has a frozen compatibility removal policy:

- add deprecations now when a real stable replacement exists
- keep the deprecated compatibility APIs alive through the `0.x` line
- remove them no earlier than `1.0.0`, and only with migration documentation in place
