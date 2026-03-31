# OpenAI Provider-Owned Input Hints

## Purpose

This note freezes a narrow provider-owned hint contract for OpenAI-family user input encoding.

The goal is to keep the shared `PromptPart` model stable while still allowing OpenAI-specific input features that do not belong in the unified core contract.

## Why This Should Stay Provider-Owned

The shared prompt model already has the right common fields:

- `ImagePromptPart.mediaType`
- `ImagePromptPart.uri`
- `ImagePromptPart.bytes`
- `FilePromptPart.mediaType`
- `FilePromptPart.filename`
- `FilePromptPart.uri`
- `FilePromptPart.bytes`

What it does not have, and should not gain just for OpenAI, is a dedicated field for:

- OpenAI file handles such as `file_id`
- OpenAI image-detail hints such as `low` / `high` / `auto`

Those are provider-specific transport hints, not portable prompt semantics.

## Frozen Hint Keys

OpenAI-family codecs may read the following provider-owned keys from `PromptPart.providerMetadata['openai']`:

- `fileId`
  - string
  - provider-owned OpenAI file handle for user input encoding
- `imageDetail`
  - string
  - provider-owned hint for OpenAI image detail handling

These keys are intentionally namespaced and should not be promoted into shared core fields.

## Supported Uses

### Responses Path

The migrated Responses codec may use:

- `ImagePromptPart.providerMetadata['openai']['fileId']`
  - encodes user image input as `input_image.file_id`
- `FilePromptPart.providerMetadata['openai']['fileId']`
  - for `application/pdf`, encodes user file input as `input_file.file_id`
- `ImagePromptPart.providerMetadata['openai']['imageDetail']`
- image-shaped `FilePromptPart.providerMetadata['openai']['imageDetail']`
  - encodes the OpenAI `detail` hint on `input_image`

The Responses path may also use `FilePromptPart.uri` for PDF files as `input_file.file_url`.

### Chat-Completions Path

The migrated chat-completions codec may use:

- `FilePromptPart.providerMetadata['openai']['fileId']`
  - for `application/pdf`, encodes user file input as `file.file_id`
- `ImagePromptPart.providerMetadata['openai']['imageDetail']`
- image-shaped `FilePromptPart.providerMetadata['openai']['imageDetail']`
  - encodes the OpenAI `image_url.detail` hint

The chat-completions path should still reject URL-backed PDF or audio file parts.

## Non-Goals

This contract does not freeze:

- assistant-side file-handle replay
- generic provider-owned file handles for non-OpenAI providers
- new shared prompt fields for provider-native transport hints
- any promise that every OpenAI-compatible profile supports every OpenAI-owned hint identically

## Recommendation

Future OpenAI-owned input hints should only be added if they meet all three conditions:

1. they are request-shaping details, not shared conversation semantics
2. they are already known to exist on the OpenAI-family wire contract
3. they can be encoded without widening the shared core model
