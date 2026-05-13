# Provider Metadata Boundary Guard

Date: 2026-05-13
Status: implemented

## What Landed

Provider metadata is now guarded as response-side and replay-only data:

- provider input contracts cannot accept raw `ProviderMetadata`
- `CallOptions` continues to carry input-side provider customization through
  typed `ProviderInvocationOptions`
- prompt parts continue to carry input-side customization through typed
  `ProviderPromptPartOptions`
- replay metadata is explicit through `ProviderReplayPromptPartOptions`
- prompt JSON still rejects legacy `providerMetadata` fields and points callers
  to typed replay prompt options

The new guard scans the provider input contract files so `ProviderMetadata`
cannot silently return to ordinary request or prompt input surfaces.

## Why This Matters

`ProviderMetadata` describes provider observations from model outputs:
response identifiers, raw provider details, replay hints, and provider
continuation data. Treating it as a normal request customization bag would
re-couple input and output semantics and weaken typed provider options.

The intended shape is now explicit:

- user-authored provider behavior: typed provider options
- provider-observed output details: `ProviderMetadata`
- replay of prior provider observations: `ProviderReplayPromptPartOptions`

## Validation

- `dart test test/provider_stream_naming_guard_test.dart`

## Remaining Work

This guard locks the low-level contract. Release-facing docs should still
explain the rule with examples so users know when to use provider options
versus replay metadata.
