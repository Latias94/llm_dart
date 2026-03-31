# Main Text Call Result Layer

## Goal

This note records the next incremental step after `streamOutputResult(...)`
 landed:

> How should `llm_dart` expose a more productized main text-call result surface
> without redefining the low-level meaning of `generateText(...)` and
> `streamText(...)`?

## 1. Problem

After the previous structured-output slices, the repository already had:

- low-level single-step `generateText(...)`
- low-level single-step `streamText(...)`
- shared structured helpers such as `generateOutput(...)`
- streamed structured helpers such as `streamOutput(...)` and
  `streamOutputResult(...)`

That was already useful, but there was still a product gap:

- parsed output still lived behind dedicated helper names
- streaming still split into a raw stream helper versus a structured result
  helper
- there was still no one additive result layer that looked closer to the
  mature `repo-ref/ai` call surface

## 2. Decision

We should still not redefine the low-level helpers themselves.

That rule remains important:

- `generateText(...)` stays a thin helper around `LanguageModel.generate(...)`
- `streamText(...)` stays a thin helper around `LanguageModel.stream(...)`

Instead, the additive main-call layer is:

- `generateTextCall<T>(...)`
- `streamTextCall<T>(...)`

These sit above the low-level helpers and above the shared structured-output
 layer.

## 3. New Shared Surface

### 3.1 `GenerateTextCallResult<T>`

`generateTextCall(...)` returns a shared wrapper result with:

- the raw `GenerateTextResult` in `result`
- delegated common getters such as `text`, `reasoningText`, `usage`, and
  response metadata
- parsed `output` when `outputSpec` is provided

If `outputSpec` is omitted:

- the call still returns the shared wrapper
- no parsed output is exposed

### 3.2 `StreamTextCallResult<T>`

`streamTextCall(...)` returns a result object that is still directly iterable as
 `Stream<TextStreamEvent>`.

That means old usage patterns such as:

```dart
await for (final event in streamTextCall(...)) {
  ...
}
```

remain valid.

At the same time, the result now also exposes:

- `result`
- delegated futures such as `text`, `reasoningText`, and `usage`
- `partialOutputStream`
- `elementStream<TElement>()`
- `output`

when `outputSpec` is provided.

## 4. Why This Layer Is The Right Increment

### 4.1 It Moves Closer To The Reference Shape

The reference repository productizes result surfaces above the raw provider
 stream.

The new additive layer moves `llm_dart` in that direction without copying the
 TypeScript API literally.

### 4.2 It Keeps Low-Level Boundaries Honest

This change does not widen:

- `LanguageModel.generate(...)`
- `LanguageModel.stream(...)`
- `GenerateTextRequest`
- `TextStreamEvent`

Provider packages still only own provider I/O and decoding.

### 4.3 It Avoids A Premature Full Breaking Rename

We still do not need to decide yet whether:

- the additive call layer should permanently stay additive
- or later fold into `generateText(...)` / `streamText(...)`

That larger naming and migration decision can now be evaluated on top of a
 proven implementation.

## 5. Remaining Questions

After this slice, the remaining gap is narrower:

- should `generateTextCall(...)` and `streamTextCall(...)` eventually replace
  the old helper names
- or should the current low-level helpers remain public as the narrow raw layer
- should text output remain opt-in through `outputSpec`
- or should a later main-call API implicitly treat plain text as one output mode

These are now product-surface questions, not missing architecture foundation.

## Conclusion

The correct next step was not to overload `generateText(...)` and
`streamText(...)` immediately.

The correct next step was to add an additive main result layer:

- keep the low-level helpers honest
- expose a richer shared call surface through `generateTextCall(...)`
- expose a stream-compatible result object through `streamTextCall(...)`

This is a cleaner Dart-first bridge toward the mature `repo-ref/ai` shape.
