# Anthropic Status Reconciliation

## Goal

This note reconciles the Anthropic workstream documents with the package state that now exists in `packages/llm_dart_anthropic`.

The immediate purpose is to stop treating already-migrated Anthropic work as still-open architecture debt.

## 1. What Is Now Actually Package-Owned

The Anthropic package now already owns the main text path and several provider-native replay or helper surfaces:

- `Anthropic.chatModel(...)`
- `Anthropic.files(...)`
- `AnthropicChatModelSettings`
- `AnthropicGenerateTextOptions`
- `AnthropicFilesSettings`
- `AnthropicCacheControl`
- `AnthropicMessagesCodec`
- `AnthropicMessagesResultCodec`
- `AnthropicStreamCodec`
- `AnthropicMcpServer` and related typed MCP models
- `AnthropicToolSearchRegexTool20251119`
- `AnthropicToolSearchBm25Tool20251119`
- `AnthropicCodeExecutionReplay`

This is no longer just a skeleton or a thin landing zone.

## 2. What The Current Anthropic Package Already Proves

### Request Encoding

The package-owned request codec already covers:

- common function tools through `GenerateTextRequest.tools`
- shared `ToolChoice`
- Anthropic native tools through typed package APIs
- provider-owned deferred-loading controls for common function tools through
  `deferredToolNames`
- extended thinking and interleaved-thinking request controls
- MCP server configuration without reviving `extensions`
- request-side cache control through typed tool-cache options and provider metadata

### Result And Stream Decoding

The result and stream codecs already cover:

- text output
- reasoning / thinking output, including redacted-thinking metadata
- common tool-use and tool-result flows
- Anthropic provider-executed tool calls
- MCP tool-use and tool-result flows
- provider-native `web_search_tool_result` replay payloads
- provider-native `web_fetch_tool_result` replay payloads
- provider-native `tool_search_tool_result` replay payloads
- provider-native execution replay payloads
- citation to shared source projection
- malformed tool-input stream handling

### Provider-Native APIs

The package now also already owns:

- typed execution replay parsing and rendering helpers
- typed execution file-handle helpers
- provider-native files API access for execution downloads

## 3. TODO Items That Are Now Stale

The following work should now be treated as migrated rather than still-open:

- the Anthropic tool codec
- the Anthropic reasoning codec
- the Anthropic web-search adapter
- the Anthropic MCP connector request-side path

The cache-structure item also needs a narrower interpretation:

- the canonical migrated path is now `ProviderMetadata({'anthropic': {'cacheControl': ...}})` plus typed `toolsCacheControl`
- the legacy `anthropic.contentBlocks` shape still exists only as compatibility input and migration fallback

So cache-control migration is complete for the new package-owned surface even though compatibility code still accepts the old raw shape.

## 4. The Remaining Real Anthropic Gaps

The remaining Anthropic gaps are now much smaller than older TODO wording suggests:

- provider-owned custom tool-reference helpers for user-defined tool-search
  flows are still not exposed
- provider-owned native-tool selection is still deferred until a concrete forcing use case appears
- additional provider-native admin or storage APIs may still land later, but they are not blockers for the migrated text boundary

Important consequence:

- Anthropic should not keep being described as waiting on generic “non-text migration parity”
- the remaining open work is now replay-policy cleanup plus optional future provider-native surfaces

## 5. Roadmap Consequence

For the current breaking round, Anthropic is no longer the primary architecture blocker.

The next meaningful Anthropic work should be limited to:

1. deciding whether Anthropic should expose provider-owned custom tool-reference helpers for user-defined tool-search flows
2. deciding whether Anthropic ever needs a public provider-owned tool-selection surface
3. keeping compatibility and migration guidance precise as the remaining provider-native surfaces land

That is a much smaller and safer scope than reopening the Anthropic text mainline.
