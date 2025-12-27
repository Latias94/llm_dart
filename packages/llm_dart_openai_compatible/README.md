# llm_dart_openai_compatible

OpenAI-compatible provider configs and factories for `llm_dart`.

This package exists to reuse a single “wire protocol” implementation across
multiple providers that speak an OpenAI-compatible API.

Most users should depend on a concrete provider package (e.g. `llm_dart_groq`,
`llm_dart_xai`, `llm_dart_deepseek`) rather than this package directly.

