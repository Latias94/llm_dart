# Example Compatibility Audit

## Scope

This audit closes the M6 check for non-migration example usage of legacy and
compatibility APIs.

## Result

Default examples are stable-first. `tool/check_example_api_guards.dart` rejects
these compatibility surfaces outside explicitly allowlisted appendix files:

- `package:llm_dart/legacy.dart`
- `package:llm_dart/builder/...`
- `package:llm_dart/providers/...`
- `package:llm_dart/models/...`
- `package:llm_dart/core/...` subpaths
- `LLMBuilder()`
- the removed `ai()` helper
- grouped `llm.AI` facade usage in examples

The remaining allowlisted files are documented as provider-owned or
compatibility appendices:

| Example | Reason |
| --- | --- |
| `example/02_core_features/assistants.dart` | OpenAI assistant lifecycle remains a provider-owned compatibility boundary. |
| `example/02_core_features/cancellation_demo.dart` | Model listing cancellation remains on a provider-owned compatibility boundary. |
| `example/02_core_features/capability_detection.dart` | Registry metadata still uses the compatibility provider registry while stable model execution is shown separately. |
| `example/02_core_features/capability_factory_methods.dart` | Documents typed `build*()` migration helpers for the legacy builder. |
| `example/02_core_features/model_listing.dart` | Remote catalog listing remains provider-owned compatibility material. |
| `example/02_core_features/provider_specific_builders.dart` | Documents provider callback migration helpers for the legacy builder. |
| `example/03_advanced_features/realtime_audio.dart` | Realtime audio remains a provider-owned ElevenLabs compatibility appendix. |
| `example/04_providers/elevenlabs/audio_capabilities.dart` | Streaming and realtime audio remain on the ElevenLabs compatibility shell. |
| `example/04_providers/google/google_tts_example.dart` | Streamed PCM output and voice discovery remain Google compatibility appendices. |
| `example/04_providers/openai/build_openai_responses_demo.dart` | Raw OpenAI response lifecycle APIs remain compatibility material. |
| `example/04_providers/openai/responses_api.dart` | Raw OpenAI response lifecycle APIs remain compatibility material. |

## Documentation Cleanup

The example README now keeps compatibility-only builder examples out of the
default core-feature list and presents them as migration-only appendices.

`example/02_core_features/README.md` also separates normal core-feature run
commands from compatibility appendix run commands.

## Policy

New examples should not be added to the compatibility allowlist unless they
cover a provider-owned lifecycle API, a migration-only builder workflow, or a
documented residual capability that does not yet have a stable model-first
surface.
