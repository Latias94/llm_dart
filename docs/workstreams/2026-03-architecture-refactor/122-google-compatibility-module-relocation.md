# 122. Google Compatibility Module Relocation

## What Changed

The remaining root-hosted Google legacy implementation modules moved under
explicit compatibility ownership:

- `lib/src/compatibility/providers/google/client.dart`
- `lib/src/compatibility/providers/google/dio_strategy.dart`
- `lib/src/compatibility/providers/google/chat.dart`
- `lib/src/compatibility/providers/google/embeddings.dart`
- `lib/src/compatibility/providers/google/images.dart`
- `lib/src/compatibility/providers/google/tts.dart`

The old public paths under `lib/providers/google/` now act as compatibility
re-exports.

## Why This Matters

The previous Google shell relocation made the root provider entrypoint
compatibility-owned, but the real HTTP implementation weight was still visibly
spread across the public provider directory.

That left an awkward mixed message:

- the public provider shell looked compatibility-oriented
- but the actual legacy HTTP client and capability modules still looked like
  first-class root implementation homes

Moving these modules under `src/compatibility` makes the architecture more
honest:

- the root package is still a real Google legacy host for now
- but that host role is explicitly a compatibility concern
- the package-owned modern mainline remains `llm_dart_google`

## Boundary Effect

After this move:

- old imports continue to work through re-exports
- internal compatibility code can depend on compatibility-owned Google modules
  directly
- the remaining Google root host role is easier to inventory and shrink in
  follow-up slices

## What This Move Does Not Solve

This relocation still does not:

- remove root `dio` or `logging` dependencies
- migrate the Google legacy HTTP client out of the root package
- remove duplicated capability families between root Google code and
  `llm_dart_google`
- narrow the broad legacy Google barrel export surface yet

Those remain separate follow-up decisions.

## Practical Result

Google now matches the current direction used elsewhere in the refactor:

- public root paths stay stable as migration-era shells
- real compatibility implementation ownership moves under `src/compatibility`
- deeper provider thinning can happen later without pretending the public
  provider directory is still the long-term implementation home
