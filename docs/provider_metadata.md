# Provider Metadata Conventions

`providerMetadata` is the escape hatch for provider-specific fields that are not
part of the standardized surface.

This repository follows a Vercel AI SDK–style namespacing convention:

- Providers emit a single stable canonical namespace key (usually the base
  provider family id, such as `openai`, `azure`, `anthropic`, `google`, `vertex`).

Canonicalization policy:

- **Downstream code should read via `readProviderMetadata(providerMetadata, providerId)`.**
- `readProviderMetadata` supports namespaced provider ids (e.g. `openai.chat`,
  `xai.responses`) and legacy alias keys if they appear in recorded fixtures.

See:

- ADP 0009: `docs/adp/0009-provider-metadata-canonicalization.md`

## Recommended usage (downstream)

Prefer reading the canonical key:

```dart
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

final meta = response.providerMetadata;
final openai = readProviderMetadata<Map<String, dynamic>>(meta, 'openai');
```

`readProviderMetadata` prefers a base provider key when present and falls back
to capability keys (and single-entry maps) when needed.

Namespaced provider ids (e.g. `xai.responses`) are also supported. Always pass
the provider instance id you used, and let the helper handle base vs alias keys:

```dart
final xaiResponses =
    readProviderMetadata<Map<String, dynamic>>(meta, 'xai.responses');
```

Exception note:

- During the fearless refactor window, some providers may emit additional keys
  for parity or migration. Prefer the helper for stable access.

## Recommended Payload Shape

Minimal, capability-agnostic payload:

```json
{
  "model": "model-id",
  "endpoint": "relative-or-full-endpoint"
}
```

Additional fields are provider-specific and should remain stable once shipped.

## Examples

OpenAI speech (TTS):

```json
{
  "openai": { "model": "tts-1", "endpoint": "audio/speech" }
}
```

OpenAI-compatible chat (e.g. DeepSeek via Chat Completions):

```json
{
  "deepseek": { "id": "chatcmpl_123", "model": "gpt-4o" }
}
```

Anthropic Messages:

```json
{
  "anthropic": { "id": "msg_123", "model": "claude-3-5-sonnet-latest" }
}
```

Google Generative AI (chat):

```json
{
  "google": { "model": "gemini-1.5-flash" }
}
```
