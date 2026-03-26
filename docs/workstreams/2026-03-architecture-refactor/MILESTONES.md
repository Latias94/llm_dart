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

## M3 - Anthropic And Google

Goals:

- migrate the Anthropic and Google mainlines
- represent provider-specific features through typed options, provider metadata, and custom parts

Acceptance criteria:

- Anthropic reasoning, tools, and MCP connector paths work
- Google chat, image, embedding, and TTS paths work

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

Acceptance criteria:

- the Flutter chat example runs on the new API
- reasoning, tools, sources, and files render naturally

## M6 - Compatibility Cleanup

Goals:

- degrade the old builder and capability interfaces into compatibility layers
- remove the old bus-style internals

Acceptance criteria:

- the README is centered on the new API
- old APIs have explicit deprecation markers
- duplicate registry logic, string-extension mainlines, and mixed-layer message logic are removed
