# 123. Google Entrypoint Narrowing

## What Changed

The provider-focused Google barrel now exports a narrower surface:

- `lib/providers/google/google.dart` keeps the legacy provider constructor
  helpers plus the public `GoogleConfig`, `GoogleProvider`, and
  `GoogleLLMBuilder`
- it no longer re-exports internal legacy implementation modules such as:
  - `client.dart`
  - `chat.dart`
  - `embeddings.dart`

Compatibility-oriented broad exports move to `lib/legacy.dart` instead.

## Why This Matters

This aligns the repository more closely with the reference structure in
`repo-ref/ai` and with the package-owned modern Google surface:

- provider entrypoints should primarily expose provider construction and typed
  public API shapes
- internal transport/client/capability modules should not look like the default
  user-facing surface
- broad compatibility exports belong on the explicit compatibility entrypoint,
  not the provider-focused barrel

## Boundary Result

After this change:

- `package:llm_dart/providers/google/google.dart` is a narrower provider entry
- `package:llm_dart/legacy.dart` remains the compatibility-oriented broad root
  surface
- tests or migration code that intentionally target internal Google legacy
  modules should import those files directly or use `legacy.dart`

## Why This Is A Better Fit Than Copying Package Count

This change borrows a useful structural lesson from `repo-ref/ai` without
copying its publication strategy mechanically:

- keep the provider entry focused
- keep compatibility broadness explicit
- keep internal modules importable when needed, but not as the default provider
  barrel
