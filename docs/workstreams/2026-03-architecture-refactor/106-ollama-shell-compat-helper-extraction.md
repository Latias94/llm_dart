# 106. Ollama Shell Compatibility Helper Extraction

## What Changed

The root `OllamaProvider` shell no longer keeps all compatibility glue inline in
`lib/providers/ollama/provider.dart`.

That file now delegates compatibility-specific shell setup to:

- `lib/src/compatibility/providers/ollama_compat_shell_support.dart`

The extracted support now owns:

- compatibility `LLMConfig` shaping for the root Ollama shell
- `LegacyChatCapabilityAdapter` construction for the bridged modern chat path
- bridged modern embedding-model ownership for the root shell
- chat-bridge gating rules for the current replay-safe subset

## Why This Matters

This does not change public API behavior.

It changes ownership shape.

Before this step, `lib/providers/ollama/provider.dart` mixed together:

- root compatibility shell orchestration
- modern community-model delegation
- compatibility config shaping
- compatibility bridge gating
- compatibility provider-option translation

After this step, the provider file is closer to what it should be:

- a root shell that wires together residual provider modules
- a root shell that delegates shared-capability modern paths
- not the place where compatibility glue logic keeps growing forever

## What Improved

The Ollama root shell now has less direct dependency on root-only compatibility
internals:

- it no longer directly imports `core/config.dart`
- it no longer directly imports `legacy_chat_adapter.dart`
- it no longer directly imports `legacy_config_keys.dart`

Those details now live behind the dedicated root compatibility support module.

## What Did Not Change

This extraction is intentionally narrow.

It does not:

- move `OllamaProvider` into `llm_dart_community`
- widen the shared modern surface
- change `/api/generate` completion ownership
- change model-listing ownership
- remove the root compatibility shell itself

## Remaining Work

The next remaining Ollama decoupling work is still larger than this one step:

- the residual root provider modules still exist
- the legacy factory/config adaptation path is still root-owned
- the root shell still implements compatibility interfaces directly

So this extraction should be read as shell-thinning progress, not as full
community-provider migration completion.
