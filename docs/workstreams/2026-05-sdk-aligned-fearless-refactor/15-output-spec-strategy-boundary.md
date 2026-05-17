# Output Spec Strategy Boundary

Date: 2026-05-17

## Reference

This slice continues the alignment with `repo-ref/ai` object output strategy
layers, especially:

- `repo-ref/ai/packages/ai/src/generate-object/output-strategy.ts`
- `repo-ref/ai/packages/ai/src/generate-object/generate-object.ts`
- `repo-ref/ai/packages/ai/src/generate-object/stream-object.ts`
- `repo-ref/ai/packages/ai/src/generate-object/parse-and-validate-object-result.ts`

The reference keeps the strategy interface small while each output shape owns
its own response format, final parse, partial parse, and stream event behavior.
The Dart implementation keeps the public `OutputSpec` family intact while
moving each concrete strategy into an output-type-owned module.

## Problem

`packages/llm_dart_ai/lib/src/model/output_spec_strategy.dart` had become a
single module for several independent reasons to change:

- the public `OutputSpec<T>` strategy interface
- text output parsing
- schema-shaped JSON output parsing
- object output schema validation and parsing
- array output wrapping, partial element repair, and element event projection
- choice output option normalization, final parsing, and partial disambiguation

That made the strategy seam useful for callers but shallow for maintainers:
changing one output type required editing a file that also held the parse and
partial-stream rules for all other output types.

## Decision

Keep `output_spec_strategy.dart` as the compatibility facade and split concrete
strategies by output type:

- `output_spec_base.dart`
  - `OutputSpec<T>`
- `output_spec_text.dart`
  - `TextOutputSpec`
- `output_spec_json_strategy.dart`
  - `JsonOutputSpec<T>`
- `output_spec_object.dart`
  - `ObjectOutputSpec<T>`
- `output_spec_array.dart`
  - `ArrayOutputSpec<T>`
- `output_spec_choice.dart`
  - `ChoiceOutputSpec<T>`

This keeps public imports stable while giving each output type local ownership
of its response format, parse, partial parse, and stream event behavior.

## Behavior Contract

The refactor preserves these contracts:

- `OutputSpec`, `TextOutputSpec`, `JsonOutputSpec`, `ObjectOutputSpec`,
  `ArrayOutputSpec`, and `ChoiceOutputSpec` remain available through the same
  public exports.
- final parsing for text, JSON, object, array, and choice outputs is unchanged.
- partial parsing for text, JSON, object, array, and choice outputs is
  unchanged.
- array element stream events are still emitted only for newly completed
  decoded elements.
- object schema validation and choice option normalization keep the same error
  behavior.
- `generateOutput`, `streamOutput`, `generateObject`, and `streamObject` keep
  their existing behavior through the output runner facade.
- `llm_dart_core` compatibility exports continue to resolve the same output
  spec names.

## Benefits

Locality improves because each output type now owns the implementation details
that change together.

Leverage improves because the public strategy facade remains a small interface
for callers, while future output-type changes can land in one focused adapter
instead of a shared file that mixes every strategy.

This leaves future work to decide whether `output_spec_json.dart` and
`output_spec_foundation.dart` should be split further into schema validation,
JSON repair, and parse diagnostic modules. That should wait until another
behavioral change proves the next seam.
