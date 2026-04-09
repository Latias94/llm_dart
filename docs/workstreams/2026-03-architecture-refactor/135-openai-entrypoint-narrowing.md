# 135. OpenAI Entrypoint Narrowing

## What Changed

The provider-focused OpenAI barrel now exports a narrower surface:

- `lib/providers/openai/openai.dart` keeps:
  - `OpenAIConfig`
  - `OpenAIProvider`
  - `OpenAIBuilder`
  - the raw OpenAI Responses residual API surface
  - the built-in tool DSL
  - the legacy constructor helpers such as `createOpenAIProvider(...)`
- it no longer re-exports internal legacy implementation modules such as:
  - `client.dart`
  - `chat.dart`
  - `embeddings.dart`
  - `audio.dart`
  - `images.dart`
  - `files.dart`
  - `models.dart`
  - `moderation.dart`
  - `assistants.dart`
  - `completion.dart`

Compatibility-oriented broad exports move to `lib/legacy.dart` instead.

## Why This Matters

After the OpenAI shell and module relocations, the public barrel was still too
wide.

That created the wrong default signal:

- the implementation already lives under `src/compatibility`
- but the main OpenAI barrel still looked like a catch-all import for internal
  legacy modules

That is not the boundary we want to teach or preserve.

The useful rule is the same one already applied to Google:

- provider-focused barrels expose construction and typed public API shapes
- explicit compatibility breadth lives on `legacy.dart`
- internal compatibility modules remain importable by path, but are no longer
  the default provider surface

## Why Some OpenAI Residual APIs Still Stay On The Barrel

This narrowing is intentionally not as aggressive as a pure modern-provider
barrel.

The OpenAI compatibility story still has a few public residual surfaces that
are meaningfully user-facing:

- `OpenAIBuilder`
- `OpenAIBuiltInTools`
- `OpenAIResponsesCapability`
- `OpenAIResponses`
- `buildOpenAIResponses()` and `provider.responses`

Those are still compatibility-oriented, but they are explicit public residual
APIs rather than just internal implementation files.

So this cut keeps them visible while removing the modules that are clearly
implementation-hosting detail.

## Boundary Result

After this change:

- `package:llm_dart/providers/openai/openai.dart` is a narrower provider entry
- `package:llm_dart/legacy.dart` remains the broad compatibility shell
- users who intentionally need internal legacy OpenAI modules can still import
  those files directly

## Practical Result

OpenAI now follows the same structural direction already used by the other
major migrated provider families:

- modern package-owned OpenAI usage stays on `package:llm_dart/openai.dart`
- compatibility breadth stays explicit on `package:llm_dart/legacy.dart`
- the provider-focused compatibility barrel is no longer a disguised internal
  module dump
