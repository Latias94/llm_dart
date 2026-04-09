# 141. Root OpenAI-Compatible Helper Bridge Policy

## Question

After narrowing the official root `OpenAIProvider` chat path onto the modern
OpenAI bridge, should the deprecated root OpenAI-compatible preset helpers also
gain profile-specific modern bridge paths?

Examples:

- `createOpenRouterProvider(...)`
- `createGroqProvider(...)`
- `createDeepSeekProvider(...)`
- `createAzureOpenAIProvider(...)`
- `createCopilotProvider(...)`
- `createTogetherProvider(...)`

## What Was Reviewed

- `lib/providers/openai/openai.dart`
- `lib/src/compatibility/providers/openai/provider_compat.dart`
- `lib/src/compatibility/providers/openai/bridge_support.dart`
- `packages/llm_dart_openai/lib/src/openai_family_profile.dart`
- `docs/workstreams/2026-03-architecture-refactor/136-openai-public-compatibility-api-policy.md`
- `docs/workstreams/2026-03-architecture-refactor/139-root-openai-chat-hosting-gap.md`
- `docs/workstreams/2026-03-architecture-refactor/140-root-openai-chat-bridge-slice.md`

## Decision

No.

The deprecated root OpenAI-compatible preset helpers should remain
compatibility-only aliases and stay on the fallback path.

They should **not** gain new profile-specific modern bridge ownership inside
the root package.

## Why

### 1. They are deprecated constructor aliases, not real architecture boundaries

These helpers mostly pre-fill:

- `baseUrl`
- `model`
- endpoint-style URL shaping

before returning the same old root compatibility shell.

That is not enough to justify a new long-term bridge branch in the root
package.

### 2. Their modern home already exists somewhere else

For the OpenAI-family providers that already have package-owned modern profiles,
the intended migration direction is:

- `AI.openRouter(...).chatModel(...)`
- `AI.groq(...).chatModel(...)`
- `AI.deepSeek(...).chatModel(...)`

not another round of root-hosted bridge specialization.

For endpoint-style OpenAI-compatible services such as Azure, Together, or
Copilot, the migrated text path can still use:

- `AI.openai(...).chatModel(...)`

with explicit `baseUrl` and model settings when only modern text behavior is
needed.

### 3. The root package still mainly adds residual compatibility APIs

The reason the root OpenAI shell still exists is not to become a permanent
profile host for every OpenAI-compatible service.

It still exists because it carries residual compatibility surface such as:

- Responses lifecycle helpers
- file management
- moderation
- assistants
- legacy completion

That makes it the wrong place to keep widening modern profile-aware chat
ownership.

### 4. Official OpenAI was the highest-value narrowing target

The official OpenAI host was the right first narrowing slice because:

- it is the primary OpenAI text path
- it already has the most complete modern package support
- it removes the most duplication immediately

The deprecated helper constructors do not offer the same return on complexity.

## Practical Result

The root bridge gate stays intentionally narrow:

- official `api.openai.com` requests may use the modern root chat bridge
- deprecated OpenAI-compatible preset helpers remain on the compatibility
  fallback path

This keeps the architecture honest:

- modern profile-aware chat lives in provider-owned packages
- root preset helpers stay migration aids only

## Revisit Threshold

This decision should only be revisited if a concrete product need appears where:

- a deprecated helper still has material real-world usage
- the required behavior cannot be expressed through the provider-owned modern
  package surface
- and the value is large enough to justify one more root-hosted bridge branch

Until then, fallback-only is the cleaner policy.
