# TODO

## Workstream Setup

- [x] Create provider fixture contract workstream docs
- [x] Define provider fixture directory layout
- [x] Define golden naming convention
- [x] Define first OpenAI fixture scope

## OpenAI First Slice

- [x] Add Responses request body golden
- [x] Add Chat Completions request body golden
- [x] Add Responses stream event golden
- [x] Add Chat Completions stream event golden
- [x] Cover tool replay, MCP behavior, and provider metadata in the first
      golden set
- [x] Keep public API unchanged
- [x] Avoid new public packages

## Google Slice

- [x] Add GenerateContent request body golden
- [x] Add GenerateContent stream event golden
- [x] Cover media inputs, file references, structured output, safety settings,
      native tools, server-side tool replay, function-call id replay, reasoning,
      code execution, grounding, URL context, and provider metadata
- [x] Keep public API unchanged
- [x] Avoid new public packages

## Validation

- [x] Run focused OpenAI fixture contract tests
- [x] Run focused Google fixture contract tests
- [x] Run existing focused OpenAI request/stream/language-model tests with the
      new fixture contract tests
- [x] Run `dart analyze packages\llm_dart_openai`
- [x] Run `dart analyze packages\llm_dart_google`
- [x] Run `dart run tool\check_workspace_dependency_guards.dart`

Last validated: 2026-05-15 17:29 +08:00 through the full release readiness
gate.
