# Modern Surface Audit

## Objective

Audit first-party docs and examples for places where the default learning path
still leads with provider-facing prompts, advanced runtime facades, or
compatibility APIs instead of the modern app-facing surface.

The target public story is:

- default app code uses `ModelMessage` through `messages:`
- provider-facing `PromptMessage` through `prompt:` is advanced material
- `generateText(...)` and `streamText(...)` are the primary runtime helpers
- `runTextGeneration(...)` and `streamTextRun(...)` are advanced run/step
  facades
- root legacy and builder-era APIs are migration-only or removed

## Evidence Commands

Representative searches used for this audit:

```powershell
rg -n "UserPromptMessage|SystemPromptMessage|AssistantPromptMessage|ToolPromptMessage|List<.*PromptMessage|prompt:\s*\[|prompt:\s*prompt|runTextGeneration\(|streamTextRun\(|package:llm_dart_core|package:llm_dart/legacy\.dart|LLMBuilder|createProvider" README.md docs\migration example packages\llm_dart_ai\README.md packages\llm_dart_chat\README.md packages\llm_dart_core\README.md packages\llm_dart_provider\README.md packages\llm_dart_openai\README.md packages\llm_dart_anthropic\README.md packages\llm_dart_google\README.md packages\llm_dart_ollama\README.md packages\llm_dart_elevenlabs\README.md
```

```powershell
rg --files-with-matches "UserPromptMessage|SystemPromptMessage|AssistantPromptMessage|ToolPromptMessage|List<.*PromptMessage|PromptMessage" README.md docs\migration example
```

```powershell
rg --files-with-matches "ModelMessage|UserModelMessage|SystemModelMessage|AssistantModelMessage|messages:" README.md docs\migration example
```

## Findings

### Strong Default Path

The root README already presents the modern surface clearly:

- `package:llm_dart/llm_dart.dart` is the default modern import.
- quick examples use `SystemModelMessage.text(...)` and
  `UserModelMessage.text(...)`.
- `generateText(...)` / `streamText(...)` are described as primary helpers.
- `runTextGeneration(...)` / `streamTextRun(...)` are described as advanced
  runner telemetry surfaces.
- builder-era APIs such as `LLMBuilder()` and `createProvider(...)` are
  described as removed.

The getting-started examples also use `ModelMessage` and `messages:` in the
main path:

- `example/01_getting_started/quick_start.dart`
- `example/01_getting_started/basic_configuration.dart`
- `example/01_getting_started/provider_comparison.dart`

### Provider README Drift

Focused provider package READMEs still lead with provider-facing prompt shapes:

| File | Evidence | Recommendation |
| --- | --- | --- |
| `packages/llm_dart_openai/README.md` | examples use `prompt:` with `UserPromptMessage` | Change first text-generation example to `messages:` with `UserModelMessage`; keep provider-facing prompt only in advanced replay/provider contract examples. |
| `packages/llm_dart_anthropic/README.md` | examples use `prompt:` with `UserPromptMessage` | Same: default to `messages:`, reserve `PromptMessage` for provider-specific content/replay. |
| `packages/llm_dart_google/README.md` | examples use `prompt:` with `UserPromptMessage` | Same. |
| `packages/llm_dart_ollama/README.md` | quick example uses `prompt:` with `UserPromptMessage` | Same. |

This is a docs-gap, not an implementation blocker.

Cleanup status:

- addressed by `06-modern-surface-docs-cleanup.md`
- default provider README text-generation examples now use `messages:` with
  `UserModelMessage`
- provider-contract prompt examples remain reserved for advanced material

### Migration Guide Drift

`docs/migration/0.11-sdk-aligned.md` still uses provider-facing
`UserPromptMessage` in multiple migration snippets.

This may be intentional for low-level migration from old prompt shapes, but the
guide should separate:

- modern app replacement: `messages:` + `ModelMessage`
- provider-contract migration: `prompt:` + `PromptMessage`

Recommendation:

- add a short "default modern migration" snippet before provider-facing prompt
  snippets
- label every `PromptMessage` snippet as advanced/provider-contract material

Cleanup status:

- addressed by `06-modern-surface-docs-cleanup.md`
- common migration "After" snippets now use `messages:` with
  `UserModelMessage`
- direct `PromptMessage` naming remains only for provider-contract explanation

### Advanced Examples With Acceptable Provider-Facing Prompts

Many advanced examples use `PromptMessage` because they demonstrate provider
or replay behavior. These should not be mechanically rewritten:

- Anthropic file handling, MCP, extended thinking, and streaming tool calling
- OpenAI Responses lifecycle, image/file messages, advanced replay, and GPT-5
  feature demos
- Google image generation and media-heavy examples
- xAI live search and OpenAI-compatible provider demos
- MCP client examples that inspect or replay prompt history
- custom provider examples that implement `LanguageModel` directly

Recommendation:

- keep provider-facing prompts in these examples when they show lower-level
  contracts
- add a local comment or README note when an example intentionally uses
  `PromptMessage` for provider-contract control

### Advanced Runtime Facade Usage

The root README and `llm_dart_ai` README mention `runTextGeneration(...)`,
`streamTextRun(...)`, `GenerateTextRunner`, and `StreamTextRunner` as advanced
surfaces.

This matches the current architecture. No code change is recommended.

## Classification

| Area | Status | Next Action |
| --- | --- | --- |
| Root README default path | acceptable | keep as is |
| Getting started examples | acceptable | keep as is |
| Provider package READMEs | docs gap | migrate first text-generation snippets to `messages:` |
| Migration guide | docs gap | split default migration snippets from provider-contract snippets |
| Advanced provider examples | acceptable advanced usage | add intent labels only where confusing |
| Runner docs | acceptable advanced usage | keep advanced framing |

## Suggested Follow-Up Milestone

Open a bounded docs-only milestone:

1. update provider package README first examples to `messages:`
2. update migration guide to label `PromptMessage` as advanced provider
   contract
3. add a guard or docs review checklist entry so new common examples do not
   lead with `PromptMessage`

No implementation refactor is needed for this audit.

Status:

- executed as the docs-only cleanup recorded in
  `06-modern-surface-docs-cleanup.md`
