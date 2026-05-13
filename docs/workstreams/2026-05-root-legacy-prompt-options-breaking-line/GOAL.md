# Goal

## Canonical Goal Text

Complete the next intentional breaking architecture line for `llm_dart` by
removing the remaining root-package legacy implementation ownership, making
`llm_dart_ai` the clear app-facing prompt and runtime surface, and tightening
provider input customization so request-side provider behavior flows through
typed provider options instead of output metadata.

This breaking line should leave the package graph intact unless concrete
implementation evidence proves a new boundary is necessary. The root package
must become a thin modern facade plus documented migration notes, not a second
implementation home. `llm_dart_ai` must own user-facing `ModelMessage`
ergonomics, prompt normalization, prompt validation, text/object generation,
tool-loop orchestration, structured-output result facades, and UI projection.
`llm_dart_provider` must own only provider-facing model contracts and
wire-neutral normalized request/result structures. Provider packages must keep
their typed options, capability profiles, native helper clients, replay codecs,
and product-specific features without depending on runtime, chat, Flutter,
root, or legacy compatibility code.

The work is complete only when root legacy implementation code is deleted or
relocated behind an explicit migration vehicle, ordinary prompt inputs no
longer carry `ProviderMetadata`, provider replay uses explicit typed replay
options, the structured text/object result surface has one documented
long-term direction, guards prevent boundary regressions, and migration docs,
examples, tests, consumer smoke, and publish dry-runs prove the breaking line.

## Completion Definition

This goal is complete only when:

- root `llm_dart` no longer owns provider, builder, model, or compatibility
  implementation code beyond explicitly documented migration hooks
- default user-facing examples and docs use `llm_dart_ai` prompt/runtime
  helpers and focused provider packages
- provider-facing `PromptMessage` remains an advanced/implementation contract,
  not the common app-facing prompt shape
- ordinary request-side prompt parts and tool output parts do not expose
  `ProviderMetadata`
- provider replay metadata is carried only through explicit typed replay
  options or provider-owned replay helpers
- typed provider options remain discoverable while leaving a documented raw
  escape hatch for provider-specific features
- structured output, object generation, and text-call result facades have one
  documented migration direction
- provider packages remain free of runtime, chat, Flutter, root, and legacy
  dependencies in production code
- guards, package tests, root tests, Flutter tests where affected, migration
  docs, examples, consumer smoke, and publish dry-runs pass for the new line
