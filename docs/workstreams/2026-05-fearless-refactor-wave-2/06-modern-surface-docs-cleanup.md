# Modern Surface Docs Cleanup

## Objective

Execute the bounded docs-only milestone from `02-modern-surface-audit.md`.

The goal is to make app-facing examples teach the modern `ModelMessage` surface
first while preserving provider-contract `PromptMessage` usage where it is
actually the right abstraction.

## Changes

Provider README default text-generation examples now use `messages:` with
`UserModelMessage`:

- `packages/llm_dart_openai/README.md`
- `packages/llm_dart_anthropic/README.md`
- `packages/llm_dart_google/README.md`
- `packages/llm_dart_ollama/README.md`

The migration guide default replacement snippets now use `messages:` with
`UserModelMessage`:

- replace `ai()` / `LLMBuilder()` with focused factories
- replace legacy chat calls
- replace legacy streaming calls
- normal shared options example

The migration guide still names provider-contract `PromptMessage` types when
explaining normalized provider prompt replay and low-level provider contracts.

## Evidence Commands

```powershell
rg -n "UserPromptMessage|SystemPromptMessage|AssistantPromptMessage|ToolPromptMessage|prompt:\s*\[" packages\llm_dart_openai\README.md packages\llm_dart_anthropic\README.md packages\llm_dart_google\README.md packages\llm_dart_ollama\README.md docs\migration\0.11-sdk-aligned.md
```

Expected result after cleanup:

- no provider README hits
- no default `prompt: [` snippets in the migration guide
- only provider-contract explanatory references remain

## Acceptance Criteria

- [x] Provider README quick examples use `messages:` with `UserModelMessage`
- [x] Provider-owned options examples use `messages:` with `UserModelMessage`
- [x] Migration guide common replacement snippets use `messages:` with
  `UserModelMessage`
- [x] Provider-contract `PromptMessage` usage is not removed where the document
  is describing normalized prompt replay or low-level adapter contracts
- [x] No source API or package boundary changes were made

## Result

This milestone reduces documentation drift without changing implementation
ownership. It supports the Wave 2 goal by improving public API clarity before
any compatibility removals.
