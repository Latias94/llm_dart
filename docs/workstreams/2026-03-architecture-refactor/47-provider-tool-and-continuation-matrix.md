# Provider Tool And Continuation Matrix

## Goal

This note freezes the currently audited provider behavior for tool declaration,
tool replay, approval continuation, and multi-step ownership.

The core question is:

> After the shared runner boundary has been frozen, what does each provider
> family actually support today, and which parts must remain provider-owned?

This note is intentionally concrete. It describes the behavior that already
exists in the migrated provider packages instead of proposing a hypothetical
uniform tool runtime.

## Frozen Conclusion

- there is no honest shared continuation contract beyond common function tools
- OpenAI Responses remains the richest provider-owned continuation path
- OpenAI chat-completions remains a function-tool-only mainline with explicit
  rejection or warning-based downgrade for Responses-only semantics
- Anthropic can mix common and native tool declarations in one request, but
  provider-executed MCP/native continuation remains provider-owned
- Google native tools remain provider-owned and effectively exclusive for a
  given call today
- provider-native tool forcing or selection APIs must stay provider-owned
  instead of widening shared `ToolChoice`

## 1. Shared Baseline

The stable shared baseline across providers remains:

- common `FunctionToolDefinition`
- shared `ToolChoice`
- shared tool call and tool result content models
- shared `providerExecuted` marker on decoded tool calls and tool results
- the narrow shared `GenerateTextRunner` for app-supplied common function-tool
  continuation only

What the shared baseline does not promise:

- provider-native tool declaration
- provider-native tool selection or forcing
- approval-aware continuation
- provider-hosted execution lifecycles
- dynamic or schema-less tool families

## 2. OpenAI Family

## OpenAI Responses

Current behavior:

- supports common function tools
- supports OpenAI built-in tools through provider-owned options
- supports `previous_response_id`
- decodes provider-executed approval requests and MCP-oriented continuation into
  shared tool call, approval, and tool result content/events
- re-encodes approval continuation through Responses-specific input items such
  as approval responses

Ownership verdict:

- keep this path provider-owned
- shared runner must not try to absorb built-in tool or approval continuation
  that depends on Responses-specific request items

## OpenAI Chat Completions

Current behavior:

- supports common function tools
- rejects Responses-only provider options such as `previousResponseId`
- rejects OpenAI built-in tools before sending
- replays only the chat-completions-safe subset of assistant and tool history
- warning-drops provider-executed or dynamic tool calls during replay
- warning-drops provider-native MCP tool results during replay
- warning-drops approval response replay during chat-completions request
  encoding

Ownership verdict:

- this mainline remains intentionally narrower than Responses
- provider-native continuation must not be normalized into chat-completions just
  to simulate parity

## OpenAI-Family Implication

The OpenAI family already proves why one shared tool contract is not enough:

- one provider family exposes both a narrow function-tool path
  (chat-completions)
- and a richer provider-owned continuation path (Responses)

That difference should stay explicit in provider code and migration guidance.

## 3. Anthropic

Current behavior:

- common function tools and Anthropic native tools are encoded into one
  request-side `tools` array
- common `AutoToolChoice` and `RequiredToolChoice` can apply across that mixed
  request-side set
- `SpecificToolChoice` remains stable only for common function tools in phase 1
- assistant replay preserves provider-executed `server_tool_use` and
  `mcp_tool_use` blocks when prompt history already contains them
- provider-native result families such as MCP, web fetch/search, and code
  execution remain provider-owned through provider metadata and custom-part
  contracts
- approval response replay is intentionally not elevated into a shared runner
  contract

Ownership verdict:

- Anthropic can share more request-side declaration shape than Google
- but its provider-executed continuation and native result families still stay
  provider-owned

## Anthropic Gap That Must Stay Provider-Owned

The remaining gap is not a shared `ToolChoice` problem.

It is a provider-owned API problem:

- if Anthropic later needs native-tool forcing or selection beyond the current
  shared subset, that should be a typed Anthropic option surface
- it should not widen shared `ToolChoice`

## 4. Google

Current behavior:

- common function tools map into Google `functionDeclarations`
- common `ToolChoice` maps into `toolConfig.functionCallingConfig`
- Google native tools are declared through provider-owned options
- when Google native tools are active, common function tools are ignored for the
  call
- when Google native tools are active, shared `toolChoice` is also ignored for
  the call
- the codec emits warnings instead of pretending mixed native and shared tool
  behavior is fully normalized
- provider-executed native tool results such as code execution still decode into
  shared provider-executed tool content/events for rendering and replay

Ownership verdict:

- Google native tools stay provider-owned and effectively exclusive today
- the current warning-based downgrade is intentional and should not be hidden
  behind a fake shared abstraction

## Google Gap That Must Stay Provider-Owned

If Google later needs:

- native-tool forcing
- native-tool selection rules
- mixed native-tool and function-tool policy

those must land in Google-owned option surfaces, not in shared `ToolChoice` or
the shared runner.

## 5. What `repo-ref/ai` Changes In Comparison

The reference SDK can expose a broader orchestration surface because it owns
more of the loop in one runtime:

- tool execution
- approval handling
- stop policy
- step mutation
- stream stitching

`llm_dart` should copy the placement lesson, not the breadth:

- keep common function-tool continuation shared
- keep provider-native continuation provider-owned
- keep chat-interactive continuation in `llm_dart_flutter`

## 6. Cross-Provider Matrix

## Shared Runner Eligible Today

- common function tools with app-supplied execution

## Provider-Owned Today

- OpenAI Responses built-in tools and approval continuation
- Anthropic MCP and other provider-executed native tool families
- Anthropic provider-native replay/result families
- Google native search/code-execution tool declaration and policy

## Warning-Based Downgrade Instead Of Normalization

- OpenAI chat-completions replay of provider-executed, dynamic, MCP, and
  approval-specific continuation
- Google mixed native-tool and shared function-tool request policy

## 7. Recommended Next Provider-Owned Work

The next provider-facing design work should stay provider-owned:

- provider-native tool forcing or selection APIs
- broader Anthropic native tool coverage
- broader Google native tool policy coverage
- OpenAI Responses helper APIs around provider-owned continuation families

The next work should not be:

- widening shared `ToolChoice`
- widening the shared runner to own provider-native continuation
- pretending provider-native approvals are just another common tool result loop

## Conclusion

The current provider matrix is now explicit:

- OpenAI Responses is rich and provider-owned
- OpenAI chat-completions is narrower and intentionally so
- Anthropic mixes declarations more easily than Google, but native continuation
  still stays provider-owned
- Google native tools remain exclusive and warning-driven when mixed with common
  tool configuration

That is the correct shape for `llm_dart`.

The next step is not more shared abstraction.

It is clearer provider-owned APIs where provider-native tool selection,
approval, and continuation semantics really belong.
