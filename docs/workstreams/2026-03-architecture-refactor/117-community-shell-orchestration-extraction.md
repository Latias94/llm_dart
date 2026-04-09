# 117. Community Shell Orchestration Extraction

## What Changed

The root compatibility providers for Ollama and ElevenLabs now push more of
their shell-only orchestration into dedicated compatibility support modules.

This means:

- `lib/providers/ollama/provider.dart`
  - no longer directly wires bridge helpers, fallback chat, completion, and
    model-listing modules inline
- `lib/providers/elevenlabs/provider.dart`
  - no longer directly wires bridge guards, fallback audio modules, and model
    helper modules inline

Instead, those root provider files now delegate more of that composition to:

- `lib/src/compatibility/providers/ollama_compat_shell_support.dart`
- `lib/src/compatibility/providers/elevenlabs_compat_shell_support.dart`

## Why This Matters

This is not the final closure of the community-provider decoupling work.

The builders, factories, root config shaping, and residual provider-only APIs
still exist.

But this extraction is still meaningful because it changes the ownership shape
of the root provider files:

- root provider shells now look more like explicit adapters
- compatibility-only orchestration sits closer to the compatibility layer
- the provider files stop acting as the place where compatibility modules are
  manually assembled one by one

That is a healthier intermediate state before any deeper move of implementation
weight.

## What Did Not Change

This slice does **not** claim that:

- `TODO 157` is fully closed
- Ollama or ElevenLabs are fully decoupled from root compatibility types
- residual completion, model-listing, voice/admin, or file-based flows moved
  into `llm_dart_community`

The current root shells still remain compatibility-era adapters.

## Practical Result

After this slice:

- compatibility bridge and fallback orchestration is more centralized
- the root provider shells are thinner in code ownership terms
- future shell cleanup can focus more clearly on the remaining root-owned
  config/factory and residual provider-shaped surfaces
