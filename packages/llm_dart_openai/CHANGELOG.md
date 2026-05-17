# Changelog

## Unreleased

- OpenAI-family facades now report profile-specific model facet support to
  `ProviderRegistry`: OpenAI exposes the current OpenAI language, embedding,
  image, speech, and transcription facets, while OpenRouter, DeepSeek, Groq,
  xAI, and Phind conservatively expose language-model lookup only.
- Direct non-text model factories on unsupported OpenAI-family profiles now
  throw `UnsupportedError` before constructing a misleading model object.
- OpenAI-family model capability descriptions now route through a profile-owned
  capability policy seam, which keeps the public describer stable while
  separating OpenAI, DeepSeek, OpenRouter, and xAI capability differences.
- Chat Completions request encoding now delegates OpenAI/DeepSeek-specific
  request fields and compatibility cleanup to an internal request policy seam
  while preserving existing typed provider option behaviour.
- The language-model Chat Completions path now resolves request policy from
  `OpenAIFamilyProfile` rather than only from `providerId`, keeping custom
  OpenAI profile ids on the OpenAI request-policy path.
- OpenAI Responses prompt conversion now delegates user media encoding,
  assistant replay projection, tool message projection, and replay policy to
  focused internal modules while preserving typed options and wire output.
- OpenAI embedding-model orchestration now delegates provider option
  resolution, request validation/body construction, transport request
  projection, and indexed response decoding to focused internal modules while
  preserving provider behavior.
- OpenAI image-model orchestration now delegates generation/edit validation,
  JSON and multipart request construction, transport request projection, and
  response/provider metadata decoding to focused internal modules while
  preserving provider behavior.
- OpenAI speech and transcription model orchestration now delegates provider
  option validation, request body construction, transport request projection,
  and response/provider metadata decoding to focused internal modules while
  preserving provider behavior.
- OpenAI language-model orchestration now delegates route-aware request
  encoding, transport request construction, generate response decoding, and
  stream chunk decoding to focused internal modules while preserving provider
  behavior.

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the OpenAI-family provider package.
- Use this package directly when you need OpenAI-specific options, native tool
  support, model profiles, or lower-level provider APIs.
- Includes package-local short factories such as `openai(...)`, `groq(...)`,
  `deepSeek(...)`, `openRouter(...)`, `xai(...)`, and `phind(...)` so apps can
  use the focused package without depending on the root facade.
- OpenRouter profiles can attach app attribution headers through
  `OpenRouterProfile(appReferer: ..., appTitle: ...)`.
- The root `llm_dart` package and `package:llm_dart/openai.dart` re-export the
  same model-first path for convenience.
- OpenAI-family models now implement the provider-side `doGenerate(...)`,
  `doStream(...)`, `doEmbed(...)`, and non-text `doGenerate(...)` contracts;
  app code should use shared helpers from `llm_dart_ai` or the root package.
- Image and file prompt-part request controls, including OpenAI image detail,
  are represented with typed `OpenAIPromptPartOptions` instead of
  `ProviderMetadata`.
