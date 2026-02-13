# Tool Approvals (AI SDK v3-style)

This document describes best practices for **tool approval flows** in `llm_dart`
when aligning with the Vercel AI SDK v3 semantics.

In this repo, "tool approval" means: the model (or provider) requests
permission to execute a tool call, and the app must approve/deny before the run
can continue.

---

## 1) Two approval modes

### 1.1 Local tool loop approvals (app-executed tools)

When you run a local tool loop (tools executed by your app), the loop can stop
with:

- `ToolApprovalRequiredError`
- `ToolLoopBlockedState`

Recommended server behavior:

- Treat it as a **blocked outcome**, not a fatal error.
- Persist enough state to resume.
- Return an **opaque resume key** to the client (not raw state).

### 1.2 Provider-executed tool approvals (provider/server-side tools)

Some providers can execute tools server-side (e.g. MCP tools) and may emit
approval requests while streaming.

In that case streaming can stop with:

- `ProviderToolApprovalRequiredError`
- `ProviderToolApprovalBlockedState`

Recommended server behavior:

- Enable "stop on approval request" when you want explicit persistence/resume.
- Persist the prompt IR + requests + partial assistant output.
- Return an opaque resume key to the client.

---

## 2) Persistence strategy (recommended)

### 2.1 Do not send raw state to the browser

Both blocked states can include user messages, tool inputs, and provider
metadata. Avoid returning them directly to the client.

Instead:

1) Persist the blocked state server-side (DB/kv/cache)
2) Return a `resumeKey` (string) to the client
3) On resume, load state by `resumeKey`, apply decisions, continue

### 2.2 Store prompt IR, not legacy messages

Provider approvals rely on Prompt IR to replay `tool-approval-response` parts.
Prefer persisting:

- `Prompt` (prompt IR)
- decisions (approvalId -> approved/reason)

The prompt IR now supports:

- `ToolApprovalRequestPart` (assistant content)
- `ToolApprovalResponsePart` (tool role)

This makes history self-contained and compatible with the v3 prompt codec.

### 2.3 Collect approvals from history (optional)

If you persist prompt IR across requests, you can analyze or validate approvals
with:

- `collectToolApprovalsFromPrompt(prompt)`

This mirrors the AI SDK `collectToolApprovals` intent:
match `tool-approval-response` from the last tool message to the prior
assistant `tool-approval-request` and the corresponding `tool-call`.

---

## 3) Resume mechanics

### 3.1 Resuming local tool loop approvals

High-level flow:

1) Run tool loop until blocked
2) Ask user to approve/deny tool calls
3) Resume from `ToolLoopBlockedState` with decisions

This is represented as a structured blocked state, similar to AI SDK behavior.

### 3.2 Resuming provider tool approvals (streaming)

High-level flow:

1) Stream with `stopOnProviderToolApprovalRequests: true`
2) When blocked, persist `ProviderToolApprovalBlockedState` and return `resumeKey`
3) On resume, load state, build decisions, then call:
   - `resumeChatPartsAfterProviderToolApprovalRequired(...)`

---

## 4) UI message stream (SSE) integration

### 4.1 Prefer a unified "blocked" chunk + abort

When the run is blocked, the UI stream should:

1) Emit `tool-approval-request` chunks (one per requested approval)
2) Emit a structured blocked payload chunk (optional)
3) Emit `abort` to end the stream

`llm_dart_ai` supports three related chunk types:

- `data-tool-blocked` (unified)
- `data-tool-loop-blocked` (local tool loop)
- `data-tool-approval-blocked` (provider tool approvals)

All three share the same normalized `data` shape:

```json
{
  "kind": "tool-loop | provider-tool-approval",
  "stepIndex": 0,
  "approvalIds": ["..."],
  "toolCallIds": ["..."],
  "extra": { "...": "app-defined payload" }
}
```

### 4.2 Use `extra` to return an opaque resume key

When encoding SSE, attach an opaque key via:

- `toolApprovalBlockedStateData: (state) => { 'resumeKey': ... }`
- `providerToolApprovalBlockedStateData: (state) => { 'resumeKey': ... }`

Do not include the full prompt or tool inputs in `extra`.

---

## 5) Operational notes

- Validate decisions: ensure every requested `approvalId` is answered.
- Use `maxSteps`/`providerToolApprovalMaxSteps` to bound loops.
- Consider expiring `resumeKey` records (TTL) and authenticating resume calls.
- Redact PII before persistence if you store prompt IR or provider metadata.

