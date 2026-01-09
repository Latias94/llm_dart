# Provider Metadata Conventions

`providerMetadata` is the escape hatch for provider-specific fields that are not
part of the standardized surface.

This repository follows a Vercel AI SDK–style namespacing convention:

- Always emit a base namespace key equal to `providerId` (e.g. `openai`,
  `anthropic`, `google`, `deepseek`).
- Additionally emit one or more capability aliases (e.g. `openai.chat`,
  `openai.responses`, `openai.image`, `openai.speech`, `openai.transcription`).
- Never remove existing keys. New aliases must mirror the exact same payload.

## Why Aliases

Vercel AI SDK uses `providerName` strings like:

- `openai.chat`
- `openai.responses`
- `anthropic.messages`
- `google.generative-ai`

We keep `providerId` as the stable primary key and add aliases so that:

- Users can match AI SDK fixtures/expectations when porting tests.
- Protocol reuse layers (`*_compatible`) can expose consistent namespaces.

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

