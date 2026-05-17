# Output Foundation JSON Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` structured output support
layers, especially:

- `repo-ref/ai/packages/ai/src/generate-object/output-strategy.ts`
- `repo-ref/ai/packages/ai/src/generate-object/parse-and-validate-object-result.ts`
- `repo-ref/ai/packages/ai/src/generate-object/stream-object.ts`
- `repo-ref/ai/packages/ai/src/generate-object/stream-object-result.ts`

The reference keeps parsing, validation, stream event shape, and result facade
concepts separate. The Dart implementation keeps the existing public facades
while moving the underlying support types and JSON helpers into focused
modules.

## Problem

Two support modules had become shallow accumulation points:

- `output_spec_foundation.dart`
  - decoder typedefs
  - structured output parse context
  - generated output result facade
  - stream event union
- `output_spec_json.dart`
  - JSON text decoding
  - object coercion
  - JSON value freezing and equality
  - object schema validation
  - choice option normalization
  - usage diagnostics JSON projection

Each group changes for a different reason. Keeping them in two mixed files made
future output changes harder to review because type surface changes, parse
helper changes, validation changes, and diagnostic changes looked related even
when they were not.

## Decision

Keep the two existing files as compatibility facades and split implementation
ownership:

- `output_decoder_types.dart`
  - `JsonOutputDecoder<T>`, `JsonObjectDecoder<T>`, and
    `JsonArrayElementDecoder<T>`
- `output_context.dart`
  - `StructuredOutputContext`
- `output_result.dart`
  - `GenerateOutputResult<T>` and `GenerateObjectResult<T>`
- `output_stream_event.dart`
  - output stream event types
- `output_json_text.dart`
  - structured output JSON text decoding
- `output_json_object.dart`
  - JSON object coercion helpers
- `output_json_value.dart`
  - JSON value freezing and deep equality
- `output_schema_validation.dart`
  - object schema validation and choice option normalization
- `output_usage_diagnostics.dart`
  - usage metadata diagnostic projection

This keeps public and internal import compatibility while making each support
module deeper and easier to change independently.

## Behavior Contract

The refactor preserves these contracts:

- `output_spec_foundation.dart` still exports decoder typedefs,
  `StructuredOutputContext`, generated output results, and output stream
  events.
- `output_spec_json.dart` still exports the same structured output JSON helper
  functions.
- public `llm_dart_ai` output spec exports remain unchanged.
- `llm_dart_core` compatibility exports continue to resolve the same names.
- JSON parse error messages, object coercion behavior, immutable partial JSON
  values, duplicate partial suppression, object schema validation, choice
  option normalization, and validation diagnostics are unchanged.
- `generateOutput`, `streamOutput`, `generateObject`, `streamObject`, and
  `streamOutputResult` behavior remains unchanged.

## Benefits

Locality improves because changes to result/event types, decoder typedefs,
JSON text parsing, JSON object coercion, JSON value equality, schema
validation, and diagnostics now have separate modules.

Leverage improves because the public facades remain small stable seams, while
future behavior changes can be made in the module that owns the reason to
change.

The next likely structured output seam is not another split inside these files;
it is provider adapter mapping for response formats and provider-native
structured output capabilities.
