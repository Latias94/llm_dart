# Provider Metadata Conventions

`providerMetadata` is the escape hatch for provider-specific fields that are not
part of the standardized surface.

This repository follows a Vercel AI SDK–style namespacing convention:

- Always emit a canonical namespace key equal to the provider instance `providerId`
  (e.g. `openai`, `anthropic`, `google`, `deepseek`, `xai.responses`).
- Historically, we also emitted capability aliases (e.g. `openai.chat`,
  `openai.responses`, `google.generative-ai`) for AI SDK fixture parity.

Canonicalization policy:

- **Downstream code should treat `providerMetadata[providerId]` as canonical.**
- Alias keys are **compatibility only** during the fearless refactor window.
- If aliases are emitted, their payload must deep-equal the canonical payload.
- We stop adding new aliases by default.

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
final meta = response.providerMetadata;
final openai = meta?['openai'] as Map<String, dynamic>?;
```

If you are migrating legacy code that used an alias key (e.g. `openai.chat`),
update it to the canonical `openai` key.

Exception note:

- Some providers intentionally emit AI SDK parity namespaces (e.g. Google Vertex
  emits `vertex`). See provider guides for the canonical key per provider.

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
