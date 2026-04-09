# 140. Root OpenAI Chat Bridge Slice

## Scope

Narrow the public root `OpenAIProvider` chat ownership without removing the
public compatibility shell.

This slice only targets the official OpenAI-hosted root path:

- `OpenAIProvider`
- `createOpenAIProvider(...)`
- `OpenAIConfig(baseUrl: 'https://api.openai.com/v1/...')`

It does **not** widen the bridge yet for:

- Azure-style endpoints
- OpenRouter/Groq/DeepSeek/Together/GitHub Copilot preset-style base URLs
- arbitrary custom OpenAI-compatible proxies

## What Changed

The root compatibility provider now delegates `chat`, `chatWithTools`, and
`chatStream` through the same modern `llm_dart_openai` projection layer that
the broader compatibility bridge already uses when all of these are true:

- the request targets the official OpenAI host
- the request remains inside `canUseOpenAIChatBridge(...)`
- the bridge projection succeeds without a compatibility-mapping error

Implementation details:

- `lib/src/compatibility/providers/openai/bridge_support.dart`
  centralizes OpenAI chat-bridge construction and OpenAI built-in tool mapping
- `lib/src/compatibility/providers/openai/provider_compat.dart`
  now tries the modern bridge first for the root provider chat path
- `lib/src/compatibility/providers/openai_family_compat_provider.dart`
  reuses the same helper so the root-provider slice and compatibility-provider
  slice do not drift again

## Important Behavioral Boundary

The internal chat bridge now prefers the modern OpenAI Responses mainline for
the official OpenAI-hosted subset even when the public compatibility config has
`useResponsesAPI: false`.

That is intentional.

`useResponsesAPI` still matters for the residual public compatibility surface:

- the `responses` getter
- raw Responses lifecycle helpers
- fallback behavior when a request is outside the bridge-safe subset

But the bridged text path is now allowed to converge on one modern request and
stream implementation source instead of preserving two long-term internal chat
stacks.

## Why This Is Better

This removes a high-value duplication seam:

- root `OpenAIProvider` no longer needs to be the long-term owner of yet
  another OpenAI chat request/stream implementation for the audited subset
- OpenAI stream and request behavior now converges more directly on the modern
  package-owned mainline
- residual root-only APIs remain available without blocking chat ownership
  narrowing

## Regression Coverage Added

- structured output through the root provider bridge
- user image/file replay through the root provider bridge
- common function-tool replay through the root provider bridge
- streaming text events through the root provider bridge
- residual `responses` getter behavior remains separate from chat delegation

## Deliberately Deferred

The next widening question is still separate:

> Should deprecated root OpenAI-compatible preset helpers gain their own
> profile-specific modern bridge path, or should they remain fallback-only
> while users continue migrating to provider-owned modern packages?

This slice keeps that answer open and only narrows the official OpenAI-hosted
root path first.
