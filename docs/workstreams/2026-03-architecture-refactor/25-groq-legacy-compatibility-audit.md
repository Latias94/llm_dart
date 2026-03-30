# Groq Legacy Compatibility Audit

## Goal

This note freezes the initial Groq compatibility position after the OpenAI-family chat-completions mainline landed in `llm_dart_openai`.

The question is not whether the refactored package can call Groq directly.

It can.

The real question is narrower:

- which legacy Groq request shapes are already bridge-safe
- which ones still require fallback to the old provider
- what the first acceptable compatibility subset should be

## 1. Current Legacy Groq Surface

The old root Groq provider is relatively small, but it is not a perfect OpenAI-compatible bridge.

Its current request behavior includes:

- endpoint: `chat/completions`
- common request fields:
  - `model`
  - `messages`
  - `stream`
  - `max_tokens`
  - `temperature`
  - `top_p`
  - `top_k`
  - `tools`
  - `tool_choice`
- message `name` passthrough

The important legacy limitations are:

- the old provider does not serialize `stopSequences`
- the old provider does not serialize `user`
- the old provider does not serialize `serviceTier`
- the old provider does not serialize typed structured output
- the old provider does not have a faithful multimodal request encoder even though the config still carries model-family vision flags
- the old provider does not preserve `ToolResultMessage` as a real tool-role replay shape

So Groq is operationally close to OpenAI chat-completions, but its legacy request surface is narrower than the root builder might suggest.

## 2. Current Refactored Package Coverage

The refactored `llm_dart_openai` package now provides a usable Groq direct path through `GroqProfile` on top of the chat-completions mainline.

Current direct-package coverage includes:

- text generation
- streaming text deltas
- common function tools
- common tool choice
- streamed tool-call aggregation
- generic OpenAI-family chat-completions request encoding

Current gaps relative to the old Groq root-provider behavior still include:

- no frozen compatibility policy yet for named legacy messages
- no frozen compatibility policy yet for legacy prompt-side tool replay
- no frozen compatibility policy yet for old Groq multimodal assumptions
- no reason to auto-enable legacy fields that the old provider used to ignore

So the package mainline exists, but the legacy Groq bridge still needs an explicit subset audit.

## 3. Bridge-Risk Inventory

### Safe enough today for direct package execution

- plain text prompts
- common assistant text output
- common function-tool declarations
- common tool choice
- OpenAI-compatible chat-completions streaming

### Not bridge-safe yet for automatic legacy routing

- named legacy messages
- any legacy message decorators or provider extensions
- prompt replay that uses `ToolUseMessage` or `ToolResultMessage`
- any request that depends on:
  - `stopSequences`
  - `user`
  - `serviceTier`
  - typed structured output
  - OpenAI-family extras such as `parallelToolCalls` or `verbosity`
- any multimodal request shape
- mixed shaping that combines `config.systemPrompt` with explicit system messages

### Why tool replay stays out of subset V1

The old Groq provider can declare tools on the request.

But its legacy prompt encoder does not preserve full tool-result replay semantics cleanly, and the refactored path would otherwise improve those requests silently instead of matching the old behavior exactly.

That is a migration decision, not something the compatibility layer should assume.

So the first bridge-safe subset should stop at common function-tool declaration, not tool replay history.

## 4. Proposed Bridge-Safe Subset V1

The first acceptable Groq compatibility subset should stay intentionally narrow:

- provider: `groq`
- prompt shape:
  - system text
  - user text
  - assistant text
- common request controls:
  - `maxTokens`
  - `temperature`
  - `topP`
  - `topK`
  - one system-shaping path only:
    - either `systemPrompt`
    - or explicit system messages
- common tool support:
  - common function tools only
  - common `ToolChoice`

The first subset should explicitly exclude:

- named messages
- legacy message extensions
- assistant tool-call replay in prompt history
- tool-result replay in prompt history
- multimodal prompt parts
- `stopSequences`
- `user`
- `serviceTier`
- typed structured output
- OpenAI-family extension-only controls that the old Groq provider ignored

## 5. Routing Rule Recommendation

The Groq subset V1 is now the active compatibility rule.

Current routing rule:

- if the request matches the Groq subset V1 exactly, it routes to `llm_dart_openai` with `GroqProfile`
- otherwise it stays on the legacy Groq provider path automatically

This is intentionally a per-request rule, not a declaration that all Groq legacy traffic is now migrated.

## 6. Follow-Up Work Needed Before Expansion

1. Decide whether legacy assistant tool-call replay deserves a separate audited Groq subset later.
2. Decide whether legacy tool-result replay should become bridge-safe through a frozen provider-owned encoding path, or remain fallback-only.
3. Decide whether ignored legacy fields such as `stopSequences` should stay fallback-only for the whole migration window or become typed Groq options later.
4. Keep compatibility tests that prove:
   - plain text-and-tool-definition Groq requests route safely
   - tool replay forces fallback
   - multimodal Groq requests force fallback
   - ignored legacy extras force fallback

## 7. Current Conclusion

Groq has now crossed both:

- the package-mainline threshold
- the initial compatibility-routing threshold for subset V1 only

That is still a conservative intermediate state, not full Groq migration.

The next safe step is to expand only one additional audited Groq subset at a time.
