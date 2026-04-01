# Anthropic Legacy Parser Decomposition

## Goal

This note records the next provider-specific compatibility cleanup step:

- split `anthropic_legacy_extensions.dart` into focused same-library modules
- keep the audited raw-block parsing contract unchanged
- keep Anthropic compatibility bridge gating and replay behavior unchanged

This is a structure refactor, not a protocol expansion.

## 1. Why This Became The Next Best Target

After the root compatibility facades and the generic bridge shell were already
decomposed, the biggest remaining non-provider-package hotspot was the
Anthropic-specific legacy parser.

That file mixed four different concerns:

- legacy raw-block value models
- top-level legacy extension analysis
- individual raw-block parsers
- JSON normalization and validation helpers

This is exactly the sort of provider-owned compatibility logic that should stay
outside the shared compatibility shell, but it still benefits from clearer
internal boundaries.

## 2. Frozen Decomposition Rule

This slice keeps the existing Anthropic compatibility contract stable:

- no new raw block families are allowed
- no relaxed validation rules are introduced
- no bridge-safe subset expansion is implied
- no provider-specific parsing is moved back into shared compatibility files

The change is purely internal module decomposition.

## 3. Landed Split

The old file is now reduced to a shell plus same-library parts:

- `anthropic_legacy_extensions_models.dart`
- `anthropic_legacy_extensions_analyzer.dart`
- `anthropic_legacy_extensions_block_parsers.dart`
- `anthropic_legacy_extensions_utils.dart`

This maps to the actual ownership boundaries:

- the models file owns the value types and compatibility analysis snapshots
- the analyzer owns the top-level message and extension traversal
- the block parser file owns the raw Anthropic block-family parsing rules
- the utils file owns JSON-safe normalization and input validation helpers

## 4. Why Same-Library Parts Were Chosen

Using `part` files keeps this refactor low risk because it preserves:

- existing public entrypoints like `analyzeAnthropicLegacyMessageExtensions(...)`
- the current private helper topology
- zero migration cost for the Anthropic compatibility provider
- minimal risk of accidentally changing replay-safe parsing behavior

That is the right fit for a compatibility parser that is already heavily
covered by route and replay regression tests.

## 5. Validation

This slice was validated with:

- `dart analyze lib/src/compatibility test/chat_route_compatibility_test.dart test/legacy_compatibility_test.dart`
- `dart test test/chat_route_compatibility_test.dart test/legacy_compatibility_test.dart`

## 6. Next Step

After this provider-specific parser split, the remaining large compatibility or
root hotspots are now more conventional legacy model files such as audio,
assistant, image, file, and tool models, plus any future provider-owned bridge
coverage work that still needs to remain explicitly audited.
