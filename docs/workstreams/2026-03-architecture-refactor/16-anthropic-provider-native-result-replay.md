# Anthropic Provider-Native Result Replay Boundary

## Goal

This document freezes the next design boundary for Anthropic replay work:

- which Anthropic result blocks are bridge-safe today
- why some decoded Anthropic result blocks still cannot be replayed
- how future provider-native result replay should enter the architecture without widening the common core incorrectly

This is a follow-up to:

- `11-anthropic-migration-plan.md`
- `14-provider-replay-fidelity-policy.md`
- `15-legacy-compatibility-facade.md`

## 1. The Current Asymmetry Is Real

The new Anthropic package currently has two different capabilities:

- request encoding can emit a limited set of Anthropic-native replay blocks
- result decoding can recognize a wider set of provider-native result blocks

That asymmetry is expected. It is not a bug by itself.

The current request codec can re-encode:

- assistant `tool_use`
- assistant `server_tool_use`
- assistant `mcp_tool_use`
- user `tool_result`
- user `mcp_tool_result`
- user `web_search_tool_result` through the Anthropic-owned custom replay path
- user `web_fetch_tool_result` through the Anthropic-owned custom replay path
- user `tool_search_tool_result` through the Anthropic-owned custom replay path
- user `code_execution_tool_result` through the Anthropic-owned custom replay path
- user `bash_code_execution_tool_result` through the Anthropic-owned custom replay path
- user `text_editor_code_execution_tool_result` through the Anthropic-owned custom replay path

The current result decoder can also recognize provider-native result families such as:

- `web_search_tool_result`
- `web_fetch_tool_result`
- `code_execution_tool_result`
- `bash_code_execution_tool_result`
- `text_editor_code_execution_tool_result`
- `tool_search_tool_result`

Important conclusion:

- decode breadth is wider than request-side replay breadth
- bridge routing must follow request-side replay breadth, not decode breadth

## 2. Frozen Rule For The Current Breaking Round

Anthropic compatibility and prompt replay should use this rule:

1. a raw or reconstructed Anthropic block is replay-safe only if the new Anthropic request codec can emit the same wire shape back out without semantic loss
2. decode-only support does not make a block bridge-safe
3. when exact request-side re-encoding is not available, the compatibility layer must fall back instead of approximating the block

This rule applies both to:

- legacy `anthropic.contentBlocks` compatibility routing
- future session replay decisions for Anthropic-specific result blocks

## 3. Current Status Matrix

| Wire block family | Current request encode support | Legacy bridge status | Notes |
| --- | --- | --- | --- |
| `tool_use` | yes | allowed | assistant-only |
| `server_tool_use` | yes | allowed | assistant-only |
| `mcp_tool_use` | yes | allowed | assistant-only; requires stable server name |
| `tool_result` | yes | allowed with restrictions | legacy raw replay is currently limited to string `content` so the original wire shape is not normalized into a different JSON form |
| `mcp_tool_result` | yes | allowed | JSON-safe `content` is acceptable and maps cleanly to the current request codec |
| `web_search_tool_result` | yes, through `anthropic.result.web_search` | allowed with restrictions | the new Anthropic prompt path can replay it through provider-owned custom parts, and the legacy raw bridge now accepts the raw block for user-role replay when it stays in the exact `type` / `tool_use_id` / list `content` shape |
| `web_fetch_tool_result` | yes, through `anthropic.result.web_fetch` | allowed with restrictions | the new Anthropic prompt path can replay it through provider-owned custom parts, and the legacy raw bridge now accepts the raw block for user-role replay when it stays in the exact `type` / `tool_use_id` / map `content` shape |
| `code_execution_tool_result` | yes, through `anthropic.result.code_execution` | fallback | provider-owned replay now works through Anthropic custom parts, but the legacy raw bridge still does not accept the raw block directly |
| `bash_code_execution_tool_result` | yes, through `anthropic.result.code_execution` | fallback | same boundary |
| `text_editor_code_execution_tool_result` | yes, through `anthropic.result.code_execution` | fallback | same boundary |
| `tool_search_tool_result` | yes, through `anthropic.result.tool_search` | allowed with restrictions | the new Anthropic prompt path can replay it through provider-owned custom parts, and the legacy raw bridge now accepts the raw block for user-role replay when it stays in the exact `type` / `tool_use_id` / map `content` shape |

## 4. Why Plain `tool_result` Needs A Stricter Legacy Rule

The legacy compatibility layer accepts raw Anthropic `contentBlocks`, not only normalized core prompt parts.

For plain `tool_result`, the current request codec may normalize non-string payloads when encoding the output again. That means:

- the semantic output may still survive
- the original raw wire shape may not survive

The current bridge policy therefore stays conservative:

- raw legacy `tool_result` is bridge-safe only when `content` is already a string
- `mcp_tool_result` can stay JSON-safe because the request codec already emits JSON-safe content for that wire shape directly

This is not an arbitrary difference. It is a replay-fidelity rule.

## 5. Do Not Solve This By Widening The Common Core Blindly

It would be easy to react to the current gap by adding a generic core enum or a provider-specific discriminator directly to `ToolResultPromptPart`.

That is not the recommended direction.

Why:

- the unsupported result families are Anthropic-specific wire blocks, not stable cross-provider semantics
- some of those blocks are renderable provider-native output, not just tool-output transport detail
- forcing Anthropic block typing into the shared core would make the common model absorb provider policy too early

The current recommended split is:

- common `ToolResultPromptPart` stays the home for shared tool-result semantics plus the already supported Anthropic replay shapes
- provider-native Anthropic result replay should use Anthropic-owned prompt/content/UI representations when exact block identity must survive
- small replay hints may still use `providerMetadata`, but full provider-native result payloads should not hide there when they are semantically renderable output

## 6. Recommended Representation For Future Anthropic Result Replay

For future Anthropic-native result replay, prefer a provider-owned representation built on existing extension channels:

- `CustomContentPart` for decoded provider-native output that should remain renderable
- `CustomUiPart` for UI projection of the same provider-native output
- `CustomPromptPart` for replaying that provider-native output back into Anthropic requests

Recommended namespace direction:

- `kind: "anthropic.result.web_search"`
- `kind: "anthropic.result.web_fetch"`
- `kind: "anthropic.result.tool_search"`
- `kind: "anthropic.result.code_execution"`

The exact names can still change, but the shape should stay provider-owned and namespaced.

Why this is the preferred direction:

- it preserves wire-family identity without polluting common tool-result semantics
- it stays aligned with the existing provider-feature placement rules for renderable provider-native output
- it gives Flutter and session replay one stable provider-owned payload path

## 7. Promotion Checklist For Any New Anthropic Result Block

Before a provider-native result block moves from fallback to replay-safe, all of the following should be true:

1. the Anthropic request codec can emit the exact block type and required fields
2. prompt history can preserve the payload in a JSON-safe form
3. UI projection can preserve or intentionally summarize the provider-native payload without blocking replay
4. session restore can round-trip the payload back into `PromptMessage`
5. route-compatibility tests prove unsupported legacy raw blocks still fall back
6. codec tests prove the supported block round-trips without shape loss
7. migration docs explain whether the block is shared, provider-owned, or fallback-only

If any item above is missing, the block should stay fallback-only.

## 8. Recommended Execution Order

The current execution order is:

1. implement one Anthropic-owned custom replay path for `web_search_tool_result`
2. validate prompt serialization, UI projection, session replay, and request re-encoding through that path
3. extend the same provider-owned replay path to `web_fetch_tool_result`
4. allow the same two retrieval result families in the legacy raw bridge only after exact raw re-encoding is proven
5. leave the legacy raw bridge for execution result families for later unless a concrete product flow needs it

Current status:

- steps 1 and 2 are now implemented for `web_search_tool_result`
- step 3 is now also implemented for `web_fetch_tool_result`
- step 4 is now also implemented for all three current retrieval result families
- the provider-owned replay path is now also implemented for the execution result families through `anthropic.result.code_execution`
- the remaining execution boundary is the legacy raw bridge, which still stays fallback-only

## 9. Migration Guidance

For the current breaking round, user guidance should be explicit:

- legacy raw Anthropic `tool_use` / `server_tool_use` / `mcp_tool_use` can bridge
- legacy raw Anthropic `tool_result` / `mcp_tool_result` can bridge only inside the currently frozen replay-safe subset
- provider-owned Anthropic replay for `web_search_tool_result` now works through `CustomContentPart` / `CustomUiPart` / `CustomPromptPart`
- provider-owned Anthropic replay for `web_fetch_tool_result` now works through `CustomContentPart` / `CustomUiPart` / `CustomPromptPart`
- provider-owned Anthropic replay for `tool_search_tool_result` now also works through `CustomContentPart` / `CustomUiPart` / `CustomPromptPart`
- provider-owned Anthropic replay for `code_execution_tool_result`, `bash_code_execution_tool_result`, and `text_editor_code_execution_tool_result` now works through `CustomContentPart` / `CustomUiPart` / `CustomPromptPart` with `kind: "anthropic.result.code_execution"`
- legacy raw Anthropic `web_search_tool_result` can now bridge only for user-role replay with the exact `type` / `tool_use_id` / list `content` wire shape
- legacy raw Anthropic `web_fetch_tool_result` can now bridge only for user-role replay with the exact `type` / `tool_use_id` / map `content` wire shape
- legacy raw Anthropic `tool_search_tool_result` can now bridge only for user-role replay with the exact `type` / `tool_use_id` / map `content` wire shape
- legacy raw execution-oriented provider-native result blocks still fall back to the old provider path

This should be documented as a fidelity boundary, not as a temporary codec omission.

## 10. Practical Review Rule

When an Anthropic result replay change is proposed, ask:

> Can the new request codec emit the same provider-native block family back out, and can session replay preserve it without hiding critical payload in ad hoc metadata?

If the answer is no, the block should not enter the bridge allowlist yet.
