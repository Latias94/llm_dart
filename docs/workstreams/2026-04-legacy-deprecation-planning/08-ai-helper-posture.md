# `ai()` Helper Posture

## Goal

Decide whether the legacy `ai()` helper should remain a frozen compatibility
host or move into soft deprecation now that the migration recipe set exists.

## Decision

`ai()` should now be treated as **soft-deprecated**.

This is a leaf alias, not a compatibility trunk.

The compatibility trunk that remains frozen is `LLMBuilder()`, not `ai()`.

## Why `ai()` Is Now Ready

### 1. It Is Only A Thin Alias

`ai()` is just:

```dart
LLMBuilder ai() => LLMBuilder();
```

It does not own separate behavior, routing, or provider semantics.

That means deprecating it does **not** remove the actual builder migration
rail.

### 2. The Modern Shared Replacement Story Now Exists

The repository now has documented task-oriented migration recipes for:

- text generation
- streaming
- tool runs
- embeddings
- image generation
- audio
- model listing
- raw OpenAI Responses flows

That is enough to stop treating `ai()` as required migration infrastructure for
new or newly-touched app-facing code.

### 3. The Compatibility Replacement Also Exists

For users who still need the compatibility builder surface, the honest
replacement is:

```dart
LLMBuilder()
```

not another alias layer.

This preserves the builder trunk while shrinking one unnecessary convenience
leaf.

### 4. The Name Now Conflicts With The Modern Direction

The modern primary facade is:

```dart
AI.<provider>(...)
```

Keeping `ai()` as an equally prominent non-deprecated symbol makes the root
story harder to teach:

- `AI` means modern stable model-centric facade
- `ai()` means legacy compatibility builder alias

Soft-deprecating `ai()` makes that distinction clearer without deleting the
builder system.

### 5. Repository Usage Is Now Low Enough

After the example and test sweep:

- the explicit compatibility appendix examples now use `LLMBuilder()`
- direct executable `ai()` usage is no longer needed in `example/`
- the repository keeps only compatibility disclosure and one explicit legacy
  export test around `ai()`

That is the right moment to deprecate a leaf alias.

## What Does **Not** Change

This decision does **not** mean:

- deprecate `LLMBuilder`
- remove `legacy.dart`
- remove builder capability methods such as `buildAudio()` or
  `buildModelListing()`
- force old compatibility users to jump directly to the stable `AI` facade

Those broader compatibility questions remain separate.

## Recommended Replacement

### For New App-Facing Code

Use the stable facade:

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
```

### For Compatibility Builder Code

Use the explicit builder directly:

```dart
final provider = await LLMBuilder()
    .openai()
    .apiKey(apiKey)
    .model('gpt-4.1-mini')
    .build();
```

## Implementation Consequence

The repository should now:

- annotate `ai()` as deprecated
- move all first-party executable code to `LLMBuilder()`
- keep `legacy.dart` as the explicit compatibility import
- keep `LLMBuilder` itself frozen, not deprecated

## Removal Timing

`ai()` should not be removed immediately.

Recommended posture:

- soft-deprecate now
- keep it through at least one explicit migration cycle
- review removal only after the already-prepared leaf-removal wave lands cleanly

That keeps the sequence conservative:

1. deprecate the alias
2. keep the real builder trunk
3. revisit actual removal later
