# Shared Structured Output Boundary

## Goal

This note answers the next concrete architecture question after the
`repo-ref/ai` gap review:

> How should `llm_dart` close the remaining structured-generation gap without
> copying a TypeScript-specific API shape blindly?

This matters because “structured output support exists somewhere” is not the
same thing as “structured generation is a stable shared capability”.

## 1. Reference Signal From `repo-ref/ai`

The most important recent signal from the reference repository is easy to miss:

- `generateObject` and `streamObject` still exist
- but they are now marked as deprecated
- the preferred direction is `generateText` / `streamText` with an `output`
  specification

That means the mature lesson is not “add a separate object API forever”.

The mature lesson is:

- shared structured generation should live above provider-specific
  `responseFormat`
- the shared boundary should own parsing and validation
- the same output contract should be reusable by both non-streaming and
  streaming text generation

In the reference implementation, the real center of gravity is the output
strategy layer:

- build provider-facing `responseFormat`
- parse final output
- parse partial output
- optionally emit element streams for arrays

That is the structural idea worth borrowing.

## 2. Current `llm_dart` State

Current status in the refactor branch:

- `LanguageModel` and `generateText` already exist as shared text-generation
  entry points
- `OutputSpec`, `generateOutput(...)`, and `streamOutput(...)` now exist as a
  shared structured-output layer above those text helpers
- OpenAI and Google already expose provider-owned JSON-schema
  `responseFormat` request shaping
- structured output is therefore no longer only provider-owned, but the shared
  layer is still intentionally narrower than a full `streamObject` contract

What is still missing in shared core:

- no shared parsed-output field on `GenerateTextResult`
- no shared partial structured output model for `streamText`
- no shared element-streaming model for array-like outputs
- no shared migration path from old compatibility `jsonSchema` inputs into the
  new primary API

In other words, the capability exists on the wire, but not yet as a stable
cross-provider contract.

## 3. Dart-Specific Constraints

We should not copy the reference API literally because Dart has different
tradeoffs.

### 3.1 Do Not Force A Specific Schema Library Into Core

TypeScript can lean on schema libraries that also drive type inference.

`llm_dart_core` should not depend on one specific Dart schema or validation
package just to imitate that experience.

The shared boundary should remain:

- JSON-safe
- serializable
- independent from code generation
- usable from Flutter, CLI, and backend Dart

### 3.2 Request Shaping And Final Decoding Must Stay Separate

For Dart, the cleanest shared contract is usually:

- one value for provider-facing schema guidance
- one decoder or validator for final typed conversion

Those two concerns often overlap, but they are not identical.

### 3.3 Do Not Lie About Provider Support

The shared output contract must not pretend that every provider supports the
same structured-generation semantics.

Shared output should mean:

- providers may encode a shared `responseFormat`
- providers may reject unsupported output modes explicitly
- provider-native structured-generation systems that do not map honestly should
  stay provider-owned

## 4. Why Provider-Owned `responseFormat` Alone Is Not Enough

The current provider-owned shape is too low-level to become the long-term
architecture endpoint.

Problems with the current state:

- app code must branch on provider package types
- there is no one shared parsed-object result path
- there is no common streaming story
- validation failures remain app-owned or provider-owned instead of
  architecture-owned
- Flutter and server applications cannot build one stable structured-generation
  integration against the new primary API

That means the current provider-owned `responseFormat` types are a useful
implementation slice, but not the final shared API shape.

## 5. Design Options

## A. Keep Structured Output Provider-Owned Only

### Pros

- minimal new shared surface
- no new generics in `generateText`
- providers stay maximally independent

### Cons

- preserves one of the clearest remaining structure gaps versus the reference
- keeps structured generation as an escape hatch instead of a first-class
  capability
- produces poor cross-provider DX
- makes Flutter/server abstractions weaker than they need to be

Verdict:

- not recommended as the long-term target

## B. Add Dedicated `generateObject` / `streamObject` APIs

### Pros

- additive and easy to explain
- keeps today’s `generateText` signatures simpler
- can land without immediately widening all text result types

### Cons

- duplicates the text-generation pipeline structurally
- is already no longer the preferred direction in the reference repository
- risks creating two parallel futures: text APIs and structured APIs

Verdict:

- acceptable only as a temporary migration wrapper, not as the target

## C. Add A Shared Output Specification To `generateText` / `streamText`

### Pros

- aligns with the latest reference direction, not the older surface
- keeps one core generation pipeline
- lets text and structured output share retry, transport, lifecycle, and
  provider selection behavior
- gives Dart one honest extension point for future output modes

### Cons

- requires a more careful shared core design
- likely requires generic or side-channel parsed output fields on text results
- needs a Dart-first schema and decoder story

Verdict:

- recommended target architecture

## 6. Recommended Shared Boundary

The recommended design is:

- do not standardize permanent standalone `generateObject` APIs as the end
  state
- add a shared output-specification layer on top of `generateText` and
  `streamText`
- allow temporary wrapper helpers later if migration ergonomics require them

## 6.1 Recommended Core Concepts

### 1. Shared Output Specification

Use one shared concept such as:

```dart
abstract interface class OutputSpec<T, PartialT, ElementT> {
  Future<ResponseFormat?> responseFormat();

  Future<T> parseComplete({
    required String text,
    required StructuredOutputContext context,
  });

  Future<PartialT?> parsePartial({
    required String text,
  });

  StreamTransformer<PartialT, ElementT>? createElementTransformer();
}
```

This keeps the architecture clear:

- provider-facing request guidance
- final parse and validation
- optional partial parsing
- optional element streaming

### 2. Shared Response-Format Value

Do not let provider packages define the shared request shape indirectly.

Introduce a provider-neutral response-format value in core, for example:

```dart
sealed class ResponseFormat {
  const ResponseFormat();
}

final class TextResponseFormat extends ResponseFormat {
  const TextResponseFormat();
}

final class JsonResponseFormat extends ResponseFormat {
  final Map<String, Object?>? schema;
  final String? name;
  final String? description;

  const JsonResponseFormat({
    this.schema,
    this.name,
    this.description,
  });
}
```

Provider packages then map this shared value into their wire-specific request
shapes.

### 3. Shared Structured Output Context

Final decoding needs context for good error reporting.

Recommended minimum context:

- `responseId`
- `responseTimestamp`
- `responseModelId`
- `finishReason`
- `rawFinishReason`
- `usage`
- `providerMetadata`

This lets structured-output failures stay integrated with the shared result and
error model.

## 6.2 Recommended Built-In Output Modes

The first shared output modes should stay small:

- `text`
- `json`
- `object`
- `array`

Possible later mode:

- `choice` or enum-like output

Do not start with every clever variation.

The first job is to close the core architecture gap honestly.

## 6.3 Recommended Dart Schema Strategy

Do not copy the reference repository’s schema strategy directly.

For Dart, the shared output mode should use:

- JSON Schema for provider request shaping
- app-supplied decoding or validation for final typed conversion

That suggests a shape closer to:

```dart
final class ObjectOutputSpec<T> implements OutputSpec<T, Object?, Never> {
  final Map<String, Object?> schema;
  final T Function(Object? json) decode;
  final String? name;
  final String? description;

  const ObjectOutputSpec({
    required this.schema,
    required this.decode,
    this.name,
    this.description,
  });
}
```

Why this is better for Dart:

- no hard dependency on one schema library
- works with manual decoding, `json_serializable`, `freezed`, or custom codecs
- keeps the shared core neutral

## 6.4 Shared JSON Schema Utility Should Be Extracted

`ToolJsonSchema` is too tool-specific to become the shared foundation for
structured output unchanged.

Why:

- tool input schemas are intentionally constrained to an object root
- structured output may need object, array-wrapper, enum-wrapper, or generic
  JSON modes

Recommended direction:

- extract a general JSON-schema utility or value type in `llm_dart_core`
- keep `ToolJsonSchema` as the constrained function-tool wrapper above it
- let structured output reuse the general JSON-schema layer instead of
  reusing `ToolJsonSchema` directly

## 7. Recommended Result Placement

The cleanest long-term target is:

- `generateText` keeps returning the existing text-oriented result surface
- when `output` is configured, the result also exposes parsed output

That can be additive through a field such as:

```dart
final class GenerateTextResult<TOutput> {
  final List<ContentPart> content;
  final TOutput? output;
  ...
}
```

Or, if we want to avoid a large generic migration immediately:

- keep the base `GenerateTextResult`
- add a typed wrapper result for the output-enabled helpers

The important architecture rule is:

- parsed structured output should be shared-result data, not provider-owned
  metadata

## 8. Streaming Recommendation

Do not make the first structured-output step a full clone of the reference
streaming object layer.

Recommended order:

### Phase 1

- final parsed structured output for non-streaming `generateText`
- a shared streaming helper that forwards raw `TextStreamEvent`s and emits one
  final parsed-output event at the end
- no partial structured streaming yet

### Phase 2

- add `streamText` partial structured output only for the output modes that can
  be supported honestly
- start with `json` and `object`
- only add array element streaming if real users need it

This keeps the shared boundary honest while still moving toward the mature
reference direction.

## 9. Provider Support Recommendation

The first shared structured-output path should target only the providers that
already have a truthful shared request path:

- OpenAI family
- Google

Anthropic should only join the shared structured-output path later if it can do
so honestly without provider-shaped hacks.

If a provider cannot support a shared output mode:

- fail explicitly
- or emit a warning and reject the call path

Do not silently drop the output contract.

## 10. Migration Recommendation

Use a staged migration.

### Step 1

- introduce the shared response-format and output-spec concepts in core
- keep provider-owned `responseFormat` options working as temporary lower-level
  escape hatches

### Step 2

- map OpenAI and Google provider codecs from the shared response-format value
- add shared final-output parsing in the common layer

### Step 3

- add compatibility mapping from old `jsonSchema`-style legacy inputs into the
  new shared output spec

### Step 4

- decide later whether a small `generateObject(...)` wrapper is still useful as
  migration sugar

## Conclusion

The right way to close the remaining structured-generation gap is not to freeze
provider-owned `responseFormat` as the permanent endpoint, and not to copy an
older standalone `generateObject` surface literally.

The better direction for `llm_dart` is:

- shared output specification in core
- shared response-format value in core
- JSON Schema for provider guidance
- app-supplied decoding for Dart-friendly typed conversion
- phased streaming support later

That gives us a Dart-first architecture that still learns the right lesson from
the latest `repo-ref/ai` design.
