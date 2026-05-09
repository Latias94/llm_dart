# 116. Provider Root Entrypoint Narrowing

## Question

Should provider-focused root entrypoints such as:

- `package:llm_dart/openai.dart`
- `package:llm_dart/google.dart`
- `package:llm_dart/anthropic.dart`

continue re-exporting:

- `AI`
- `core.dart`
- `transport.dart`

or should they narrow down to provider-owned package surfaces only?

## Conclusion

They should narrow down.

The recommended stable rule is:

- `package:llm_dart/ai.dart` or `package:llm_dart/llm_dart.dart`
  - owns the app-facing `AI` facade
- `package:llm_dart/core.dart`
  - owns shared prompt/result/tool/output types and helper functions
- `package:llm_dart/transport.dart`
  - owns shared transport types
- `package:llm_dart/openai.dart`
  - owns OpenAI-family provider types only
- `package:llm_dart/google.dart`
  - owns Google provider types only
- `package:llm_dart/anthropic.dart`
  - owns Anthropic provider types only

So provider-focused root entrypoints should stop re-exporting unrelated modern
shells.

## Why

## 1. Their Current Export Graph Is Broader Than Their Names

Today, each of these provider-focused root entrypoints exports:

- the provider package barrel
- `core.dart`
- `transport.dart`
- `AI`

That makes imports such as `package:llm_dart/openai.dart` look narrower than
they really are.

In practice, the import name says “provider-owned OpenAI surface”, but the
actual export graph also smuggles in:

- shared core helpers
- shared transport types
- the root cross-provider facade

That weakens boundary signaling.

## 2. Repository Usage Is Already Mostly Split Correctly

Current examples and docs already mostly follow the healthier split:

- import `package:llm_dart/ai.dart` for `AI`
- import `package:llm_dart/core.dart` for shared helpers and types
- import `package:llm_dart/openai.dart` or similar for provider-owned options

That matters because it means narrowing these entrypoints now is not fighting
the current modern usage style.

The remaining in-repo dependency on provider-entrypoint `AI` exposure is now
minor enough to clean up directly.

## 3. This Better Matches `repo-ref/ai`

The useful reference rule is again ownership clarity:

- provider package entrypoints expose provider-owned constructors, models, and
  provider-specific types
- they do not also re-export the whole app-facing facade or shared utility
  entrypoints under the same provider import

Our Dart packaging is intentionally different, but the same ownership signal is
useful here:

- provider entrypoints should feel provider-owned
- the app-facing `AI` facade should feel root-owned

## 4. This Helps The Remaining Root Cleanup

The repository still has two remaining structural cleanup themes:

- reducing root compatibility/provider-hosting weight
- keeping the export graph honest while the migration window stays open

Narrowing provider root entrypoints helps both:

- import intent becomes clearer
- provider namespaces stop acting like alternate portals to the full modern
  root surface
- the next export-graph cleanup no longer needs to guess whether a provider
  shell is supposed to be “focused” or “broad”

## 5. `chat.dart` Remains The Intentional Convenience Exception

This narrowing rule should not be generalized blindly to every focused
entrypoint.

`package:llm_dart/chat.dart` is intentionally different:

- it is an app-facing convenience shell
- it exists specifically to combine chat runtime, core, transport, and the
  short stable model factories into one pure-Dart chat entrypoint

That convenience boundary is explicit and still useful.

The provider entrypoints do not have the same justification.

2026-05 update: the later focused-entrypoint cleanup narrowed this exception
too. `chat.dart` still combines the pure Dart chat runtime with core,
transport, and short factories such as `openai(...)`, but it no longer exports
the grouped `AI` namespace. Import `package:llm_dart/llm_dart.dart` or
`package:llm_dart/ai.dart` when a codebase explicitly wants
`AI.<provider>(...)`.

## What Should Change

The stable entrypoint guidance should become:

- if you want `AI`, import `ai.dart` or `llm_dart.dart`
- if you want shared helper/types, import `core.dart`
- if you want transport abstractions, import `transport.dart`
- if you want provider-owned types/options, import the corresponding provider
  entrypoint

That keeps import intent legible.

## What Should Not Happen

Do not:

- keep provider entrypoints broad just for convenience symmetry
- move provider-owned option types back into the root facade so imports look
  shorter
- re-add `AI`, `core.dart`, or `transport.dart` to provider entrypoints after
  narrowing them

## Impact On The Workstream

This closes the provider-root-entrypoint question more explicitly:

- provider-focused root entrypoints should now be genuinely provider-focused
- the app-facing `AI` facade remains on `ai.dart` / `llm_dart.dart`
- shared helper layers remain on `core.dart` and `transport.dart`
- `chat.dart` stays the intentional convenience exception
