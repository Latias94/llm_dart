# OpenAI Family Policy Hub Split - Handoff

Status: Closed
Last updated: 2026-05-23

## Current State

The repository is on `refactor/architecture-foundation` and now contains the
new OpenAI family policy hub split workstream in addition to the earlier
architecture and release lanes.

The next live hotspot is the OpenAI family policy hub:

- `packages/llm_dart_openai/lib/src/provider/openai_provider_options_bag.dart`
  was 1107 lines and publicly exported before this lane; it is now reduced to
  a library facade plus shared JSON parsing helpers
- `packages/llm_dart_openai/lib/src/provider/openai_family_common_option_resolver.dart`
  still delegates into that compatibility module
- typed options and profile-specific rejection rules are already covered by
  tests, so the next refactor should preserve behavior while moving ownership
  into smaller modules

Completed slices:

- moved generate-text and OpenAI-family typed option compatibility helpers into
  `packages/llm_dart_openai/lib/src/provider/openai_provider_options_bag_generate_text.dart`
- moved embedding, image, speech, and transcription option compatibility
  helpers into
  `packages/llm_dart_openai/lib/src/provider/openai_provider_options_bag_non_text.dart`
- added
  `packages/llm_dart_openai/lib/src/provider/openai_family_invocation_options.dart`
  as the resolver-facing invocation option seam
- documented `openai_provider_options_bag.dart` as the public compatibility
  bridge for existing `ProviderOptionsBag` callers, with typed option classes
  as the preferred path for new code
- kept the public `llm_dart_openai` facade unchanged
- validated the split with focused OpenAI tests, package analysis, workspace
  dependency guard, root boundary guard, and `git diff --check`

## Follow-On

Review whether the remaining public helper functions in
`openai_provider_options_bag_generate_text.dart` should be deprecated in a
later breaking line, or kept as long-term compatibility encode/decode helpers.
This is not a blocker for the current policy-hub split.

## Notes

- Keep `ProviderOptionsBag` behavior stable until the new boundary is in place.
- Do not widen the package graph or introduce a new package yet.
