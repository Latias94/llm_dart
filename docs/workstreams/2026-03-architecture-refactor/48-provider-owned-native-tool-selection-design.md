# Provider-Owned Native Tool Selection Design

## Goal

This note freezes how provider-owned native-tool forcing or selection should be
designed without widening shared `ToolChoice`.

The core question is:

> If a provider supports native tools with provider-specific selection or
> forcing semantics, where should that API live and how should it interact with
> the current shared function-tool contract?

The short answer is:

- do not widen shared `ToolChoice`
- keep native-tool selection provider-owned
- do not silently merge provider-owned selection with shared `toolChoice`
- land provider-owned selection only where the wire contract is already proven

## 1. Shared Constraint

The current shared `ToolChoice` remains intentionally small:

- `AutoToolChoice`
- `RequiredToolChoice`
- `SpecificToolChoice`
- `NoneToolChoice`

That contract exists for the cross-provider function-tool overlap.

It should not expand to absorb:

- provider-native tool IDs
- provider-native parallelism controls
- provider-specific approval or execution modes
- model-family-specific mixed-tool policies

If we widen shared `ToolChoice`, we will recreate the same coupling problem that
the refactor is trying to remove.

## 2. General Provider Rule

If a provider later needs native-tool selection or forcing, the API must live
inside that provider's typed settings or invocation options.

Frozen rule:

- shared `toolChoice` stays shared-function-oriented
- provider-owned native-tool selection lives under provider-owned options
- provider-owned selection must not silently merge with shared `toolChoice`

Recommended conflict rule:

- if provider-owned native-tool selection is set for a call, shared
  `toolChoice` must be `null`
- if both are set, the provider codec should reject the request before sending

This is stricter than warning-based override, but it keeps the boundary honest.

## 3. Anthropic

## Current State

Anthropic is the closest provider to a mixed declaration surface:

- common function tools and native tools can already share one request-side
  `tools` array
- shared `AutoToolChoice` and `RequiredToolChoice` can already apply across the
  current mixed request subset
- `SpecificToolChoice` still remains stable only for declared common function
  tools in phase 1

There is already one important provider rule that the shared contract does not
express well:

- extended thinking only supports `auto` or `none` tool choice

That restriction is now enforced in code.

External contract signal:

- Anthropic's current extended-thinking documentation also states that thinking
  mode supports only `tool_choice: auto` or `tool_choice: none`

## Why Anthropic Needs A Provider-Owned Surface Later

If Anthropic later needs richer tool selection, the missing pieces are
provider-specific:

- selecting a native tool by name when it is not a declared common function
  tool
- `disable_parallel_tool_use`
- future native-tool-family forcing that is not equivalent to shared
  `SpecificToolChoice`

Those do not belong in shared `ToolChoice`.

## Recommended Anthropic Shape

If this lands later, it should be a provider-owned contract such as:

```dart
sealed class AnthropicToolSelection {
  const AnthropicToolSelection();
}

final class AnthropicAutoToolSelection extends AnthropicToolSelection {
  final bool? disableParallelToolUse;
}

final class AnthropicNoToolSelection extends AnthropicToolSelection {}

final class AnthropicAnyToolSelection extends AnthropicToolSelection {
  final bool? disableParallelToolUse;
}

final class AnthropicSpecificToolSelection extends AnthropicToolSelection {
  final String toolName;
  final bool? disableParallelToolUse;
}
```

Placement:

- model defaults: `AnthropicChatModelSettings.toolSelection`
- per-call override: `AnthropicGenerateTextOptions.toolSelection`

Conflict rule:

- if `toolSelection` is set, shared `toolChoice` must be `null`

This avoids ambiguous merge rules across mixed common/native tool sets.

## 4. Google

## Current State

The current Google migrated path is intentionally conservative:

- common function tools use `functionDeclarations`
- shared `ToolChoice` maps to `toolConfig.functionCallingConfig`
- native Google tools are provider-owned
- when native tools are active, common function tools and shared `toolChoice`
  are currently ignored with warnings

That is the current implementation boundary, not the final ecosystem truth.

External contract signal:

- Google's current Gemini function-calling documentation already describes a
  broader Gemini 3 multi-tool path with server-side tool-invocation circulation
  for mixed built-in and function-tool use

## Why Google Should Not Get A Fake Selection API Yet

Google is the clearest example of why we should not invent a provider-owned
selection API too early.

The current request codec does not yet model a stable mixed-tool contract for:

- native Google search/code-execution tools
- function declarations
- server-side tool invocation circulation

Until that wire contract is proven in the migrated provider path, a public
`GoogleNativeToolChoice` or `GoogleToolPolicy` API would be guesswork.

## Frozen Google Rule

For now:

- keep Google native tools as provider-owned declaration only
- do not add a public forcing or selection API yet
- do not widen shared `ToolChoice` to compensate

Future prerequisite before any Google selection API lands:

- first migrate a real mixed-tool wire contract in the provider codec
- then expose a provider-owned policy surface that matches that contract

## 5. OpenAI Responses

OpenAI Responses already proves the same design lesson:

- built-in tools are provider-owned
- approval and provider-hosted continuation are provider-owned
- richer built-in tool control must stay in `OpenAIGenerateTextOptions`

If OpenAI later needs finer built-in-tool selection semantics, they should stay
inside OpenAI-owned options rather than widening shared `ToolChoice`.

## 6. Precedence Rule

When provider-owned native-tool selection exists later, it should follow the
same precedence as other provider-owned settings:

- invocation options override model defaults
- no implicit merging

That means:

- `ProviderGenerateTextOptions.toolSelection`
  overrides `ProviderChatModelSettings.toolSelection`
- the resolved provider-owned selection is then validated against the rest of
  the provider request shape

## 7. Recommended Implementation Order

1. keep shared `ToolChoice` unchanged
2. add provider-specific guardrails where official provider rules are already
   known
3. if a real provider-owned selection surface is needed, land Anthropic first
4. only revisit Google after the migrated codec supports a proven mixed-tool
   wire contract
5. keep OpenAI built-in selection provider-owned in the Responses path

## Conclusion

The design is now frozen:

- shared `ToolChoice` stays small
- provider-owned native-tool selection stays provider-owned
- provider-owned selection must not silently merge with shared `toolChoice`
- Anthropic is the first realistic candidate for a provider-owned selection
  surface
- Google should not expose one yet until its mixed-tool wire contract is
  actually migrated

That is the right tradeoff for `llm_dart`.
