# Google Native-Tool Selection Closure

## Purpose

This note closes the remaining active Google TODO around public native-tool
selection or forcing.

The question is no longer whether `llm_dart_google` supports the first real
mixed-tool path.

The question is:

- should that progress now force the repository to expose a public Google
  native-tool selection API
- or is this already a future provider-owned policy question rather than
  current migration debt

## Current State

The current Gemini 3 mixed-tool subset is already implemented enough to prove
the provider-owned contract that matters:

- native Google tools remain provider-owned
- common function tools can now mix with native tools on the audited Gemini 3
  path
- that path is model-gated through
  `includeServerSideToolInvocations`
- assistant-side server-tool replay is preserved through provider-owned custom
  parts and custom events
- multimodal `functionResponse.parts` replay also stays provider-owned

So the repository already has the important architecture outcome:

- the provider package owns the richer Google-native tool circulation contract

## Why A Public Selection API Is Still Not Ready

Even with the mixed-tool subset implemented, the missing part is still not a
shared-core abstraction gap.

The unresolved questions remain provider-owned policy questions, such as:

- which Google-native tool families should participate beyond the audited
  subset
- whether any forcing or selection semantics stay stable across Gemini model
  families
- how Google-native tool policy should interact with model-gated mixed-tool
  circulation
- whether Google will actually document a broader stable selection policy than
  the current model-gated contract

That is not enough to justify a public `GoogleToolSelection` or
`GoogleNativeToolChoice` surface yet.

## Closure Verdict

The active TODO should now close.

Google native-tool selection is no longer an open migration blocker.

It is a future provider-owned policy question that should reopen only if a
concrete Google contract and product need appear together.

## Reopen Threshold

This should only reopen if all of the following become true:

- Google documents or proves a stable native-tool forcing/selection contract
  beyond the current model-gated circulation subset
- the contract applies to a real migrated provider path, not only to a narrow
  experimental edge case
- there is a concrete product need for public selection or forcing
- the resulting API can stay provider-owned and mutually exclusive with shared
  `toolChoice`

Absent that, the current provider-owned options and mixed-tool subset are
enough.

## TODO Consequence

The workstream should therefore:

- close the active TODO about exposing a public Google native-tool selection
  or forcing API
- keep the question documented as future provider-owned policy only

## Bottom Line

Gemini 3 mixed-tool support landing does not mean Google now needs a public
selection API.

It means the provider-owned mixed-tool boundary is now proven enough that the
remaining question can move out of active refactor debt and into future policy.
