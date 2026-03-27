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

## 12. Malformed Tool Input Status

Resolved in the current breaking round:

- malformed tool input now uses a dedicated `ToolInputErrorEvent`
- tool execution errors still use `ToolResultEvent(isError: true)`
- Flutter UI projection currently reuses the existing tool error rendering path
- provider adapters can adopt malformed-input signaling incrementally
- `10-malformed-tool-input-design.md` documents the frozen boundary

## 13. Reasoning File Status

Resolved in the current breaking round:

- `reasoning-file` should become a common cross-provider model
- the first concrete driver is Google, because the reference mainline already distinguishes thought-only files in generate, stream, and prompt replay paths
- keep one shared `GeneratedFile` payload and add distinct prompt/content/stream/UI wrappers for reasoning-only files

## 14. How Example-Only Dependencies Should Leave The Root Package

Needs confirmation:

- should example-heavy flows such as MCP integration move into their own example package or app
- or should the root package keep example-only dev dependencies until compatibility cleanup is nearly complete

Current recommendation:

- keep example-only dependencies at the root only as a temporary migration compromise
- once the new facade and package layout stabilize, move examples that need extra dependencies into their own package or app

## 15. Tool Definition Boundary Status

Resolved in the current breaking round:

- `llm_dart_core` now standardizes only common function-tool declarations
- the common tool request model uses object-rooted `ToolJsonSchema`
- shared `ToolChoice` now carries only cross-provider semantics
- provider-native tools remain outside the common request model and continue through provider-owned options or APIs
- `12-tool-definition-boundary.md` documents the frozen boundary

## 16. Provider-Native Tool Entry Status

Resolved in the current breaking round:

- provider-native tools now enter through provider-package typed settings or invocation options
- Google and Anthropic both have initial native tool entry APIs in their provider packages
- invocation-level native tool lists override provider-model defaults
- `13-provider-native-tool-entry.md` documents the frozen boundary

## 17. Assistant Prompt Replay Fidelity Status

Resolved in the current breaking round:

- assistant prompt history must round-trip replayable assistant semantics instead of storing only a display-oriented summary
- replayable prompt parts need optional part-level provider metadata
- reasoning parts, reasoning files, replayable custom parts, and relevant part metadata should survive `ChatUiMessage -> PromptMessage` reconstruction
- citations, UI-only data parts, and transport-only markers still stay out of prompt history
