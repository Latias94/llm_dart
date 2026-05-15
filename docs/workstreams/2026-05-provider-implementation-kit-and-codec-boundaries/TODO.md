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
- [ ] Audit OpenAI Responses codec responsibilities in detail
- [ ] Audit Anthropic messages and stream codec responsibilities in detail
- [ ] Audit Google GenerateContent codec responsibilities in detail
- [ ] Audit Ollama language model request/stream responsibilities in detail
- [ ] Decide first implementation slice after publish handoff status is clear

## OpenAI Responses Slice

- [ ] Freeze target extracted module names
- [ ] Identify request/response/stream/replay fixture coverage
- [ ] Extract the first low-risk helper
- [ ] Keep public OpenAI facade stable
- [ ] Run focused OpenAI tests and analysis

## Second Provider Slice

- [ ] Pick Anthropic, Google, or Ollama as the contrast provider
- [ ] Extract one provider-local helper boundary
- [ ] Add or strengthen fixture-based tests
- [ ] Run focused provider tests and analysis

## Provider Implementation Kit

- [ ] Inventory duplicated helpers after two implementation slices
- [ ] Keep one-provider helpers provider-local
- [ ] Decide whether any helper belongs in an internal shared helper module
- [ ] Decide whether public `llm_dart_provider_utils` is justified
- [ ] Document the decision before creating any new package

## Validation

- [ ] Run workspace dependency guards after provider implementation slices
- [ ] Run root and core boundary guards after provider implementation slices
- [ ] Run focused tests for touched provider packages
- [ ] Run affected package analysis
- [ ] Run `dart run tool/release_readiness.dart` before claiming closure
