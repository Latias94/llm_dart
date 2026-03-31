# Google Mixed-Tool Migration Design

## Goal

This note freezes the current Gemini 3 mixed-tool direction after the first
provider-owned subset has already landed in `llm_dart_google`.

The specific problem is:

> Official Gemini 3 `generateContent` can combine built-in Google tools and
> function declarations, but that contract only works when server-side tool
> invocations are circulated and replayed faithfully.

The goal of this note is no longer to describe a hypothetical migration from
zero. The goal is to record what is now implemented, what remains intentionally
conservative, and which boundaries must still stay Google-owned.

## Frozen Conclusion

- Google native tools remain provider-owned
- `llm_dart_google` now supports a provider-owned Gemini 3 mixed-tool subset
- that subset combines native Google tools and common function tools in one
  request when `includeServerSideToolInvocations` is enabled
- assistant-side Google server `toolCall` / `toolResponse` replay now round-
  trips through provider-owned custom parts instead of widening shared events
- multimodal Google `functionResponse.parts` replay now also stays
  provider-owned through a typed helper
- non-Gemini-3 models still reject `includeServerSideToolInvocations`
- calls outside the implemented Gemini 3 subset still keep the conservative
  warning-based downgrade path
- no shared `ToolChoice`, shared runner, or shared event widening is justified

## 1. Official Gemini 3 Contract Signals

The relevant official Google contract signals remain:

- Gemini 3 `generateContent` can combine built-in tools and function calling
  in one request
- this path requires `toolConfig.includeServerSideToolInvocations = true`
- follow-up turns must preserve server-side tool context instead of replaying
  only common function-call history
- Google still treats this as a model-family-specific contract rather than a
  generic cross-provider tool abstraction

That means the real problem was never "merge two tool lists".

It was:

- request declaration
- tool-circulation policy
- assistant-side server-tool replay
- multimodal function-response replay
- follow-up prompt fidelity

as one provider-owned contract.

## 2. Implemented Provider-Owned Subset

## Request Declaration

The current Google codec now supports the audited Gemini 3 subset:

- native Google tools still come from `GoogleChatModelSettings.tools` or
  `GoogleGenerateTextOptions.tools`
- common function tools still come from the shared `GenerateTextRequest.tools`
  path
- when the model is Gemini 3 and
  `includeServerSideToolInvocations == true`, the request can now encode:
  - native Google tool entries
  - plus one `functionDeclarations` tool entry
  - plus `toolConfig.includeServerSideToolInvocations = true`
  - plus shared `functionCallingConfig` for the common function-tool subset

Outside that subset:

- non-Gemini-3 models reject `includeServerSideToolInvocations`
- native-tool calls without the circulation flag still warning-drop shared
  function tools and shared `toolChoice`

## Replay And Follow-Up Encoding

Several replay slices are now implemented:

- provider-originated Gemini 3 `functionCall.id` values now survive result
  decode, shared-runner continuation, and request replay
- `google.result.function_response` now preserves exact Google
  `functionResponse` payloads, including multimodal `functionResponse.parts`
- `google.result.tool_call` now preserves assistant-side server `toolCall`
  payloads
- `google.result.tool_response` now preserves assistant-side server
  `toolResponse` payloads
- follow-up requests that replay Google server `toolCall` / `toolResponse`
  parts now require `includeServerSideToolInvocations = true`

This keeps replay fidelity provider-owned instead of widening:

- shared `ToolResultPromptPart`
- shared `ToolResultEvent`
- shared `ToolUiPart`

with Google-only server-tool structure.

## Result And Stream Decode

The current Google result and stream codecs now decode assistant-side server
tool circulation into provider-owned payloads:

- result decode maps Google `toolCall` / `toolResponse` blocks into
  `CustomContentPart`
- stream decode maps Google `toolCall` / `toolResponse` blocks into
  `CustomEvent`
- those provider-owned payloads can already flow through Flutter/session replay
  without changing the shared event model

## 3. What Remains Intentionally Conservative

The Google path is broader than before, but it is still intentionally bounded.

The following rules remain conservative by design:

- `includeServerSideToolInvocations` is still rejected for non-Gemini-3 models
- the mixed-tool path is enabled only through Google-owned options
- shared `ToolChoice` still expresses only common function-tool policy
- there is still no public Google native-tool forcing or selection API
- calls outside the audited Gemini 3 subset still keep warning-based downgrade
  instead of pretending broader normalization exists

That is the correct boundary. The new landed subset is provider-owned
capability, not a reason to widen the shared core.

## 4. Remaining Gaps

The major remaining Google questions are now narrower:

- whether any Google-native tool families beyond the audited search/code-
  execution subset should enter the migrated provider path next
- whether Flutter should later gain dedicated renderer helpers for
  `google.result.tool_call` / `google.result.tool_response`
- whether a concrete Google-native selection or forcing requirement appears
  that justifies a provider-owned policy API
- whether Google documents any broader stable mixed-tool policy beyond the
  current model-gated Gemini 3 contract

These are provider-owned questions. They are not evidence that the shared core
is missing another abstraction.

## 5. Shared Boundary Impact

The current implementation confirms the broader architecture decisions:

- shared `ToolChoice` stays small
- shared runner stays limited to app-supplied common function tools
- provider-native server-tool circulation stays provider-owned
- provider-owned custom parts remain the right replay boundary
- Flutter chat/session should consume these richer payloads through provider-
  owned rendering or adapters, not through new Google-specific shared events

This is the main lesson worth keeping from `repo-ref/ai`:

- put the rich provider contract in the provider package

not:

- widen the shared contract until every provider-specific tool lifecycle looks
  common

## 6. Recommended Next Steps

1. Keep the Gemini 3 mixed-tool subset regression-tested at request, decode,
   and replay boundaries.
2. Add more Flutter/session end-to-end coverage for provider-owned Google
   server-tool replay.
3. Decide whether Google server-tool custom parts need dedicated renderer
   helpers before considering any shared projection.
4. Revisit public Google native-tool selection only if a concrete provider
   policy need appears.
5. Extend Google native-tool coverage only when the official contract and test
   evidence are equally clear.

## Conclusion

The Google direction is now frozen more precisely:

- Gemini 3 mixed-tool support is real and partially implemented
- the implemented path stays provider-owned and model-gated
- server-side tool replay and multimodal function-response replay now have
  concrete provider-owned contracts
- the remaining work is policy coverage and renderer maturity, not wider shared
  abstraction

That is the correct architecture boundary for the current breaking refactor.
