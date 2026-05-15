# TODO

## Workstream Setup

- [x] Create the provider implementation kit and codec boundary workstream
- [x] Define the canonical goal
- [x] Record initial hotspot audit
- [x] Record reference lessons from `repo-ref/ai`
- [x] Define utility publication criteria
- [x] Add the workstream to the workstream index

## Hotspot Audit

- [x] Capture first-pass provider implementation hotspots by file size and
  responsibility
- [x] Audit OpenAI Responses codec responsibilities in detail
- [x] Audit Anthropic messages tool-configuration boundary in detail
- [x] Decide first implementation slice after publish handoff status is clear

## Future Candidates

- [x] Google GenerateContent detailed codec audit and extraction
- Ollama language-model request/stream detailed audit

## OpenAI Responses Slice

- [x] Freeze target extracted module names
- [x] Identify request/response/stream/replay fixture coverage
- [x] Extract the first low-risk helper
- [x] Keep public OpenAI facade stable
- [x] Run focused OpenAI tests and analysis

## Second Provider Slice

- [x] Pick Anthropic, Google, or Ollama as the contrast provider
- [x] Extract one provider-local helper boundary
- [x] Verify fixture-based tests cover the extracted boundary
- [x] Run focused provider tests and analysis

## Google Follow-Up Slice

- [x] Compare Google GenerateContent boundaries against `repo-ref/ai`
      `convert-to-google-messages.ts` and `google-prepare-tools.ts`
- [x] Extract Google prompt/content/file/replay projection into a provider-local
      module
- [x] Extract Google common/native tool configuration into a provider-local
      module
- [x] Keep Gemini and Vertex semantics provider-local
- [x] Run focused Google tests, package analysis, and workspace dependency
      guards
- [x] Document why this still does not justify public provider utilities

## Provider Implementation Kit

- [x] Inventory duplicated helpers after the OpenAI and Anthropic slices
- [x] Keep one-provider helpers provider-local
- [x] Decide whether any helper belongs in an internal shared helper module
- [x] Decide whether public `llm_dart_provider_utils` is justified
- [x] Document the decision before creating any new package

## Validation

- [x] Run workspace dependency guards after provider implementation slices
- [x] Run root and core boundary guards after provider implementation slices
- [x] Run focused tests for touched provider packages after implementation slices
- [x] Run affected package analysis after implementation slices
- [x] Run `dart run tool/release_readiness.dart` before claiming closure
