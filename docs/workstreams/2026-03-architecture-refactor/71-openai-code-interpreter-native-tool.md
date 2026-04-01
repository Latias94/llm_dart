# OpenAI Code Interpreter Native Tool

## Purpose

This note records the next OpenAI-native request-side tool slice after
`image_generation` and `mcp`.

The question was:

- should `llm_dart_openai` add `code_interpreter` as a first-class
  provider-owned declaration surface, or stop before that point?

The answer is now:

- yes, `code_interpreter` is still inside the reasonable request-side subset

## What Landed

`llm_dart_openai` now exposes a first-class provider-owned declaration surface
for OpenAI `code_interpreter`:

- `OpenAICodeInterpreterTool`
- `OpenAICodeInterpreterContainer`
- `OpenAICodeInterpreterAutoContainer`
- `OpenAICodeInterpreterContainerReference`
- `OpenAIBuiltInTools.codeInterpreter(...)`

The current request-side surface supports:

- the default auto container
- auto containers with uploaded file IDs
- explicit container references

## Why This Still Fits The Architecture

`code_interpreter` is still a request-side built-in tool declaration.

That means it fits the already-frozen provider-owned tool-entry rule:

- it belongs in `llm_dart_openai`
- it does not widen shared `ToolChoice`
- it does not widen the shared tool-definition model
- it does not add local runtime dependencies

This is still materially different from shell, patch, or tool-search runtime
surfaces that push much harder toward an agent runtime.

## What Did Not Land

This slice does **not** add:

- provider-owned helper APIs for `code_interpreter_call` outputs
- shared event types for code-interpreter code/output streaming
- hosted execution orchestration in the shared runner
- shell-style execution helpers

Those remain intentionally separate questions.

## Boundary Verdict

After this slice, the request-side OpenAI tool subset is strong enough for the
stable package surface:

- web search
- file search
- computer use
- image generation
- MCP
- code interpreter

The remaining hosted tool families should now be treated as deliberate
non-goals until a real use case appears.

## Bottom Line

`code_interpreter` is now part of the OpenAI provider-owned request-side tool
surface.

This is the last obvious high-value request-side addition before the project
should prefer restraint over further reference-surface cloning.
