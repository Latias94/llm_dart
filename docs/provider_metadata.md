# Provider Metadata Conventions

`providerMetadata` is the escape hatch for provider-specific fields that are not
part of the standardized surface.

This repository follows a Vercel AI SDK–style namespacing convention:

- Always emit a canonical namespace key equal to the **base provider id**
  (the prefix before the first `.` in `providerId`; e.g. `openai` for
  `openai.chat` and `openai.responses`).
- Also emit one or more capability aliases (e.g. `openai.chat`, `openai.responses`)
  for Vercel AI SDK parity and protocol reuse.

Canonicalization policy:

- **Downstream code should treat `providerMetadata[baseProviderId]` as canonical.**
- Capability keys are aliases for parity/ergonomics.
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
final meta = response.providerMetadata;
final openai = meta?['openai'] as Map<String, dynamic>?;
```

If you are migrating legacy code that used a capability key (e.g. `openai.chat`),
prefer the canonical base key (`openai`) for maximum stability.

Exception note:

- Some providers may emit additional compatibility aliases during the refactor
  window, but the canonical key should remain the base provider id (without
  capability suffixes).

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
