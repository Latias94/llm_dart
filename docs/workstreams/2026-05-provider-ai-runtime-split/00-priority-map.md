# Priority Map

## Priority 1 - Freeze The Breaking Target

Before moving code, freeze the package graph and the stable vocabulary:

- provider specification layer
- provider utility layer
- AI runtime layer
- transport layer
- chat runtime layer
- Flutter adapter layer
- provider-owned helper layer
- root facade and legacy host

The output of this step should be a package graph that can later be enforced by
dependency guards.

## Priority 2 - Split Provider Spec From Runtime

The current `llm_dart_core` package is useful but too concentrated for the next
breaking line.

Provider model interfaces and data contracts should not live in the same
ownership group as multi-step generation runners, structured output parsing, UI
projection, and serialization.

Target direction:

- move model specs and shared wire-neutral data contracts to
  `llm_dart_provider`
- move generation orchestration to `llm_dart_ai`
- keep transport and chat runtime separate

## Priority 3 - Redesign File And Tool Data

The highest-value data-structure improvement is to stop encoding provider file
identity through generic metadata.

The shared prompt/content model should have first-class structures for:

- inline bytes
- URLs
- inline text files
- provider references
- structured tool outputs
- tool execution denial
- tool errors
- content-rich tool output

Provider metadata should remain output-side provider detail, not the primary
input-side reference mechanism.

## Priority 4 - Preserve Provider-Owned Product Value

Do not flatten useful provider-native features into weak common fields.

The following should stay provider-owned:

- OpenAI hosted files, moderation, Responses-specific controls, image editing,
  and native tools
- Anthropic files, thinking, MCP, native tools, and cache controls
- Google native tools, safety settings, cached content, image editing, and
  server-side tool replay
- Ollama local catalog and runtime-specific settings
- ElevenLabs voices and audio lifecycle helpers

The shared layer should expose stable operations. Provider packages should own
product-specific lifecycle and policy APIs.

## Priority 5 - Slim The Root Package By Moving Ownership

Root slimming should follow real code ownership moves.

Do not remove dependencies or exports cosmetically. First move implementation
weight into owning packages, then shrink root dependencies and entrypoints.

The long-term root role should be:

- modern default facade
- focused provider and chat entrypoint convenience
- explicit legacy compatibility host only while migration requires it

## Priority 6 - Update Guards, Examples, And Migration Docs

Every completed code move should have matching enforcement and guidance:

- workspace dependency guards
- root boundary guards
- focused entrypoint examples
- compatibility migration matrix
- breaking changelog notes

## Explicitly Deferred

The following should remain deferred until the core split has landed:

- adding reranking, video, skills, or gateway abstractions for reference parity
- splitting every provider into fine-grained subpackages
- expanding UI chunk vocabulary purely to match `repo-ref/ai`
- removing all legacy APIs before migration guidance exists
