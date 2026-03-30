# DeepSeek Legacy Compatibility Audit

## Goal

This note freezes the current DeepSeek compatibility position after the initial OpenAI-family chat-completions mainline landed in `llm_dart_openai`.

The question is no longer whether the refactored package can execute DeepSeek at all.

It can.

The real question is narrower:

- which legacy DeepSeek request shapes are already bridge-safe
- which ones still require fallback to the old provider
- what the first acceptable compatibility subset should be

## 1. Current Legacy DeepSeek Surface

The old root DeepSeek provider is not just a plain OpenAI-compatible alias.

Its current request behavior includes:

- endpoint: `chat/completions`
- models: `deepseek-chat` and `deepseek-reasoner`
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
- DeepSeek-specific extension fields:
  - `logprobs`
  - `top_logprobs`
  - `frequency_penalty`
  - `presence_penalty`
  - raw `response_format`

The old provider also carries DeepSeek-specific behavior:

- it removes `reasoning_content` from replayed input messages because DeepSeek rejects that field in the prompt
- it treats `deepseek-reasoner` as a special model family with parameter restrictions
- it emits legacy thinking deltas from `reasoning_content` and from `<think>...</think>` content

## 2. Current Refactored Package Coverage

The refactored `llm_dart_openai` package now provides a usable DeepSeek direct path through the OpenAI-family chat-completions mainline.

Current direct-package coverage includes:

- text generation
- streaming text deltas
- reasoning extraction from `reasoning_content`
- reasoning extraction from `<think>...</think>` content
- common function tools
- tool choice
- streamed tool-call aggregation
- typed JSON-schema response format
- OpenAI-family profiles with provider-owned metadata namespaces

Current gaps relative to the old DeepSeek provider still include:

- no typed DeepSeek invocation options for `logprobs`
- no typed DeepSeek invocation options for `top_logprobs`
- no typed DeepSeek invocation options for `frequency_penalty`
- no typed DeepSeek invocation options for `presence_penalty`
- no explicit model-aware gating for `deepseek-reasoner` restrictions
- no frozen mapping from the old raw `response_format` extension to the new typed response-format contract

This means the package mainline exists, but the legacy DeepSeek bridge is still incomplete.

## 3. Bridge-Risk Inventory

### Safe enough today for direct package execution

- plain text prompts
- common assistant text output
- reasoning extraction from provider output
- common function tools and tool results
- OpenAI-compatible chat-completions streaming

### Not bridge-safe yet for automatic legacy routing

- `deepseek-reasoner` requests without a frozen model-aware restriction policy
- any request using DeepSeek-specific extensions:
  - `logprobs`
  - `top_logprobs`
  - `frequency_penalty`
  - `presence_penalty`
  - raw `response_format`
- any request that depends on legacy message decorators or replay semantics not representable by the current chat-completions codec without warnings

### Why `deepseek-reasoner` is still special

The old provider explicitly knows that:

- `logprobs` and `top_logprobs` should not be sent to `deepseek-reasoner`
- `temperature`, `top_p`, `presence_penalty`, and `frequency_penalty` are ineffective for `deepseek-reasoner`
- prompt-side `reasoning_content` must be stripped

The new package currently covers only the output-side reasoning path cleanly.

It does not yet freeze the request-side restriction policy for compatibility routing.

So `deepseek-reasoner` should stay off the compatibility bridge for now.

## 4. Proposed Bridge-Safe Subset V1

The first acceptable DeepSeek compatibility subset should be intentionally small:

- provider: `deepseek`
- model: `deepseek-chat` only
- prompt shape:
  - system text
  - user text
  - assistant text
  - assistant common function tool calls
  - tool results for common function tools
- common request controls:
  - `maxTokens`
  - `temperature`
  - `topP`
  - `topK`
- common tool support:
  - common function tools only
  - common `ToolChoice`

The first subset should explicitly exclude:

- `deepseek-reasoner`
- raw DeepSeek extension fields
- provider-native or approval-style tool semantics
- replay shapes that already produce compatibility warnings in the current chat-completions codec

## 5. Routing Rule Recommendation

The DeepSeek subset V1 is now the active compatibility rule.

Current routing rule:

- if the request matches the DeepSeek subset V1 exactly, it routes to `llm_dart_openai` with `DeepSeekProfile`
- otherwise it stays on the legacy DeepSeek provider path automatically

This is intentionally a per-request rule, not a provider-wide declaration that all DeepSeek legacy traffic is now bridge-safe.

## 6. Follow-Up Work Needed Before Routing

1. Freeze whether legacy structured output should map only through the shared typed JSON-schema path, or whether raw DeepSeek `response_format` must remain fallback-only.
2. Decide whether `deepseek-reasoner` deserves a separate bridge profile later, or should remain legacy-only until request-side restriction handling is explicit.
3. Keep compatibility tests that prove:
   - `deepseek-chat` text-only requests route safely
   - common function tools route safely
   - all DeepSeek-specific extensions force fallback
   - `deepseek-reasoner` forces fallback

## 7. Current Conclusion

DeepSeek has now crossed both:

- the package-mainline threshold
- the initial compatibility-routing threshold for subset V1 only

That is still a conservative intermediate state, not full DeepSeek migration.

The next safe step is to expand only one additional audited subset at a time.
