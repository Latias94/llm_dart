# Prompt Normalization Contract

## Why This Note Exists

The refactor keeps one shared prompt model:

- `SystemPromptMessage`
- `UserPromptMessage`
- `AssistantPromptMessage`
- `ToolPromptMessage`
- shared prompt parts such as text, files, tool calls, tool results, reasoning, and custom parts

However, a shared prompt model does not imply that every provider can replay every part in the same way.

This note freezes the practical normalization contract that the tests now enforce.

## Stable Cross-Provider Replay Subset

The current replay-safe subset across the primary text providers is:

- system text
- user text
- assistant text
- assistant function tool calls that are not provider-executed/dynamic
- tool results

This subset can be normalized across:

- Anthropic Messages
- Google GenerateContent
- OpenAI Responses
- OpenAI-family chat completions

The wire shapes differ, but the semantic contract is shared.

## Areas That Are Intentionally Not Fully Unified

### 1. Multimodal User Input

- Anthropic accepts text + image + selected document/file inputs
- Google accepts text + image + file inputs
- OpenAI-family chat completions currently supports text + image plus an OpenAI-shaped file subset for image/audio/PDF
- OpenAI Responses currently supports text + image plus OpenAI-shaped file input on the migrated request boundary

Conclusion:

- multimodal user prompt replay is not yet a universally shared normalization surface

### 2. Provider-Executed Tools And Approval Flows

- Anthropic has provider-native replay for server tools and MCP tool traffic
- OpenAI Responses keeps approval continuation and provider-executed MCP traffic in provider-owned item families
- Google currently collapses replay into function-call / function-response shapes
- OpenAI-family chat completions drops these flows with warnings

Conclusion:

- provider-executed and approval flows must remain provider-owned behavior, not a guaranteed common replay contract

### 3. Assistant Reasoning Replay

- Google can replay assistant reasoning as thought-tagged parts
- OpenAI Responses only preserves replay fidelity when provider-owned metadata exists
- Anthropic currently drops assistant reasoning replay with warnings
- OpenAI-family chat completions drops assistant reasoning replay with warnings

Conclusion:

- assistant reasoning replay is not a safe common replay assumption

### 4. OpenAI Assistant Replay Boundaries

- OpenAI-family chat completions intentionally keeps assistant replay narrow: text plus common function tool calls
- OpenAI Responses is richer, but that extra richness is still OpenAI-owned rather than a shared cross-provider normalization contract

Conclusion:

- OpenAI assistant replay differences should mostly be handled as provider-owned policy, not as a reason to widen the shared prompt model

## What The Shared Prompt Model Still Gives Us

The shared prompt model is still valuable because it gives us:

- one common in-memory representation for chat/session logic
- one common compatibility and serialization story
- one place to decide when a feature belongs in core versus provider-owned metadata or custom parts

But it must not be interpreted as:

- “every provider can encode every prompt part”
- “all provider-native replay detail should become common”

## Frozen Rule

When a new prompt part or replay flow is proposed, ask:

1. can at least two primary providers replay it with meaningfully similar semantics?
2. can Flutter/session code treat it the same way?
3. can we test it as a stable normalization contract instead of a provider exception?

If the answer is no, keep it provider-owned.
