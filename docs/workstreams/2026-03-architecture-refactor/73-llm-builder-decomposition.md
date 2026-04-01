# LLMBuilder Decomposition

## Goal

This note records the first internal decomposition slice for the legacy root
builder without changing the public `LLMBuilder` API.

The goal was narrow:

- keep all existing builder call sites stable
- reduce the amount of unrelated logic living in one file
- make the next root-package cleanup steps easier

## 1. Why `LLMBuilder` Needed A Split

Before this slice, `LLMBuilder` mixed:

- provider selection
- common request configuration
- HTTP extension plumbing
- web-search compatibility settings
- image/audio/STT compatibility settings
- typed capability build helpers

That made the file harder to audit than it needed to be, especially now that
provider wiring already moved into provider packages or compatibility slices.

## 2. Frozen Decomposition Rule

`LLMBuilder` should remain a compatibility-facing public facade, but its
implementation should be split by responsibility.

That means:

- keep `LLMBuilder` as the public type
- keep fluent call syntax unchanged
- move implementation groups into smaller same-library modules
- avoid inventing a new builder abstraction during the compatibility window

## 3. Landed Split

The main `llm_builder.dart` file is now reduced to the public library shell plus
the `LLMBuilder` state holder.

Implementation moved into same-library part files:

- `llm_builder_provider_selection.dart`
- `llm_builder_common_config.dart`
- `llm_builder_web_search.dart`
- `llm_builder_media_config.dart`
- `llm_builder_builds.dart`
- `llm_builder_internal.dart`

This keeps the external API stable while making ownership clearer.

## 4. What Stayed Out Of This Slice

This decomposition intentionally did not:

- change provider-specific convenience extensions
- redesign the legacy builder surface
- remove string-based extensions
- move root compatibility features into the new package-owned APIs

Those are broader cleanup questions and should stay separate from this file
decomposition pass.

## 5. Why Same-Library Parts Were Chosen

Using same-library parts keeps the refactor low risk because it preserves:

- direct method syntax on `LLMBuilder`
- access to existing private builder state
- compatibility with current provider-specific builder extensions
- minimal test churn

This is a better fit for the root compatibility layer than introducing another
public helper type or moving all builder methods into separate exported
extension-only libraries.

## 6. Next Step

After the compatibility provider bus file and `LLMBuilder` decomposition, the
next root cleanup should focus on:

- `capability.dart`
- `chat_models.dart`

Those files still represent the larger remaining root-facade coupling hotspot.
