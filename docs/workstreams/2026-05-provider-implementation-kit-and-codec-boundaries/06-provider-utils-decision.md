# Provider Utils Decision

## Decision

Do not create or publish `llm_dart_provider_utils` in this workstream.

Do not add a new internal shared helper module yet. The extracted helpers should
remain provider-local:

- `packages/llm_dart_openai/lib/src/openai_responses_request_codec.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_tool_configuration.dart`

## Evidence After Two Slices

The OpenAI slice moved Responses request encoding. It owns provider-specific
request semantics:

- Responses `input` item shapes
- item references and replay behavior
- Responses reasoning and service-tier compatibility
- built-in tool and MCP continuation request bodies
- OpenAI file IDs and Responses data URL encoding

The Anthropic slice moved tool configuration. It owns different provider
semantics:

- Messages `tool_choice` mapping
- extended-thinking compatibility for tool choice
- Anthropic native tools
- deferred loading for tool-search flows
- tool cache-control projection and beta behavior

These are both provider-local codec boundaries, but they are not the same
contract.

## Repeated Helper Candidates

| Candidate | Current evidence | Decision |
| --- | --- | --- |
| JSON normalization | `normalizeJsonValue` already lives in `llm_dart_provider`; provider codecs only choose provider-specific warning text and target fields. | Keep using the existing provider contract helper. |
| Provider reference resolution | Providers already call `ProviderReference.requireProvider(...)`; mapping the resolved ID into OpenAI `file_id`, Anthropic `file` source, or Google `fileData` remains provider-specific. | Keep mapping provider-local. |
| Tool choice encoding | OpenAI and Anthropic have different wire values and validation rules. `RequiredToolChoice` maps differently, and Anthropic rejects forced tool use with thinking. | Keep provider-local. |
| Media and file encoding | Base64/data URL/file-source code repeats mechanically, but accepted media types, URI rules, text documents, and hosted file references differ by provider. | Keep provider-local until a stable file-data helper contract emerges. |
| Stream tool-call tracking | OpenAI already has OpenAI-family stream helpers; Anthropic and Google stream vocabularies still differ. | Revisit only after a stream-specific split. |
| Fixture/test helpers | Existing focused tests cover provider behavior directly. A public runtime package should not expose test-only helper shape. | Keep test utilities local. |

## Package Evidence

There is no `packages/llm_dart_provider_utils` package in the workspace, and no
provider package depends on such a package.

This is intentional. A public helper package should wait until at least two
provider packages need the same independently testable behavior with the same
contract and stable names.

## Follow-Up Trigger

Revisit this decision only when a future slice produces one of these conditions:

- the same file/media encoding helper is copied into two provider-local modules
  with identical validation semantics
- the same stream tool-call accumulator is needed outside the OpenAI family
- request fixture helpers become duplicated across provider test packages
- provider reference handling needs more than the existing
  `ProviderReference.requireProvider(...)` contract
