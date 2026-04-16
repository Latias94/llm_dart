# `createProvider(...)` Posture

## Goal

Decide whether `createProvider(...)` should itself become soft-deprecated, or
whether only the raw `extensions` escape hatch should stay on the deprecation
path.

## Decision

`createProvider(...)` should remain a **frozen generic compatibility helper**
for now.

Only:

```dart
createProvider(..., extensions: ...)
```

should continue to be treated as the soft-deprecated escape hatch.

## Why The Function Should Stay Frozen

### 1. It Still Covers One Real Compatibility Job

`createProvider(...)` is the only simple public helper that can still express:

- runtime-selected `providerId`
- generic compatibility config
- builder-free creation for old root-package callers

That is not the same problem as the provider-specific stable facade.

### 2. Its Honest Replacement Is Not One Short Stable Recipe

When the provider is known at compile time, the repository has clear
replacements:

- `AI.<provider>(...)`
- provider-owned root constructors such as `createOpenAIProvider(...)`
- `LLMBuilder()` for explicit compatibility builder code

But when provider choice is runtime-driven, there is no equally short shared
stable replacement yet.

That means the function itself does **not** meet the repository rule for new
deprecation: "clear enough to explain in one short migration note".

### 3. It Matches The Explicit `legacy.dart` Boundary

The repository already decided that `legacy.dart` is the compatibility home for
builder-era and generic root helpers.

Keeping `createProvider(...)` frozen inside that boundary is consistent.

### 4. The Problem Is The Raw Extension Bag, Not The Generic Helper

The architectural concern is not that a generic helper exists.

The concern is that this parameter reintroduces provider-owned semantics through
raw string keys:

```dart
extensions: <String, dynamic>{...}
```

That is exactly the part that should keep shrinking.

## What Should Stay Soft-Deprecated

The following remains on the deprecation track:

- `createProvider(..., extensions: ...)`

Because it:

- hides provider-native semantics in an untyped map
- encourages string-key coupling
- weakens the migration pressure toward provider-owned typed APIs

## Recommended Replacement Patterns

### 1. Provider Known At Compile Time

Prefer the stable facade:

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
```

or the explicit compatibility/provider root when needed:

```dart
final provider = createOpenAIProvider(
  apiKey: apiKey,
  model: 'gpt-4.1-mini',
);
```

### 2. Still On The Compatibility Builder Surface

Prefer the explicit builder over the raw extension bag:

```dart
final provider = await LLMBuilder()
    .provider(providerId)
    .apiKey(apiKey)
    .model(model)
    .build();
```

### 3. Provider-Specific Extras Are Required

Do **not** route them through generic raw extensions if a typed surface exists.

Instead, branch earlier into the provider-owned API:

- `OpenAIGenerateTextOptions(...)`
- `AnthropicGenerateTextOptions(...)`
- `XAIGenerateTextOptions(...)`
- provider-owned builder callbacks where the compatibility layer still owns a
  documented migration path

## Practical Outcome

The repository should now treat the surface as two separate things:

| Surface | Posture |
| --- | --- |
| `createProvider(...)` | Frozen compatibility helper |
| `createProvider(..., extensions: ...)` | Soft-deprecated raw escape hatch |

That distinction matters.

Without it, the repository risks deprecating one of the last honest generic
compatibility helpers before a real replacement exists.

## Revisit Conditions

Only revisit deprecating the function itself if at least one of the following
becomes true:

1. a public typed dynamic-provider factory exists
2. config-driven provider selection has a documented stable root pattern
3. real user demand for the helper is low enough that its maintenance cost
   exceeds its migration value
