# 206 OpenAI Audio Facade Thinning

## Why This Slice Exists

After the recent OpenAI compatibility chat and Responses thinning passes, the
remaining `lib/src/compatibility/providers/openai/audio.dart` file still mixed
several unrelated responsibilities:

- text-to-speech request shaping
- transcription and translation multipart request construction
- transcription and translation response mapping
- static voice, format, and language catalogs
- unsupported-feature declarations

That made the file larger than necessary and blurred the difference between
static provider catalogs, request/response support, and the actual capability
facade.

## What Changed

This slice keeps the public `OpenAIAudio` surface stable while splitting the
remaining ownership into focused helpers:

- `audio.dart`
  - thin capability facade and unsupported-feature declarations
- `openai_audio_support.dart`
  - request shaping and response mapping for TTS, STT, and translation
- `openai_audio_catalog.dart`
  - static voices, formats, and language catalogs

The public compatibility import path remains unchanged:

- `package:llm_dart/providers/openai/audio.dart`

## Why This Is Better

- keeps multipart request construction out of the facade body
- isolates response mapping from endpoint orchestration
- removes large static catalogs from the execution path
- preserves the stable compatibility-facing API
- makes future OpenAI audio maintenance less error-prone and easier to test

## Boundary Decision

This is still a **compatibility-shell cleanup**, not a new provider-package
audio API.

The goal is only to keep the root OpenAI compatibility audio surface honest
while it still exists.

## Why This Matches The Reference Direction

The useful lesson from `repo-ref/ai` is ownership:

- static provider catalogs should not stay mixed with request execution
- request shaping should not stay mixed with facade methods
- response mapping should not stay mixed with everything else

The Dart root compatibility layer remains intentionally simpler than the
reference repository. The point is clearer local ownership, not structural
parity.

## Validation

This slice is validated with:

- `dart analyze lib/src/compatibility/providers/openai/audio.dart lib/src/compatibility/providers/openai/openai_audio_catalog.dart lib/src/compatibility/providers/openai/openai_audio_support.dart test/providers/openai/openai_audio_support_test.dart test/providers/openai/openai_config_layering_test.dart`
- `dart test test/providers/openai/openai_audio_support_test.dart test/providers/openai/openai_config_layering_test.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
- `dart run tool/check_workspace_dependency_guards.dart`

## Follow-Up

After this slice, the next worthwhile hotspots are no longer the obvious
OpenAI-family mixed hosts that were just thinned. The next step is more likely
one of these:

- re-audit `lib/src/compatibility/providers/openai/provider_compat.dart` for
  any remaining non-delegation convenience helpers worth isolating
- re-audit `lib/src/compatibility/providers/anthropic/request_builder.dart`
  and only split it if a future change proves a real sub-boundary instead of
  cutting it merely because it is long

The same rule still applies: only cut where ownership is actually mixed.
