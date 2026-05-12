# Prompt Boundary Plan

## Problem

`ProviderMetadata` is documented as output-side provider-owned metadata, but
prompt input parts still expose `providerMetadata`. Some provider codecs use
that input metadata to build provider request bodies.

The highest-value fix is to make input-side customization explicit and keep
metadata output-side.

## Target Vocabulary

### Provider Options

Input-side provider customization.

Examples:

- Anthropic cache control
- Anthropic MCP or native tool controls
- OpenAI Responses request controls
- Google safety settings, cached content, and server-tool replay controls
- xAI live search settings

### Provider Metadata

Output-side provider observation and replay detail.

Examples:

- response IDs
- provider raw finish reasons
- usage-related raw details
- tool call replay metadata returned by the provider
- source or citation raw details
- UI inspection data after a model result

### Provider Reference

Input-side provider-native identity.

Examples:

- OpenAI file IDs
- Anthropic file IDs
- Google or Vertex file URIs

## Target Prompt Shape

The provider-facing prompt should eventually expose input-side part options,
not `ProviderMetadata`.

Implemented provider-level shape:

```dart
abstract interface class ProviderPromptPartOptions {
  const ProviderPromptPartOptions();
}
```

Provider-owned implementations can define typed options:

```dart
final class AnthropicPromptPartOptions implements ProviderPromptPartOptions {
  final AnthropicCacheControl? cacheControl;

  const AnthropicPromptPartOptions({
    this.cacheControl,
  });
}
```

This avoids raw maps as the primary path while leaving room for a controlled
escape hatch later if repeated need appears.

## Migration Strategy

### Phase 1 - Add Input-Side Part Options

- add provider part options types to `llm_dart_provider`
- add optional part options to prompt parts
- keep existing `providerMetadata` temporarily if source compatibility is
  required during the first migration step
- update serialization to round-trip the new shape

### Phase 2 - Move Provider Codecs

- Anthropic cache control reads `AnthropicTextPartOptions`
- Google server-tool replay reads provider-owned part options if request
  replay needs input controls
- OpenAI Responses reads provider-owned part options where request controls are
  required
- provider codecs only read `ProviderMetadata` for replay details that came
  from prior provider output

### Phase 3 - Deprecate Metadata Input

- mark prompt `providerMetadata` constructors and fields as deprecated where
  they are input-side
- update examples to use provider options
- add tests proving metadata is not accepted for new request controls

### Phase 4 - Remove Metadata Input In The Breaking Line

- remove `providerMetadata` from user-constructible prompt input shapes
- keep `ProviderMetadata` on output content, stream events, and result objects
- keep replay-oriented metadata only where the data came from a prior model
  response

## Anthropic Cache Control Migration

Old input shape:

```dart
TextPromptPart(
  'Remember this.',
  providerMetadata: ProviderMetadata.forNamespace(
    'anthropic',
    {
      'cacheControl': {'type': 'ephemeral'},
    },
  ),
);
```

Target shape:

```dart
TextPromptPart(
  'Remember this.',
  providerOptions: AnthropicPromptPartOptions(
    cacheControl: AnthropicCacheControl.ephemeral(),
  ),
);
```

The semantic boundary is the important part: cache control is input-side
provider configuration and must not be modeled as output metadata.

## Implemented Status

- `ProviderPromptPartOptions` now lives in `llm_dart_provider`.
- Prompt parts and tool-output content parts can carry `providerOptions`.
- `AnthropicPromptPartOptions` owns Anthropic per-part cache control.
- Anthropic request encoding reads cache control from `providerOptions`.
- Anthropic request encoding no longer reads cache control from
  `ProviderMetadata`.
- `OpenAIPromptPartOptions` owns OpenAI image `detail` request control for
  image prompt parts and image tool-output parts.
- OpenAI Responses and Chat Completions encoding no longer read image detail
  from `ProviderMetadata`; OpenAI replay IDs and encrypted reasoning metadata
  remain metadata because they originate from provider output.
- Google prompt metadata usage has been audited as replay-oriented
  `thoughtSignature`, `thought`, and `functionCallId` data rather than new
  request customization.
- Root Anthropic compatibility converts legacy cache markers into
  `AnthropicPromptPartOptions` before calling the modern provider codec.
- Prompt JSON serialization now preserves typed prompt part options through
  registered `ProviderPromptPartOptionsJsonCodec` instances. The default codec
  fails fast when unregistered `providerOptions` would otherwise be silently
  dropped.
- OpenAI and Anthropic expose provider-owned prompt part options JSON codecs
  for durable prompt serialization.

## Replay Semantics

Some provider output metadata must still be replayable in a future prompt.
That should be modeled explicitly:

- output content can carry `ProviderMetadata`
- runtime replay can convert output metadata into input options only through a
  provider-owned adapter
- provider codecs should not ask users to manually construct output metadata
  for request configuration

This keeps automated provider replay possible without teaching metadata as a
request API.

This workstream does not introduce a generic metadata-to-options adapter. That
adapter would blur output observations and input controls again. Provider
packages can add explicit replay adapters later when a provider needs to turn
its own prior output metadata into a new typed input option.

## User Prompt Layer Decision

This workstream leaves a user-facing `ModelMessage` shape as a follow-up.
The current breaking pass keeps provider-facing prompt contracts in
`llm_dart_provider`, keeps user-call helpers in `llm_dart_ai`, and closes the
metadata/options boundary first. A new user prompt abstraction should be added
only when it can replace root legacy message construction instead of becoming
another parallel surface.
