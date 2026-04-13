# 184 Community Compatibility Ownership Localization

## Why This Slice Exists

After the recent community-provider audit, one smaller but still meaningful
ownership smell remained inside the root compatibility layer:

- `community_provider_config_adapters.dart` mixed truly shared transport
  projection with provider-specific Ollama and ElevenLabs config adaptation
- the Ollama and ElevenLabs shell-support files still lived in the mixed
  `providers/` directory root instead of their provider-owned compatibility
  directories

That did not break behavior, but it did blur ownership again right where the
refactor is trying to make it clearer.

## What Changed

### 1. Shared community adapter support is now truly shared only

`community_provider_config_adapters.dart` now owns only:

- `createLegacyDioClientOverrides(...)`

That file is now limited to the cross-provider legacy-to-transport projection
that both community providers actually share.

### 2. Provider-specific config adaptation moved back to provider-owned paths

The legacy config adapters now live beside their provider-specific
compatibility code:

- `lib/src/compatibility/providers/ollama/config_adapter.dart`
- `lib/src/compatibility/providers/elevenlabs/config_adapter.dart`

These files now own:

- `createLegacyOllamaConfig(...)`
- `createLegacyElevenLabsConfig(...)`

### 3. Provider-specific shell support now lives inside provider-owned folders

The shell-support modules moved from the mixed compatibility-provider root into
their provider directories:

- `lib/src/compatibility/providers/ollama/shell_support.dart`
- `lib/src/compatibility/providers/elevenlabs/shell_support.dart`

This keeps:

- Ollama chat/completion/model-listing bridge orchestration with Ollama
  compatibility files
- ElevenLabs speech/transcription bridge orchestration with ElevenLabs
  compatibility files

## Why This Is Better

### 1. It removes another small shared "adapter bus"

The old layout encouraged one shared file to keep accumulating provider-shaped
logic just because the providers happened to be grouped under the temporary
`community` umbrella.

That is exactly the pattern the broader refactor is trying to avoid.

### 2. It keeps provider-owned compatibility logic provider-owned

Even inside the root compatibility layer, provider-specific adaptation should
still live under the provider that owns it.

That makes it easier to answer:

- what is truly shared
- what is only Ollama-specific
- what is only ElevenLabs-specific

### 3. It makes the next community thinning rounds safer

Future work can now thin or delete provider-specific compatibility modules
without touching one mixed cross-provider adapter file unless the change is
actually shared.

That is a better staging shape for the later Ollama and ElevenLabs migration
rounds.

## Non-Goals

This slice does **not**:

- finish community-provider migration
- move legacy capability interfaces into `llm_dart_community`
- change legacy public exports
- widen any shared modern core contract

It is a boundary-localization step, not the final community migration step.

## Conclusion

The root compatibility layer now treats community-provider adaptation more
honestly:

- shared transport override projection stays shared
- provider-specific config adaptation stays provider-owned
- provider-specific shell support stays provider-owned

This is a small change, but it keeps the remaining community migration work
moving in the right ownership direction instead of recreating another mixed
helper cluster.
