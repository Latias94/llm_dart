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

## 8. Whether Generic Remote Provider Options Should Exist In `HttpChatTransport`

Needs confirmation:

- should the generic HTTP chat transport later expose provider-specific remote options
- or should those remain backend-defined contracts outside the generic transport envelope

Current recommendation:

- do not support generic remote provider options in phase 1
- keep the transport request envelope JSON-safe and provider-neutral
- if this capability is needed later, add a separate namespaced transport field instead of serializing typed `ProviderInvocationOptions`

## P2 - Can Be Deferred

## 9. Whether `llm_dart_core` Should Be Published

Current recommendation:

- keep it internal to the repository in phase 1
- evaluate separate publishing only after the API stabilizes

## 10. Whether to Provide a Widget Layer

Current recommendation:

- not in this workstream
- provide state, session, and transport only

## 11. `SourceReference` Typing Status

Resolved in the current breaking round:

- `SourceReference` now carries an explicit `kind`
- the current common kinds are `url`, `document`, and `other`
- `SourceReference` may carry an optional `filename` for document citations
- provider-specific citation detail still belongs in provider metadata
- `GeneratedFile` remains separate from source citations

## 12. Whether Malformed Tool Input Should Be A First-Class Core Event

Needs confirmation:

- should invalid tool input remain a generic stream error
- or should the core model expose a distinct malformed-input concept

Current recommendation:

- add explicit malformed-tool-input semantics in a future breaking round
- keep tool execution errors and tool input errors separate
- do not overload `ToolResultEvent(isError: true)` to represent both stages
- prefer a dedicated `ToolInputErrorEvent` at the core stream layer
- keep Flutter UI projection on the existing error rendering path first; do not require a new UI state enum in the first round
- see `10-malformed-tool-input-design.md` for the concrete boundary proposal

## 13. Whether Reasoning Files Need A Common Cross-Provider Model

Needs confirmation:

- should the core model distinguish normal generated files from reasoning-only files
- or should provider-specific handling continue through generic file parts or custom parts

Current recommendation:

- do not add a common reasoning-file model yet
- revisit only after at least one more provider needs the distinction
