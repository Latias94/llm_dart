# OpenAI Family Policy Hub Split

## Why This Workstream Exists

`llm_dart_openai` still concentrates typed option resolution, compatibility
bag parsing, and profile-specific OpenAI-family policy in one large internal
module. The largest file in that path,
`lib/src/provider/openai_provider_options_bag.dart`, is over 1,100 lines and
currently owns generate-text, embedding, image, speech, transcription, and
profile-specific compatibility helpers.

That shape still works, but it makes the OpenAI package harder to extend and
audit. The next useful refactor is to split this policy hub into smaller
provider-local modules while preserving typed options, OpenAI-compatible
profile behavior, and the public facade.

## Goal

Deliver a smaller, more honest OpenAI-family policy boundary:

- feature-local modules own their option parsing and encoding
- common resolver policy is separated from bag compatibility
- `ProviderOptionsBag` becomes compatibility-only unless a documented public
  posture says otherwise
- existing typed option behavior and profile-specific rejection rules remain
  stable

## Reference Lessons From `repo-ref/ai`

- provider-specific option policy is easier to evolve when the common resolver
  is small
- compatibility shims should not remain the semantic center
- provider-local helpers are preferable to a single hub when the file starts
  owning multiple feature families
- public behavior should stay stable while implementation ownership moves
  inward

## What To Preserve

- typed provider options
- OpenAI-family profile routing and profile-specific rejection
- existing request and response behavior for language, embedding, image,
  speech, and transcription
- the public `llm_dart_openai` facade
- provider-native features and custom parts

## Scope

- split the generate-text option compatibility path out of the monolith first
- extract the remaining feature-specific bag helpers into smaller modules
- separate common OpenAI family resolver policy from compatibility parsing
- decide the public export posture for `ProviderOptionsBag`
- update tests and docs for any boundary change

## Non-Goals

- change the public runtime API shape
- remove OpenAI-family profiles
- flatten provider-native options into weak shared options
- publish new packages
- widen compatibility beyond the current OpenAI family surface

## Success Criteria

- no single OpenAI options file remains the semantic center
- compatibility helpers are clearly isolated from provider policy
- resolver tests prove typed overrides and profile-specific behavior still work
- package analysis and dependency guards stay green
- docs explain whether `ProviderOptionsBag` is public compatibility or
  internal support

