# 159 OpenAI Provider Chat Facade

## Why

After the OpenAI compatibility request-body and stream-parsing cleanup, the
next residual structural weight in the root OpenAI compatibility layer sat in
`OpenAIProvider` itself.

The provider shell still directly owned:

- root OpenAI bridge enablement checks,
- bridge config creation,
- bridge adapter creation,
- bridge-or-fallback routing for chat requests,
- bridge-or-fallback routing for chat streams,
- Responses-vs-chat fallback selection for chat-oriented helper methods.

That logic is compatibility plumbing, not public provider behavior. Leaving it
inside `OpenAIProvider` kept the root provider shell heavier than it needs to
be and blurred the boundary between:

- capability composition,
- compatibility chat routing,
- and the actual capability implementations.

## Decision

Move the remaining root OpenAI chat bridge and fallback routing into a focused
local facade:

- `OpenAIProvider` keeps owning capability composition and public delegation,
- `OpenAIProviderChatFacade` owns bridge wiring plus chat fallback routing,
- the concrete chat implementations still stay in `OpenAIChat` and
  `OpenAIResponses`.

This is intentionally local to the OpenAI compatibility family. It does not add
another repository-wide abstraction.

## What Changed

- Added
  `lib/src/compatibility/providers/openai/provider_chat_facade.dart`
  containing:
  - bridge support wiring,
  - bridge-or-fallback chat routing,
  - bridge-or-fallback stream routing,
  - Responses-vs-chat fallback selection,
  - the official-host bridge host check.
- Removed bridge-specific routing fields and helper methods from
  `OpenAIProvider`.
- Simplified the root provider shell so the chat-facing public methods now just
  delegate into the local facade.
- Kept all existing bridge behavior and Responses getter semantics unchanged.

## Architectural Effect

This moves the root OpenAI compatibility layer closer to the intended shape:

- `OpenAIProvider` becomes more obviously a capability-composition shell,
- provider-local routing mechanics live in a dedicated compatibility helper,
- actual request encoding and stream parsing stay in the lower capability
  modules.

That is a healthier internal split than letting the root provider continue to
accumulate bridge and fallback logic directly.

It also makes the next cleanup more straightforward: future OpenAI
compatibility work can focus on remaining facade weight or legacy-only helper
surfaces without reopening the already-shrunk request and stream internals.
