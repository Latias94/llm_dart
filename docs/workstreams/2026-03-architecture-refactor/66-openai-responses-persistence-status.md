# OpenAI Responses Persistence Status

## Purpose

This note records what actually landed after the persistence-policy freeze in [61-openai-responses-persistence-policy.md](61-openai-responses-persistence-policy.md).

The goal is to keep the architectural conclusion stable while narrowing the remaining implementation gap against `repo-ref/ai`.

## What Landed

The OpenAI Responses path now implements a minimal provider-owned persistence subset:

- `OpenAIGenerateTextOptions.store`
- `OpenAIGenerateTextOptions.conversation`
- request-body forwarding for `store` and `conversation`
- warning-based conflict detection when `conversation` and `previousResponseId` are both set

The Responses replay encoder now also follows the intended stored-item policy:

- when the effective `store` policy is `true`, replay prefers `item_reference` for preserved OpenAI item IDs
- when `conversation` is set, assistant-side items that already carry OpenAI item IDs are skipped to avoid duplicate-item failures
- when `store` is `false`, the codec reconstructs full replay payloads where the current Dart surface can do so safely

That currently covers these preserved OpenAI-owned item families:

- assistant text messages
- reasoning items
- common function-tool calls
- compaction items
- MCP approval responses

## What Also Changed For Reasoning

`store: false` is not only a request-body flag.

It also changes replay safety:

- reasoning models now automatically opt into `reasoning.encrypted_content`
- reconstructed reasoning replay without encrypted content is warning-dropped when `store` is `false`

This keeps the current Dart replay path aligned with the OpenAI Responses storage contract without widening the shared core.

## What Intentionally Did Not Land

This implementation still keeps the same architectural boundaries:

- no shared `itemReference` prompt abstraction
- no shared stored-conversation abstraction
- no changes to shared `GenerateTextOptions`
- no Flutter/session API expansion just for OpenAI storage semantics

The implementation is intentionally limited to OpenAI-owned invocation options and OpenAI-owned request encoding.

## What Still Remains Open

The remaining OpenAI Responses gap is now narrower than before.

It is mainly about richer OpenAI-native item families that the current Dart provider surface does not model yet, for example:

- hosted or provider-executed tool families that need exact non-function replay reconstruction
- any future OpenAI-native custom tool-call item families
- later model-family quirks that are not just request-shaping compatibility

Those should still stay provider-owned if they are implemented later.

## Bottom Line

The minimal persistence subset is now implemented.

`store`, `conversation`, and `item_reference` remain OpenAI-owned policy, and the shared architecture stays unchanged.
