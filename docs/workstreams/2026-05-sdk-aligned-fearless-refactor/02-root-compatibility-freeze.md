# Root Compatibility Freeze

## Decision

The root `llm_dart` package stays, but its role is frozen:

- `package:llm_dart/llm_dart.dart` is the default modern entrypoint and only
  re-exports `ai.dart`
- `package:llm_dart/ai.dart` is the modern aggregator over `llm_dart_ai`,
  focused provider entrypoints, `core.dart`, `transport.dart`, and root
  provider factory shortcuts
- provider-focused entrypoints such as `openai.dart`, `google.dart`, and
  `anthropic.dart` re-export provider-owned packages plus root factory helpers
- `core.dart`, `transport.dart`, and `chat.dart` are focused facades, not
  implementation homes
- `legacy.dart` is the explicit compatibility bridge for builder-era APIs and
  older root provider shells

New user-facing implementation ownership should not move into root. New shared
contracts belong in `llm_dart_provider`; new runtime orchestration belongs in
`llm_dart_ai`; transport implementation belongs in `llm_dart_transport`;
provider-native features belong in the provider package that sends the wire
request.

## Retained Root Entrypoints

| Entrypoint | Role |
| --- | --- |
| `llm_dart.dart` | Default modern facade; exports `ai.dart` only |
| `ai.dart` | Modern convenience aggregator |
| `core.dart` | Focused shared contract/runtime facade |
| `transport.dart` | Focused transport facade |
| `chat.dart` | Pure Dart chat runtime facade |
| `openai.dart` | OpenAI-family provider facade |
| `anthropic.dart` | Anthropic provider facade |
| `google.dart` | Google provider facade |
| `ollama.dart` | Ollama provider facade |
| `elevenlabs.dart` | ElevenLabs provider facade |
| `openrouter.dart` | OpenRouter OpenAI-family profile facade |
| `deepseek.dart` | DeepSeek OpenAI-family profile facade |
| `groq.dart` | Groq OpenAI-family profile facade |
| `phind.dart` | Phind OpenAI-family profile facade |
| `xai.dart` | xAI OpenAI-family profile facade |
| `legacy.dart` | Explicit compatibility bridge |

## Guard Coverage

`tool/check_root_package_boundary_guards.dart` now freezes:

- allowed root public entry files
- allowed root top-level directories
- allowed `lib/src` ownership buckets
- `llm_dart.dart` as a one-hop modern facade
- `ai.dart` as the modern aggregator
- provider-focused entrypoint export lists
- `core.dart`, `transport.dart`, and `chat.dart` export lists
- no Flutter import/export from root
- chat package exposure only from `chat.dart`
- no `package:llm_dart/legacy.dart` imports from examples

`tool/check_core_compatibility_shell_guard.dart` freezes
`llm_dart_core/lib` as a compatibility shell that contains only public
re-exports and approved compatibility typedef aliases.

## Migration Rule

When a root compatibility API has a documented focused replacement, prefer
removal or relocation in the breaking line instead of adding another root shim.
If a compatibility shim must remain, it should be reachable through
`legacy.dart` or a focused facade and covered by a guard or migration note.
