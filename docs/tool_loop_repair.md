# Tool Loop Repair Hook (ToolCallRepair)

Status: Draft  
Last updated: 2026-02-10

This document describes the optional **tool call repair hook** for tool loops in
`llm_dart_ai`.

The goal is to keep the default behavior **strict and predictable**, while
providing an **opt-in escape hatch** for "fearless refactors" and messy
provider/model outputs.

---

## Why this exists

Some providers/models can emit malformed tool arguments during streaming, e.g.:

- truncated JSON (`{`)
- markdown code fences around JSON (```json ... ```)
- trailing commas (`{"a": 1,}`)
- smart quotes

By default, `llm_dart_ai` treats these as invalid tool calls and emits an error
tool result without executing any local tool handler.

When you are refactoring or integrating new transports/fixtures, you may prefer
to **repair** the tool arguments best-effort and continue.

---

## API surface

The hook type is:

- `ToolCallRepair` in `llm_dart_ai`

It is accepted by:

- `runToolLoop(...)`
- `runToolLoopUntilBlocked(...)`
- `streamToolLoopParts(...)`
- `executeToolCalls(...)`
- `streamToolLoopPartsWithToolSet(...)`

Important constraints:

- The hook **only repairs `toolCall.function.arguments`** (a JSON string).
- The hook **must not** change tool identity (name/id) and cannot force
  execution of unknown tools.
- After repair, the arguments must still decode to a **JSON object** and pass
  schema validation (when tool definitions are provided), otherwise the tool is
  not executed.

---

## Reasons

`reason` is one of:

- `invalid_json`
- `arguments_not_object`
- `schema_validation_failed`

---

## Recommended usage pattern (opt-in)

Enable repair only when you explicitly want best-effort behavior:

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';

final parts = streamToolLoopParts(
  model: model,
  messages: [ChatMessage.user('hi')],
  tools: tools,
  toolHandlers: handlers,
  repairToolCall: ToolCallRepairStrategies.fixCommonJsonObject(),
);
```

---

## Built-in strategies

`ToolCallRepairStrategies.fixCommonJsonObject()` is intentionally conservative:

- Only attempts repair for `invalid_json` and `arguments_not_object`
- Tries a small set of safe transformations (strip code fences, remove trailing
  commas, replace smart quotes, append a missing `}` when payload looks like an
  object)
- Returns `null` when it cannot recover a JSON object

You can also implement a custom strategy to match your own tolerance and
observability needs.

