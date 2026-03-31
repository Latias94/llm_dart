# OpenAI Assistant Replay Alignment

## Purpose

This note audits the current OpenAI-family assistant replay behavior against `repo-ref/ai`.

The goal is to distinguish:

- intentional warning-based boundaries
- real implementation gaps

Without that distinction, OpenAI replay work risks drifting into a bus-layer rewrite.

## Chat-Completions Alignment

The reference `convert-to-openai-chat-messages.ts` only replays these assistant parts on the chat-completions path:

- assistant text
- assistant common tool calls

It does not project assistant-side:

- reasoning parts
- image parts
- file parts
- provider-native approval items
- provider-executed provider-native tool results

The migrated `llm_dart_openai` chat-completions codec matches that boundary:

- assistant `TextPromptPart` is replayed
- assistant common `ToolCallPromptPart` is replayed
- provider-executed or dynamic tool calls are warning-dropped
- reasoning, reasoning-file, custom, image, file, approval, and assistant-side tool-result parts are warning-dropped

Conclusion:

- the current warning surface on chat-completions is mostly alignment, not drift
- removing those warnings without a new wire-level contract would reduce fidelity, not improve it

## Responses Alignment

The reference `convert-to-openai-responses-input.ts` is materially richer on the Responses path.

It supports assistant replay for:

- assistant text
- assistant reasoning summaries with encrypted content
- common function tool calls
- provider-executed/provider-native tool-output families through provider-owned item types
- approval-oriented provider-native item families
- item references when item IDs and storage semantics are available

The migrated `llm_dart_openai` Responses codec already covers:

- assistant text replay with provider-owned metadata
- assistant reasoning replay with provider-owned metadata
- common function tool-call replay
- common tool-result replay
- provider-owned MCP approval and MCP call replay families
- OpenAI compaction replay metadata

The main differences versus the reference are:

- no `item_reference` optimization path
- no generalized provider-owned OpenAI custom tool-call/output families beyond the currently implemented subset
- no exposed shared/store-level switch that would let the codec choose between full replay and item references

Conclusion:

- the remaining Responses gap is mostly provider-owned optimization and richer OpenAI-native item coverage
- it is not a shared-core abstraction gap

## What Is Intentionally Still Unsupported

The following remain intentionally outside the stable shared replay contract:

- assistant multimodal replay on chat-completions
- assistant reasoning replay on chat-completions
- approval-gated continuation on chat-completions
- broad OpenAI-native item-family parity on Responses before a concrete use case appears
- store-aware item-reference replay until the library has an explicit OpenAI-owned conversation/storage policy

## Recommended Direction

The OpenAI replay workstream should now prefer this order:

1. keep chat-completions assistant replay narrow and explicit
2. add provider-owned OpenAI hints or item families only when they correspond to real OpenAI wire contracts
3. avoid widening the shared prompt model just to encode OpenAI-specific replay optimizations

## Bottom Line

The current OpenAI assistant replay warnings are no longer the main migration blocker.

The more valuable remaining work is:

- auditing whether any additional OpenAI-owned item families deserve provider-owned support
- deciding whether OpenAI Responses should ever expose an explicit item-reference optimization policy
