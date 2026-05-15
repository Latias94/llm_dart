# TODO

## Workstream Setup

- [x] Create Anthropic fixture contract workstream docs
- [x] Reuse provider-local fixture directory convention
- [x] Define first Anthropic fixture scope
- [x] Record OpenAI/Anthropic repetition without extracting shared utilities

## Anthropic First Slice

- [x] Add Messages request body golden
- [x] Add Messages request metadata golden
- [x] Add Messages replay request body golden
- [x] Add Messages stream event golden
- [x] Cover tool call and tool result replay
- [x] Cover reasoning and provider metadata
- [x] Keep public API unchanged
- [x] Avoid new public packages

## Validation

- [x] Run focused Anthropic fixture contract tests
- [x] Run existing focused Anthropic tests with the new fixture contract tests
- [x] Run `dart analyze packages\llm_dart_anthropic`
- [x] Run `dart run tool\check_workspace_dependency_guards.dart`

Last validated: 2026-05-15 13:40 +08:00.
