# Provider Metadata Conventions

`providerMetadata` is the escape hatch for provider-specific fields that are not
part of the standardized surface.

This repository follows a Vercel AI SDK–style namespacing convention:

- Providers emit at least one stable namespace key (often the base provider id,
  such as `openai` or `azure`).
- Some providers may also emit capability keys (e.g. `openai.chat`,
  `openai.responses`) for Vercel AI SDK parity and protocol reuse.

Canonicalization policy:

- **Downstream code should read via `readProviderMetadata(providerMetadata, providerId)`.**
- If aliases are emitted, their payload must deep-equal the canonical payload.
- Avoid adding new alias families unless they are justified and tested.

See:

- ADP 0009: `docs/adp/0009-provider-metadata-canonicalization.md`

## Why Aliases

Vercel AI SDK uses `providerName` strings like:

- `openai.chat`
- `openai.responses`
- `anthropic.messages`
- `google.generative-ai`

We keep `providerId` as the stable primary key and add aliases so that:

- Users can match AI SDK fixtures/expectations when porting tests.
- Protocol reuse layers (`*_compatible`) can expose consistent namespaces.

## Recommended usage (downstream)

Prefer reading the canonical key:

```dart
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

final meta = response.providerMetadata;
final openai = readProviderMetadata<Map<String, dynamic>>(meta, 'openai.chat');
```

`readProviderMetadata` prefers a base provider key when present and falls back
to capability keys (and single-entry maps) when needed.

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
  "openai": { "model": "tts-1", "endpoint": "audio/speech" },
  "openai.speech": { "model": "tts-1", "endpoint": "audio/speech" }
}
```

OpenAI-compatible chat (e.g. DeepSeek via Chat Completions):

```json
{
  "deepseek": { "id": "chatcmpl_123", "model": "gpt-4o" },
  "deepseek.chat": { "id": "chatcmpl_123", "model": "gpt-4o" }
}
```

Anthropic Messages:

```json
{
  "anthropic": { "id": "msg_123", "model": "claude-3-5-sonnet-latest" },
  "anthropic.messages": { "id": "msg_123", "model": "claude-3-5-sonnet-latest" }
}
```

Google Generative AI (chat):

```json
{
  "google": { "model": "gemini-1.5-flash" },
  "google.chat": { "model": "gemini-1.5-flash" },
  "google.generative-ai": { "model": "gemini-1.5-flash" }
}
```
