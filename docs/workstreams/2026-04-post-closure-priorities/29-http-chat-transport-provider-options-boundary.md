# 29 HTTP Chat Transport Provider-Options Boundary

## Why This Note Exists

One remaining design pressure comes from Flutter and other chat-app clients
that want backend transport plus provider-specific behavior.

At first glance, that can make it tempting to push raw
`CallOptions.providerOptions` through `HttpChatTransport`.

This note re-checks that temptation against the current `llm_dart` layering and
against the local `repo-ref/ai` reference design.

## Reference Observation From `repo-ref/ai`

The local reference repository keeps the generic chat transport intentionally
small:

- `repo-ref/ai/packages/ai/src/ui/chat.ts`
  - chat request options are `headers`, `body`, and `metadata`
- `repo-ref/ai/packages/ai/src/ui/http-chat-transport.ts`
  - the generic HTTP transport merges those request fields and leaves provider
    execution details to the backend/API layer

That is the important lesson to borrow.

The useful pattern is **not** “serialize every model invocation option through
the generic chat transport.” The useful pattern is to keep the generic transport
app-owned and backend-friendly.

## Current `llm_dart` Facts

Today:

- `ChatRequestOptions` contains `generateOptions`, `callOptions`, and
  `metadata`
- `HttpChatTransportRequestPayload` serializes:
  - prompt
  - `GenerateTextOptions`
  - stream protocol
  - app-owned `metadata`
- `HttpChatTransport` intentionally rejects:
  - `CallOptions.timeout`
  - `CallOptions.headers`
  - `CallOptions.providerOptions`

That means the current implementation is already pointing toward the same
boundary shape as `repo-ref/ai`, even though the repository still needed the
decision written down more explicitly.

## Decision

The boundary should stay as follows:

1. keep `HttpChatTransport` provider-neutral
2. do **not** serialize raw `ProviderInvocationOptions` through the generic
   HTTP chat envelope
3. use `DirectChatTransport` when client code must own typed provider options
   directly
4. use app-owned `metadata` plus transport preparation hooks when client code
   needs to send backend hints
5. let the backend translate those app-owned hints into provider-specific
   invocation options

## Why This Is The Safer Design

Serializing raw provider options through the generic transport would create
three kinds of pressure:

- it would push provider-specific wire concerns into a shared transport layer
- it would encourage clients to depend on server execution details that should
  remain backend-owned
- it would create a cross-package serialization contract for every provider
  option type, which does not belong in `llm_dart_core`

That would move the codebase away from the reference repository's actual
layering lesson, not closer to it.

## Flutter / Chat-App Guidance

For Flutter and other app clients, the recommended split is:

### Direct Provider Calls

Use `DirectChatTransport` when the client really needs typed per-request
provider options such as:

- OpenAI built-in tools
- Anthropic extended thinking
- provider-owned chat settings that are part of direct local execution

### Backend Chat Transport

Use `HttpChatTransport` when the backend should own:

- API keys
- compliance and auditing
- retry policy
- provider choice or provider-specific invocation shaping

In that mode, the client should send only:

- shared prompt state
- shared `GenerateTextOptions`
- app-owned JSON metadata or request-body hints

The backend then maps those hints into concrete provider options.

## If A Future Expansion Is Needed

If repeated backend integrations later show the same pain pattern, the next
candidate should be:

- an additive transport-owned JSON hint envelope or codec registry

The next candidate should **not** be:

- adding serialization requirements to `ProviderInvocationOptions`
- teaching `llm_dart_core` about provider-specific transport payloads
- widening the generic HTTP transport until it becomes a provider bus

## Bottom Line

For backend chat flows, `HttpChatTransport` should stay generic.

Provider-specific invocation settings remain either:

- direct-transport concerns, or
- backend-owned execution concerns

That keeps Flutter/chat integration practical without turning the shared
transport contract into a new provider-specific abstraction layer.
