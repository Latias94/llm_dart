# ADR-0002: Provider-Native Features Stay Provider-Owned

Status: Accepted
Date: 2026-05-27

## Context

Providers expose native features that do not share identical semantics:
OpenAI-family Responses tools, Anthropic beta features, Google GenerateContent
parts, Ollama local options, and ElevenLabs speech/transcription controls.
Copying mature SDK layering too literally would flatten these differences into
premature shared abstractions.

## Decision

Provider-native features stay provider-owned. Shared Modules may define stable
contracts, capability descriptions, invocation controls, and test-only fixture
helpers, but provider-native wire behavior remains in the provider package.

## Consequences

- Provider option codecs and native tool projections are maintained close to
  provider code.
- Shared app Interfaces remain smaller and more stable.
- New shared provider utilities require repeated adapters and a deletion-test
  win before they become public.
