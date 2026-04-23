# Provider-Native Helper Investment Audit

## Goal

Decide which remaining residual capabilities deserve the next round of modern
provider-owned additive helpers, and which ones should remain explicitly
deferred or compatibility-only.

This note assumes the current architectural freeze remains in force:

- no shared-core widening just to absorb provider-native value
- no symmetry-driven package splitting
- no casual legacy removal

## Decision Filter

A residual capability is a good next additive helper candidate only when all of
the following are true:

1. it solves repeated app-facing or Flutter-facing product needs
2. it has an honest provider-local contract
3. it can be expressed as a narrow typed helper, not a broad compatibility
   shell
4. it reduces pressure to import a broad compatibility surface for one
   otherwise-modern use case
5. it does not require widening shared prompt, result, event, or session
   contracts

If any of those conditions is false, the default answer should remain
compatibility appendix or deliberate defer.

## Main Conclusion

The best next steps are not another architecture round.

The best next steps are:

1. teach the already-landed provider-owned helpers more clearly
2. add a small number of high-value provider-owned clients where modern app
   code still has to fall back to a broad compatibility shell

## A. Already-Landed Provider-Owned Helpers That Should Be Treated As First-Class

| Surface | Current modern shape | Why it matters | Recommended follow-up |
| --- | --- | --- | --- |
| OpenAI moderation client | `OpenAI(...).moderation()` and `OpenAIModerationClient` | Removes a common app-safety use case from the broad compatibility shell without inventing a shared moderation contract | Treat as landed; keep docs explicit that this is OpenAI-profile only, then make the next helper pick elsewhere |
| OpenAI image editing | `OpenAIImageModel.edit(OpenAIImageEditRequest)` | Proves the correct additive-provider-helper pattern for non-shared media workflows | Tighten README and provider examples so this is taught as a modern helper instead of old compatibility residue |
| Google image editing and variation | `GoogleImageModel.edit(...)` and `createVariation(...)` | Shows that edit-specific input contracts can stay provider-owned without widening shared `ImageModel` | Tighten README and examples so the modern helper is visible |
| Anthropic file metadata/download | `Anthropic.files()` | Gives Anthropic a narrow, honest modern file client without pretending file lifecycle is shared | Keep additive; do not widen shared file-management contracts |
| OpenAI and Google provider-aware message mappers | `mapComposed(...)` plus provider part details/custom-part helpers | Important for Flutter and app rendering without widening `ChatMessageMapper` | Keep treating this as the intended UI extension pattern |
| Community-provider capability profiles | `capabilityProfile`, `describeOllamaChatModel(...)`, `describeElevenLabsSpeechModel(...)` | Necessary for Flutter gating and app affordance selection | Keep confidence guidance explicit, especially for Ollama `inferred` hints |

### Practical implication

The immediate documentation gap is now more important than another structural
change for these helpers.

## B. Recommended Next Additive Helper Candidates

These are the next provider-owned helper investments that appear most justified
after the current doc-tightening phase.

| Candidate | Proposed home | Priority | Recommendation | Why it is worth doing |
| --- | --- | --- | --- | --- |
| Narrow OpenAI files client | `llm_dart_openai` | High | Add a modern provider-owned file client for upload/get/download/list/delete as a focused package helper | File IDs are relevant to hosted-tool and retrieval-oriented OpenAI flows, but current usage still forces the broad compatibility shell |
| ElevenLabs voice catalog reader | `llm_dart_community` or a focused ElevenLabs-owned helper near the community surface | High | Add a narrow voice-catalog surface for voice-picker UIs | Voice selection is common app-facing product value and does not need the whole compatibility audio shell |
| Ollama model catalog helper | `llm_dart_community` | High | Add a local model catalog/list helper as an explicit provider-owned utility | Local model pickers are common for desktop/Flutter local-runtime apps and do not justify broad compatibility imports |
| Anthropic file lifecycle completion | `llm_dart_anthropic` | Medium | Extend the modern file client with upload/list/delete only if the typed contract can stay narrow and execution-file oriented | Anthropic already has a partial modern file surface; finishing it may reduce compatibility imports for code-execution workflows |
| Google streamed speech utility | `llm_dart_google` | Medium | If revisited, land it as a Google-owned additive utility rather than shared `SpeechModel` widening | There is real product value for voice apps, but it remains provider-specific and session/stream-shape heavy |

## C. Explicitly Defer Or Keep As Compatibility Appendix

| Surface | Recommendation | Why it should not be productized right now |
| --- | --- | --- |
| OpenAI assistants lifecycle | Keep compatibility appendix | Stored assistant objects, threads, and resources are deeply provider-specific lifecycle APIs |
| OpenAI raw Responses CRUD/lifecycle | Keep compatibility appendix | Raw response objects and lifecycle IDs are not the default app-facing architecture |
| Shared moderation abstraction | Do not add | Taxonomy and score meaning differ too much by provider; app policy should normalize provider output instead |
| Shared remote model-listing abstraction | Do not add | Remote catalogs are admin/ops concerns with very provider-specific metadata and filters |
| ElevenLabs realtime/session APIs | Keep provider-owned appendix | Realtime session behavior is protocol-heavy and not yet a truthful shared media contract |
| ElevenLabs cloning, studio, or admin endpoints | Keep provider-owned appendix | These are management APIs, not shared speech/transcription semantics |
| Ollama `/api/generate` completion | Keep compatibility-only | It is not the modern shared chat contract and would only reopen an avoidable second local text path |
| Root builder parity work | Do not reopen | The repository already has clearer model-first and provider-package-first routes |

## D. Suggested Execution Order

The next slices should be ordered like this:

1. close doc visibility gaps for already-landed provider-owned helpers
2. add one narrow provider-owned client at a time where modern code still has
   to import a broad compatibility shell
3. add package README guidance and runnable examples alongside each new helper
4. only then consider shrinking any overlapping compatibility guidance

## E. Recommendation To Carry Forward

The repository should keep one simple rule:

> when a feature is real product value but not a truthful shared contract,
> land it as a small provider-owned helper before touching shared core or broad
> compatibility trunks.

That rule preserves the current architecture while still allowing meaningful
provider-native productization.
