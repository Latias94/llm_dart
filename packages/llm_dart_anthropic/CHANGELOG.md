# Changelog

## [Unreleased]

- Refactored Anthropic Messages request option encoding into internal thinking
  policy, beta feature inference, token-count projection, and request assembly
  modules. Public settings, invocation options, beta headers, token-count
  behaviour, and wire output are unchanged.
- Refactored Anthropic code execution replay into a thin public facade plus
  provider-local replay JSON and execution result modules. Public replay API,
  custom prompt/content/event semantics, file-handle behavior, and wire shape
  are unchanged.
- Anthropic language-model orchestration now delegates request preparation,
  beta/header transport projection, generate response decoding, stream chunk
  decoding, and token-count response decoding to focused internal modules while
  preserving provider behavior.

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the Anthropic provider package.
- Use this package directly when you need Anthropic-specific options, files
  support, or lower-level provider APIs.
- Includes the package-local `anthropic(...)` short factory so apps can use the
  focused package without depending on the root facade.
- The root `llm_dart` package and `package:llm_dart/anthropic.dart` re-export
  the same model-first path for convenience.
- Anthropic models now implement the provider-side `doGenerate(...)` and
  `doStream(...)` contracts; app code should use shared helpers from
  `llm_dart_ai` or the root package.
- Prompt cache control on shared prompt parts now uses typed
  `AnthropicPromptPartOptions`, while tool cache control remains in typed
  `AnthropicGenerateTextOptions`.
