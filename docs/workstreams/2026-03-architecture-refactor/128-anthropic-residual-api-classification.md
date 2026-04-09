# 128. Anthropic Residual API Classification

## Question

After relocating the Anthropic root shell and legacy modules under
`src/compatibility`, which remaining Anthropic root APIs should still count as
real migration targets for `llm_dart_anthropic`, and which should stay
explicitly classified as compatibility-only residual surface?

## Why This Review Matters

The recent Anthropic cleanup made the ownership structure much clearer:

- `llm_dart_anthropic` already owns the modern text-generation mainline
- the root package now visibly hosts only the compatibility-era Anthropic
  surface

That still leaves an important product question:

- which remaining Anthropic compatibility APIs are only old interface baggage
- which still reveal a real provider-owned capability gap worth closing later

Without that classification, the repository risks treating every old Anthropic
method as unfinished migration work, which would recreate the same coupling
problem under a different directory.

## What Was Reviewed

Root compatibility-owned Anthropic surface:

- `lib/src/compatibility/providers/anthropic/provider_compat.dart`
- `lib/src/compatibility/providers/anthropic/chat.dart`
- `lib/src/compatibility/providers/anthropic/files.dart`
- `lib/src/compatibility/providers/anthropic/models.dart`
- `lib/providers/anthropic/config.dart`
- `lib/providers/anthropic/builder.dart`
- `lib/providers/anthropic/anthropic.dart`
- `lib/providers/anthropic/mcp_models.dart`

Modern package-owned Anthropic surface:

- `packages/llm_dart_anthropic/lib/src/anthropic.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_language_model.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_files.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_options.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_mcp_models.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_tools.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_code_execution_replay.dart`

Reference package signals from `repo-ref/ai`:

- `repo-ref/ai/packages/anthropic/src/anthropic-provider.ts`
- `repo-ref/ai/packages/anthropic/src/anthropic-messages-language-model.ts`
- `repo-ref/ai/packages/anthropic/src/anthropic-tools.ts`

## Classification Matrix

| Legacy/root Anthropic surface | Modern package-owned status | Classification | Recommended direction |
| --- | --- | --- | --- |
| Chat, tool calling, reasoning, web-search request shaping, MCP connector request config, execution replay, provider-native result replay | Already owned by `Anthropic.chatModel(...)` plus `AnthropicChatModelSettings`, `AnthropicGenerateTextOptions`, typed native tools, MCP models, and replay helpers | migrated modern mainline | keep only legacy `ChatCapability` routing glue and compatibility replay adapters in root |
| Execution file metadata and download helpers | Already owned by `Anthropic.files()` plus `AnthropicFileDescriptor`, `AnthropicFileDownload`, and execution file-handle extensions | migrated provider-owned helper | keep root file helpers only for legacy `FileManagementCapability` and old file-model compatibility |
| General file CRUD (`uploadFile`, `listFiles`, `deleteFile`, batch helpers, storage summary) | **Not** mirrored by `llm_dart_anthropic`; modern package intentionally focuses on execution file handles | compatibility-only residual for now | keep out of shared core; add a separate provider-owned storage utility only if concrete app demand appears beyond execution downloads |
| Model listing (`models`, `listModels`, `getModel`) | **Not** present in `llm_dart_anthropic` or `repo-ref/ai` | provider-specific convenience, not shared parity work | keep compatibility-only for now; only add a provider-owned catalog helper later if a real product need appears |
| Exact token counting through Anthropic `messages/count_tokens` | **Not** present in `llm_dart_anthropic` or `repo-ref/ai` | real provider-owned gap candidate | do not widen shared `LanguageModel`; consider a provider-owned helper later because exact budgeting is still useful for chat apps |
| Legacy config/builder/factory DSL (`AnthropicConfig`, `AnthropicBuilder`, `createAnthropic*Provider(...)`) | Modern provider construction already exists through `AI.anthropic(...).chatModel(...)` and `llm_dart_anthropic` | compatibility-only residual | keep on root/`legacy.dart`; do not recreate this DSL in the provider package |
| Legacy raw prompt-block and cache DSL (`AnthropicTextBlock`, `AnthropicToolsBlock`, `AnthropicMessageBuilder`, raw `anthropic.contentBlocks`) | Modern package already uses typed provider options plus provider metadata and `toolsCacheControl` | compatibility-only residual | do not migrate the raw block DSL; keep only as compatibility input and migration fallback |
| Root `AnthropicMCPServer` legacy models and builder wiring | Modern package already owns typed `AnthropicMcpServer` models | compatibility-only duplicate | keep only while the old builder/config paths exist; new code should use the package-owned types |

## What The Matrix Shows

### 1. Anthropic text migration is already structurally complete

The main capability family that justified `llm_dart_anthropic` already has a
clear modern home:

- text generation
- native tools
- reasoning
- MCP connector request configuration
- provider-native execution and tool-result replay

That means Anthropic should no longer be treated as a broad modern-surface gap.

### 2. The remaining open items are narrow and provider-shaped

The real remaining Anthropic questions are now much smaller:

- should exact token counting gain a provider-owned helper
- should general file CRUD ever gain a provider-owned storage utility
- should model listing ever gain a provider-owned catalog helper

These are provider-shaped extras, not missing shared-capability parity.

### 3. `repo-ref/ai` points in the same direction

The reference package centers its Anthropic provider around:

- a language-model factory
- request and stream codecs
- provider-owned native-tool definitions

It does **not** expose:

- model listing
- general file CRUD
- a legacy config or builder DSL

That supports the same conclusion here:

- avoid migrating old root helper APIs mechanically
- close only the provider-owned gaps that still matter as real product APIs

### 4. Our execution-file helper is a deliberate provider-owned deviation

`repo-ref/ai` does not expose a general Anthropic files surface.

`llm_dart_anthropic` still already exposes `Anthropic.files()` because this
repository has an explicit product need around execution replay and downloadable
output handles.

That difference is intentional and still fits the target architecture because:

- the helper is provider-owned, not pushed into the shared core
- it stays narrowly scoped to execution-oriented metadata and downloads
- it does not force the old legacy file-management interface to remain a modern
  abstraction

### 5. Token counting is the clearest remaining modern-gap candidate

Unlike model listing or general file CRUD, exact token counting is directly
useful for application-level prompt budgeting, guardrails, and preflight UX.

Anthropic exposes a dedicated endpoint for this, and the current root
compatibility provider already uses it.

That makes `countTokens(...)` the clearest Anthropic feature that could later
deserve a provider-owned helper without widening the shared core.

## Recommended Near-Term Policy

### Treat these as complete modern migrations

- text generation
- reasoning and thinking controls
- native tools and deferred-tool loading
- MCP connector request configuration
- provider-native replay helpers
- execution file metadata and download helpers

### Treat these as root compatibility-only residual APIs for now

- `AnthropicConfig` and the legacy Anthropic builder DSL
- `createAnthropic*Provider(...)` preset constructors
- raw `AnthropicMessageBuilder` / `contentBlocks` cache DSL
- legacy root `AnthropicMCPServer` model types
- general file CRUD helpers and batch convenience methods
- model-listing helpers

### Treat these as explicit provider-owned gap candidates, not shared-core work

- exact Anthropic token counting
- any future broader Anthropic storage/catalog utility, but only if real app
  demand appears

## Practical Next Slice

The next Anthropic implementation step should **not** be another broad file
move.

It should be this focused decision:

1. decide whether Anthropic exact token counting deserves a provider-owned
   helper in `llm_dart_anthropic`

That is the clearest remaining Anthropic API that:

- is useful for Flutter chat applications
- maps to a dedicated Anthropic endpoint
- preserves our provider-specific strength
- still does not justify widening the shared core

## Conclusion

Anthropic is now structurally close to the target architecture.

The remaining Anthropic root surface should no longer be read as one big
unfinished migration block.

Most of it is now best classified as compatibility-only residual API, while the
main remaining modern-gap candidate is:

- exact token counting

That classification should guide the next breaking-round Anthropic work.
