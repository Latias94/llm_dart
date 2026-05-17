# TODO

## Workstream Setup

- [x] Create the provider implementation kit and codec boundary workstream
- [x] Define the canonical goal
- [x] Record initial hotspot audit
- [x] Record reference lessons from `repo-ref/ai`
- [x] Define utility publication criteria
- [x] Add the workstream to the workstream index

## Hotspot Audit

- [x] Capture first-pass provider implementation hotspots by file size and
  responsibility
- [x] Audit OpenAI Responses codec responsibilities in detail
- [x] Audit Anthropic messages tool-configuration boundary in detail
- [x] Decide first implementation slice after publish handoff status is clear

## Future Candidates

- [x] Google GenerateContent detailed codec audit and extraction
- [x] Ollama language-model request/response/stream/tool detailed audit and
      extraction
- [x] Anthropic stream state/content/tool/result detailed audit and extraction

## OpenAI Responses Slice

- [x] Freeze target extracted module names
- [x] Identify request/response/stream/replay fixture coverage
- [x] Extract the first low-risk helper
- [x] Keep public OpenAI facade stable
- [x] Run focused OpenAI tests and analysis

## Second Provider Slice

- [x] Pick Anthropic, Google, or Ollama as the contrast provider
- [x] Extract one provider-local helper boundary
- [x] Verify fixture-based tests cover the extracted boundary
- [x] Run focused provider tests and analysis

## Google Follow-Up Slice

- [x] Compare Google GenerateContent boundaries against `repo-ref/ai`
      `convert-to-google-messages.ts` and `google-prepare-tools.ts`
- [x] Extract Google prompt/content/file/replay projection into a provider-local
      module
- [x] Extract Google common/native tool configuration into a provider-local
      module
- [x] Keep Gemini and Vertex semantics provider-local
- [x] Run focused Google tests, package analysis, and workspace dependency
      guards
- [x] Document why this still does not justify public provider utilities

## Ollama Follow-Up Slice

- [x] Compare Ollama chat boundaries against `repo-ref/ai`
      `openai-compatible` provider-local chat conversion and tool-preparation
      boundaries
- [x] Extract Ollama chat request body construction into a provider-local module
- [x] Extract Ollama non-stream response decoding into a provider-local module
- [x] Extract Ollama NDJSON stream parsing into a provider-local module
- [x] Extract Ollama tool declaration, replay, and decode behavior into a
      provider-local module
- [x] Keep local runtime options, image-only multimodal support, model catalog,
      embedding, and capability behavior provider-owned
- [x] Run focused Ollama tests, package analysis, and workspace dependency
      guards
- [x] Document why this still does not justify public provider utilities

## Anthropic Stream Follow-Up Slice

- [x] Compare Anthropic stream boundaries against `repo-ref/ai`
      `anthropic-language-model.ts`, `convert-anthropic-usage.ts`,
      `map-anthropic-stop-reason.ts`, and `anthropic-message-metadata.ts`
- [x] Extract Anthropic stream state accumulation into a provider-local module
- [x] Extract Anthropic content-block start/delta/stop projection into a
      provider-local module
- [x] Extract Anthropic tool-use, tool-input delta, immediate tool-result, and
      custom replay event mapping into a provider-local module
- [x] Extract Anthropic message start/delta/stop finish, usage, and metadata
      mapping into a provider-local module
- [x] Keep native tool, thinking, cache, file, code-execution replay, and
      capability behavior provider-owned
- [x] Run focused Anthropic stream tests, full Anthropic tests, package
      analysis, and workspace dependency guards
- [x] Document why this still does not justify public provider utilities

## Anthropic Result Follow-Up Slice

- [x] Compare Anthropic result boundaries against `repo-ref/ai`
      result/tool/citation/metadata projection responsibilities
- [x] Extract Anthropic non-stream content projection into provider-local
      modules
- [x] Extract Anthropic tool-use and provider-tool result projection into a
      provider-local module
- [x] Extract Anthropic finish, usage, container, and response metadata mapping
      into a provider-local module
- [x] Keep `AnthropicMessagesResultCodec` as the stable public result facade
- [x] Keep thinking, redacted-thinking, compaction, citations, MCP,
      web-search/fetch, tool-search, code-execution replay, and provider
      metadata behavior unchanged
- [x] Run focused Anthropic result/replay tests and package analysis
- [x] Document why this still does not justify public provider utilities

## Anthropic Code Execution Replay Follow-Up Slice

- [x] Compare Anthropic code-execution replay boundaries against
      `repo-ref/ai` code-execution and tool-result replay semantics
- [x] Extract Anthropic code-execution replay JSON validation into
      provider-local modules
- [x] Extract Anthropic code-execution result typed models into a
      provider-local module
- [x] Keep `AnthropicCodeExecutionReplay` as the stable public replay facade
- [x] Keep code-execution wire shape, file-handle behavior, and prompt/content
      replay semantics unchanged
- [x] Run focused Anthropic code-execution replay tests and package analysis
- [x] Run Anthropic fixture contracts after the replay split
- [x] Document why this still does not justify public provider utilities

## OpenAI Responses Stream Follow-Up Slice

- [x] Compare OpenAI Responses stream boundaries against `repo-ref/ai`
      Responses language-model and streaming tool-call tracker boundaries
- [x] Extract OpenAI Responses stream state into a provider-local module
- [x] Extract OpenAI Responses stream chunk dispatch and event projection into
      a provider-local module
- [x] Extract OpenAI Responses function-call delta tracking into a
      provider-local module
- [x] Extract OpenAI Responses finish, usage, error, and response metadata
      mapping into a provider-local module
- [x] Keep `OpenAIResponsesCodec` as the stable provider-local facade
- [x] Keep Responses replay, custom parts, MCP, built-in tools, logprobs,
      source annotations, and provider metadata behavior unchanged
- [x] Run focused OpenAI Responses stream tests and package analysis
- [x] Run workspace dependency guards after the docs update
- [x] Document why this still does not justify public provider utilities

## OpenAI Chat Completions Stream Follow-Up Slice

- [x] Compare OpenAI Chat Completions stream boundaries against `repo-ref/ai`
      chat language-model and streaming tool-call tracker boundaries
- [x] Extract OpenAI Chat Completions stream state into a provider-local module
- [x] Extract OpenAI Chat Completions stream chunk decoding and event
      projection into a provider-local module
- [x] Extract OpenAI Chat Completions tool-call delta tracking into a
      provider-local module
- [x] Extract OpenAI Chat Completions result, finish, usage, error, logprobs,
      timestamp, and response metadata mapping into a provider-local module
- [x] Keep `OpenAIChatCompletionsCodec` as the stable provider-local facade
- [x] Keep OpenAI-compatible family stream events, xAI citations, malformed
      tool input behavior, and provider metadata unchanged
- [x] Run focused OpenAI Chat Completions stream tests and package analysis
- [x] Run workspace dependency guards after the docs update
- [x] Document why this still does not justify public provider utilities

## OpenAI Request Encoding Follow-Up Slice

- [x] Compare OpenAI request boundaries against `repo-ref/ai`
      `convert-to-openai-chat-messages.ts`,
      `openai-chat-language-model.ts`, and
      `openai-responses-language-model.ts`
- [x] Extract shared OpenAI-family request response-format and low-level
      request encoding helpers into provider-local modules
- [x] Extract OpenAI Responses prompt, tool, and request-option encoding into
      provider-local modules
- [x] Extract OpenAI Chat Completions prompt, tool, and request-option encoding
      into provider-local modules
- [x] Keep `OpenAILanguageModel`, `OpenAIResponsesCodec`,
      `OpenAIResponsesRequestCodec`, and `OpenAIChatCompletionsCodec` stable
- [x] Keep Responses replay, custom parts, MCP, built-in tools, and
      OpenAI-compatible chat-completions behavior unchanged
- [x] Run focused OpenAI request, stream, language-model tests and package
      analysis
- [x] Run workspace dependency guards after the docs update
- [x] Document why this still does not justify public provider utilities

## Provider Implementation Kit

- [x] Inventory duplicated helpers after the OpenAI and Anthropic slices
- [x] Keep one-provider helpers provider-local
- [x] Decide whether any helper belongs in an internal shared helper module
- [x] Decide whether public `llm_dart_provider_utils` is justified
- [x] Document the decision before creating any new package

## Validation

- [x] Run workspace dependency guards after provider implementation slices
- [x] Run root and core boundary guards after provider implementation slices
- [x] Run focused tests for touched provider packages after implementation slices
- [x] Run affected package analysis after implementation slices
- [x] Run `dart run tool/release_readiness.dart` before claiming closure
