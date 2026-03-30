# Phind Legacy Compatibility Audit

## Goal

This note freezes the current Phind compatibility position after the OpenAI-family chat-completions mainline landed in `llm_dart_openai`.

The goal is not to define a first bridge-safe subset.

The goal is to record why no Phind legacy subset should be assumed bridge-safe today.

## 1. Current Legacy Phind Surface

The old root Phind provider does not behave like a normal OpenAI-compatible chat-completions client.

Its current request behavior includes:

- endpoint: the base URL root with an empty relative path
- request fields:
  - `additional_extension_context`
  - `allow_magic_buttons`
  - `is_vscode_extension`
  - `message_history`
  - `requested_model`
  - `user_input`
- system prompt injection by prepending a synthetic `system` entry into `message_history`

The old provider also carries additional protocol quirks:

- non-streaming requests still receive a streaming-style text response that the client reparses locally
- the provider advertises tool-related configuration in shared config types, but the old Phind chat path explicitly says tools are not supported
- the default legacy base URL still points to a historical extension-style endpoint, not a standard `/v1/chat/completions` shape

So the old Phind provider is not merely a different profile on top of the same request contract.

It is a different request-and-response protocol.

## 2. Current Refactored Package Coverage

The refactored `llm_dart_openai` package now exposes a `PhindProfile` through the new `AI.phind(...)` facade.

That gives the architecture a place to host a future Phind-compatible direct path.

But current package coverage does **not** establish legacy compatibility.

Current gaps relative to the old Phind provider include:

- no request codec for `message_history` / `requested_model` / `user_input`
- no mapping for the extension-oriented request flags that the old provider always sends
- no replay of the old streaming-response parsing contract
- no evidence that the new default Phind profile endpoint is semantically equivalent to the old extension-style endpoint
- no reason to auto-preserve tools or structured output on a provider whose old path does not actually support common tool calling

So the current refactored package gives us a facade constructor, not a migrated legacy bridge path.

## 3. Bridge-Risk Inventory

### Safe enough today for direct facade experimentation only

- explicit new-facade usage where callers intentionally target the refactored Phind profile path
- provider experiments that do not claim parity with the old root Phind provider

### Not bridge-safe today for automatic legacy routing

- any legacy Phind chat request at all

That includes:

- plain text prompts
- tool declarations
- tool replay
- structured output
- streaming
- system-prompt shaping

Because even the base request body and response parsing contract are different.

## 4. Current Routing Recommendation

Phind should stay out of the compatibility resolver.

Current routing rule:

- `AI.phind(...)` may continue to exist as a facade constructor for the refactored architecture
- `LLMBuilder.build()` should keep returning the old `PhindProvider`
- no automatic legacy request should route into the new OpenAI-family bridge today

This is not temporary wording for a nearly-finished subset.

This is the explicit current policy.

## 5. Follow-Up Work Needed Before Reconsideration

1. Decide whether Phind should stay a dedicated provider path instead of an OpenAI-family compatibility target.
2. Re-audit the real current Phind endpoint and protocol contract before assuming the new `PhindProfile` defaults represent the old provider semantics.
3. Decide whether any narrow legacy subset is worth bridging at all, given the protocol mismatch and the old provider's lack of real tool support.
4. Keep the existing compatibility test expectation that Phind remains on the legacy implementation.

## 6. Current Conclusion

Phind has crossed:

- the facade-constructor threshold

Phind has **not** crossed:

- the legacy-compatibility-routing threshold
- the legacy-request-shape-audit threshold for any bridge-safe subset

So the correct current state is:

- facade constructor: yes
- automatic legacy compatibility route: no

The next safe step is not to add a Phind subset optimistically.

The next safe step is to decide whether Phind belongs in a dedicated provider path instead of the OpenAI-family compatibility bridge.
