# Bridge-Incompatible Provider Result Migration Guidance

## Goal

This note freezes how the repository should talk about provider-native result blocks that are still bridge-incompatible at the legacy compatibility layer.

The key problem is not only technical fallback.

The key problem is migration clarity.

When a provider-native block stays outside the bridge allowlist, users need to understand:

- whether the block is unsupported everywhere
- whether it only stays unsupported in the legacy raw bridge
- whether a provider-owned replay path already exists
- whether they should migrate to that provider-owned path or simply stay on the old provider surface for now

## 1. Frozen Messaging Rule

When a provider-native result block is bridge-incompatible, migration guidance should say one of these two things explicitly:

1. **Provider-owned replay path exists**
   - tell the caller to use the provider-owned replay path in the new API
   - also state that raw legacy bridge traffic still falls back

2. **No provider-owned replay path exists yet**
   - tell the caller to keep the request on the old provider path
   - do not imply that a stable migrated replacement already exists

What should not happen:

- generic “unsupported block” wording with no migration direction
- wording that implies the block is unsupported by the whole repository when it is only unsupported by the legacy raw bridge
- wording that suggests widening the shared core is the intended fix

## 2. Anthropic Matrix

For the current breaking round, Anthropic is the concrete example.

| Anthropic raw result family | Legacy raw bridge | Provider-owned replay path | Guidance |
| --- | --- | --- | --- |
| `tool_result` string-content subset | allowed | common/shared path | no special migration warning needed |
| `mcp_tool_result` JSON-safe subset | allowed | common/shared path | no special migration warning needed |
| `web_search_tool_result` exact replay-safe subset | allowed | `anthropic.result.web_search` | no special migration warning needed when inside the allowlist |
| `web_fetch_tool_result` exact replay-safe subset | allowed | `anthropic.result.web_fetch` | no special migration warning needed when inside the allowlist |
| `tool_search_tool_result` exact replay-safe subset | allowed | `anthropic.result.tool_search` | no special migration warning needed when inside the allowlist |
| `code_execution_tool_result` | fallback | `anthropic.result.code_execution` | tell users to move to the provider-owned replay path or stay on the old provider path |
| `bash_code_execution_tool_result` | fallback | `anthropic.result.code_execution` | same guidance |
| `text_editor_code_execution_tool_result` | fallback | `anthropic.result.code_execution` | same guidance |

## 3. Code-Level Rule

Compatibility rejections should keep two properties:

- they must still cause the bridge to return `false` and fall back conservatively
- the underlying `UnsupportedError` message should explain the migration direction clearly enough for tests, logs, and future diagnostics surfaces

That means the rejection string should mention:

- the exact provider-native block family
- whether the new architecture already has a provider-owned replay kind
- whether the caller should migrate or stay on the old provider path

## 4. Documentation Rule

When workstream docs describe a fallback-only provider-native result family, they should say one of:

- “provider-owned replay exists, but the legacy raw bridge stays fallback-only”
- “no provider-owned replay path is frozen yet, so this traffic stays on the old provider path”

That wording is much more useful than a bare “fallback-only”.

## 5. Deprecation Rule

Deprecated compatibility helpers should not over-promise here.

If the stable primary API already has a provider-owned replacement, deprecation text may point at it.

If the stable primary API does not yet replace that feature family, deprecation text should instead point users to:

- the base compatibility constructor
- or the old provider surface that still owns the behavior

This keeps deprecation messaging aligned with real migration coverage.

## 6. Current Conclusion

Bridge-incompatible provider-native result blocks now need explicit migration-oriented wording, not generic rejection text.

For Anthropic specifically:

- `tool_search_tool_result` should now point users at `anthropic.result.tool_search` when they need explicit provider-owned replay payloads
- execution result families should point users at `anthropic.result.code_execution` plus old-provider fallback
