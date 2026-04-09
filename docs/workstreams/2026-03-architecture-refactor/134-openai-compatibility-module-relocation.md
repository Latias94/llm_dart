# 134. OpenAI Compatibility Module Relocation

## What Changed

The remaining root-hosted OpenAI legacy implementation modules moved under
explicit compatibility ownership:

- `lib/src/compatibility/providers/openai/client.dart`
- `lib/src/compatibility/providers/openai/dio_strategy.dart`
- `lib/src/compatibility/providers/openai/chat.dart`
- `lib/src/compatibility/providers/openai/embeddings.dart`
- `lib/src/compatibility/providers/openai/audio.dart`
- `lib/src/compatibility/providers/openai/images.dart`
- `lib/src/compatibility/providers/openai/files.dart`
- `lib/src/compatibility/providers/openai/models.dart`
- `lib/src/compatibility/providers/openai/moderation.dart`
- `lib/src/compatibility/providers/openai/assistants.dart`
- `lib/src/compatibility/providers/openai/completion.dart`
- `lib/src/compatibility/providers/openai/responses.dart`
- `lib/src/compatibility/providers/openai/responses_capability.dart`

The old public paths under `lib/providers/openai/` now act as compatibility
re-exports.

## Why This Matters

The OpenAI shell relocation fixed the top-level ownership signal, but the real
HTTP and capability implementation weight was still visibly spread across the
public provider directory.

That left the same mixed message that Google and Anthropic had before their
second thinning slice:

- the public OpenAI provider shell looked compatibility-oriented
- but the actual client, request handling, Responses path, and legacy
  capability modules still looked like first-class root implementation homes

Moving those modules under `src/compatibility` makes the architecture more
honest:

- the root package is still a real OpenAI legacy host for now
- but that host role is explicitly a compatibility concern
- the package-owned modern mainline remains `llm_dart_openai`

## Boundary Effect

After this move:

- old imports continue to work through re-exports
- internal compatibility code can depend on compatibility-owned OpenAI modules
  directly
- the remaining OpenAI root host role is easier to inventory and thin in later
  slices

This now aligns OpenAI with the same structural pattern already applied to
Google and Anthropic.

## What Did Not Move

This relocation intentionally leaves a few public compatibility-facing files in
place:

- `lib/providers/openai/config.dart`
- `lib/providers/openai/builtin_tools.dart`
- `lib/providers/openai/builder.dart`
- `lib/providers/openai/openai.dart`

Those files still carry public compatibility data-model or entrypoint
responsibilities, so moving them is a separate decision from moving the real
implementation host.

## What This Move Does Not Solve

This relocation still does not:

- migrate OpenAI residual APIs such as moderation, assistants, files, model
  listing, or Responses lifecycle management into `llm_dart_openai`
- decide whether any of those residual APIs deserve new provider-owned modern
  helpers
- remove root `dio`, `logging`, or compatibility-era HTTP/error pressure
- eliminate the remaining compatibility builder/config surface

Those remain separate follow-up slices.

## Practical Result

OpenAI now matches the same structural direction already used by the other
major migrated provider families:

- public root paths stay stable as migration-era compatibility shells
- real legacy implementation ownership moves under `src/compatibility`
- deeper provider thinning can continue later without pretending the public
  provider directory is still the long-term implementation home

## Verification

- `dart analyze`
- `dart test test/providers/openai test/legacy_compatibility_test.dart test/compat_transport_test.dart test/utils/dio/dio_client_factory_test.dart`
