# Package Graph Audit

## Runtime Dependency Policy

The current runtime dependency policy is enforced by
`tool/check_workspace_dependency_guards.dart`.

| Package | Allowed runtime dependencies |
| --- | --- |
| `llm_dart_provider` | none |
| `llm_dart_ai` | `llm_dart_provider` |
| `llm_dart_transport` | `dio`, `llm_dart_provider`, `logging` |
| `llm_dart_chat` | `llm_dart_ai`, `llm_dart_provider`, `llm_dart_transport` |
| `llm_dart_flutter` | `flutter`, `llm_dart_ai`, `llm_dart_chat`, `llm_dart_provider` |
| `llm_dart_openai` | `llm_dart_provider`, `llm_dart_transport` |
| `llm_dart_anthropic` | `llm_dart_provider`, `llm_dart_transport` |
| `llm_dart_google` | `llm_dart_provider`, `llm_dart_transport` |
| `llm_dart_ollama` | `llm_dart_provider`, `llm_dart_transport` |
| `llm_dart_elevenlabs` | `llm_dart_provider`, `llm_dart_transport` |
| `llm_dart_test` | `llm_dart_provider`, `llm_dart_transport` |
| `llm_dart_core` | `llm_dart_ai`, `llm_dart_provider` |
| root `llm_dart` | focused workspace packages only |

Provider packages may use `llm_dart_ai` in `dev_dependencies` for examples and
tests, but not in production `dependencies`.

## Audit Result

The guard passed after this workstream's dependency and UI ownership checks:

```text
workspace dependency guard passed: no package implementation files import package:llm_dart/... and no workspace pubspec policies were violated.
```

The provider packages audited for reverse runtime/UI dependencies are:

- `llm_dart_openai`
- `llm_dart_anthropic`
- `llm_dart_google`
- `llm_dart_ollama`
- `llm_dart_elevenlabs`

No provider package has a production runtime dependency on `llm_dart_ai`,
`llm_dart_chat`, `llm_dart_flutter`, root `llm_dart`, or `llm_dart_core`.
