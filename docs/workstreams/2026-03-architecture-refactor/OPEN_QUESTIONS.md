# Open Questions

## P0 - Frozen

## 1. New Top-Level Facade Naming

Originally considered:

- keep `ai()` as the main entry point
- switch to `AI.openai(...).chatModel(...)`
- keep both, with `ai()` as compatibility only

Current conclusion:

- keep both
- new documents should promote `AI.*`
- keep `ai()` until the migration window ends

## 2. Where Provider-Specific Options Should Live

Originally considered:

- pass typed invocation options on each call
- mostly pass typed model options when creating the model
- support both layers

Current conclusion:

- support both layers
- model-level options carry stable provider features
- invocation-level options carry dynamic per-call parameters

## 3. Whether Files, Assistants, and Moderation Belong in the Shared Spec

Current conclusion:

- they do not belong in the phase-1 shared spec
- keep them as provider-package-specific APIs for now

## 4. Whether the Flutter Layer Should Depend on Flutter Foundation

Current conclusion:

- `llm_dart_core` does not depend on Flutter
- `llm_dart_flutter` may depend on `foundation`

## P1 - To Be Confirmed During Phase 1 or 2

## 5. OpenAI-Compatible Family Boundary

Needs confirmation:

- should the OpenAI-compatible family include all xAI and DeepSeek capabilities
- or only the protocol-overlap portion, with special capabilities exposed through separate adapters

Current recommendation:

- move only the protocol-overlap portion into the family core
- represent special capabilities through provider profiles and custom codecs

## 6. Whether the `community` Package Will Grow Too Large

Needs confirmation:

- should Ollama and ElevenLabs stay merged temporarily
- or should they be split from the start

Current recommendation:

- merge them in phase 1
- split later only if complexity justifies it

## 7. Whether `llm_dart_flutter` Should Start in Phase 1

Needs confirmation:

- should it start in parallel with core
- or should it wait until the text mainline stabilizes

Current recommendation:

- define the interfaces early
- implement the full layer in M5

## P2 - Can Be Deferred

## 8. Whether `llm_dart_core` Should Be Published

Current recommendation:

- keep it internal to the repository in phase 1
- evaluate separate publishing only after the API stabilizes

## 9. Whether to Provide a Widget Layer

Current recommendation:

- not in this workstream
- provide state, session, and transport only
