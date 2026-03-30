# Anthropic Provider-Native Files API

## Goal

This document freezes the provider-owned files boundary for Anthropic execution output handles.

It answers one practical migration question:

> When Anthropic code execution returns provider file IDs, what API should `llm_dart` expose, and where should that API live?

## 1. Reference Signal From `repo-ref/ai`

The reference Anthropic examples consistently treat downloadable execution files as a provider-native follow-up flow:

- execution replay preserves file handles such as `file_id`
- metadata is fetched from `GET /v1/files/{fileId}`
- bytes are downloaded from `GET /v1/files/{fileId}/content`
- both requests require the Anthropic files beta header

That means the correct lesson is not to pretend that a provider file handle is already a common generated file.

## 2. Frozen Boundary

The frozen boundary is:

- execution replay stores provider-native file handles only
- `llm_dart_anthropic` owns the typed files API
- `llm_dart_core` does not gain a shared files-download abstraction for this feature
- `llm_dart_flutter` persists and restores the provider-owned replay payload, but does not auto-resolve downloads

This keeps replay fidelity and download mechanics separate.

## 3. Public API Shape

The current provider-owned API lives in `llm_dart_anthropic`:

- `Anthropic.files()`
- `AnthropicFiles`
- `AnthropicFilesSettings`
- `AnthropicFileDescriptor`
- `AnthropicFileDownload`
- `AnthropicExecutionFileHandleFilesX`

Recommended usage:

1. decode or restore `anthropic.result.code_execution`
2. read `AnthropicExecutionFileHandle`
3. resolve metadata with `AnthropicFiles.getFile(...)` or `handle.getMetadata(...)`
4. download bytes with `AnthropicFiles.downloadFile(...)` or `handle.download(...)`

## 4. Request Rules

The provider-owned files API follows these rules:

- metadata endpoint: `GET /v1/files/{fileId}`
- content endpoint: `GET /v1/files/{fileId}/content`
- required auth headers remain provider-owned
- the files beta flag is added automatically: `files-api-2025-04-14`
- custom headers may still add more beta flags or deployment-specific headers

This is why the API belongs in the Anthropic package, not in the shared core.

## 5. Dependency Direction

The dependency direction stays intentionally narrow:

- `AnthropicFiles` depends on `llm_dart_transport`
- `AnthropicExecutionFileHandle` remains a provider-owned typed model in `llm_dart_anthropic`
- no dependency flows back into `llm_dart_core`
- no common file-download API is introduced for other providers to implement prematurely

This is consistent with the medium-grained workspace split.

## 6. File Model Rule

Anthropic file IDs still do not become common `GeneratedFile` values automatically.

Why:

- a file ID is only a provider handle
- it does not contain bytes
- it does not guarantee a stable filename or MIME type without a metadata fetch
- it does not provide a cross-provider download contract

The common file model should only be considered after an explicit provider-native resolution step, and only if a real shared semantic emerges.

## 7. Flutter Integration Rule

For Flutter chat applications, the recommended flow is:

- let session replay preserve the provider-owned execution payload
- render file handles through provider-specific UI helpers if desired
- resolve metadata or bytes lazily when the user asks to inspect or download the file

Do not make the chat session automatically fetch file bytes during replay restoration.

That would mix persistence, networking, and UI policy in the wrong layer.

## 8. Review Rule

When a new provider-native file helper is proposed, ask:

> Are we resolving a provider-owned handle through a provider-owned API, or are we pretending that a provider handle is already a shared file object?

If the answer is the second one, the boundary is being widened too early.
