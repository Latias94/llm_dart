# Milestones

## M0 - Architecture Freeze

Goals:

- freeze the core boundary documents
- freeze Prompt, Result, UI Message, and Stream Event naming
- freeze package boundaries

Acceptance criteria:

- the documents in this directory complete review
- all P0 questions in `OPEN_QUESTIONS.md` have conclusions

## M1 - Core Skeleton

Goals:

- establish the workspace
- make `llm_dart_core` and `llm_dart_transport` compile
- provide empty or minimal implementations for the new spec and shared functions

Acceptance criteria:

- the new package structure lands in the main branch
- the basic test foundation exists
- the old code still compiles

## M2 - OpenAI Mainline

Goals:

- migrate OpenAI chat and responses to the new architecture
- make `generateText` and `streamText` usable
- establish the OpenAI-family profile mechanism

Acceptance criteria:

- the OpenAI text mainline works
- streaming, tool calling, reasoning, and structured-output coverage tests pass

Current status:

- minimal Responses-based text generation is implemented in `llm_dart_openai`
- streaming text, reasoning summaries, and function-call outputs are mapped into the new core models
- replay-critical OpenAI Responses metadata now survives decode, session replay, and request re-encoding for assistant message IDs, message phase, reasoning encrypted content, tool-call item IDs, and compaction items
- transport now has a concrete Dio executor, SSE decoder, cancellation abstraction, and error mapping
- broader tool coverage, structured output, and non-text endpoints remain for the next step

## M3 - Anthropic And Google

Goals:

- migrate the Anthropic and Google mainlines
- represent provider-specific features through typed options, provider metadata, and custom parts

Acceptance criteria:

- Anthropic reasoning, tools, and MCP connector paths work
- Google chat, image, embedding, and TTS paths work

Current status:

- the Anthropic text-generation mainline is now wired through `llm_dart_anthropic`
- Anthropic request encoding, result decoding, stream decoding, MCP request models, and typed options are package-owned
- Anthropic assistant replay now keeps native tool replay paths and emits explicit warnings when unsupported assistant reasoning/file/custom replay parts are dropped
- the Google text-generation mainline is now wired through `llm_dart_google`
- Google request encoding, result decoding, stream decoding, grounding-source extraction, and typed options are package-owned
- Google thought signatures and reasoning-file artifacts now survive assistant replay, snapshot round-trip, and follow-up prompt reconstruction
- the shared tool-definition boundary is now frozen around common function tools and shared `ToolChoice`
- Anthropic and Google request codecs now consume `GenerateTextRequest.tools` / `toolChoice` for request-side function declarations
- initial provider-native tool entry APIs now exist in `llm_dart_google` and `llm_dart_anthropic`
- the current event decision remains stable: provider-native streamed details stay in common events plus `providerMetadata` or provider-namespaced custom payloads, not new Anthropic-only core events
- broader Google endpoints and additional Anthropic provider-native APIs remain open

## M4 - Community Providers

Goals:

- move DeepSeek, Groq, xAI, and Phind into the OpenAI-family profile model
- move Ollama and ElevenLabs into the community package

Acceptance criteria:

- long-tail providers no longer duplicate full OpenAI implementations
- provider duplication drops visibly

## M5 - Flutter Chat Layer

Goals:

- make `llm_dart_flutter` usable
- land `ChatSession`, `ChatTransport`, and `ChatState`
- make both direct and HTTP transports work
- freeze a versioned HTTP request/chunk protocol that sits above `TextStreamEvent`

Acceptance criteria:

- the Flutter chat example runs on the new API
- reasoning, tools, sources, and files render naturally
- assistant-turn replay remains semantically faithful enough for follow-up provider calls, not only visually faithful in the UI
- HTTP transport reconnect semantics are defined through transport checkpoints rather than ad hoc core events

## M6 - Compatibility Cleanup

Goals:

- degrade the old builder and capability interfaces into compatibility layers
- remove the old bus-style internals

Acceptance criteria:

- the README is centered on the new API
- old APIs have explicit deprecation markers
- duplicate registry logic, string-extension mainlines, and mixed-layer message logic are removed
