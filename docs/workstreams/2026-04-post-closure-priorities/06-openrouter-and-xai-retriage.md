# OpenRouter And xAI Re-Triage

## Purpose

This note closes the last open provider-expansion item in the
`2026-04-post-closure-priorities` workstream:

- broader OpenRouter search mapping
- any xAI subset beyond the audited live-search path

The goal is not to prevent future provider growth.

The goal is to decide whether either topic still belongs to active refactor
debt after the architecture boundary is already frozen.

## Outcome

Neither topic remains active migration debt.

Both topics are now future provider-owned policy questions only.

That means:

- no shared-core widening is justified by either item today
- no new compatibility-bridge broadening is required today
- no new shared event or UI abstraction is required today

If either topic reopens later, it should reopen as a narrow provider contract
proposal, not as a generic "finish the migration" placeholder.

## OpenRouter

### Stable Subset

The stable OpenRouter search subset in this repository is still the audited
online-model path:

- provider ownership stays in `llm_dart_openai`
- the contract is model/profile shaping
- the stable public entry remains `OpenRouterChatModelSettings`
- shared projection continues to use common source models when citations exist

This is already enough for the current architecture phase.

### What Does Not Yet Count As Stable

The repository still does not prove a stable OpenRouter search wire contract
for legacy-shaped entries such as:

- `searchPrompt`
- `maxSearchResults`
- `useOnlineShortcut`
- any broader `webSearchConfig` fields beyond online-model intent

Those inputs exist as compatibility-era material, but that alone is not enough
reason to promote them into the modern typed surface.

### Architectural Consequence

OpenRouter should remain exactly where it is today:

- shared abstractions stay unchanged
- no OpenRouter-specific event expansion is needed
- no broader stable request contract should be claimed without tested wire
  evidence

If OpenRouter is revisited later, the reopen trigger must be a stronger,
provider-native search request contract than simple `:online` model shaping.

## xAI

### Stable Subset

The stable xAI subset in this repository is still the audited live-search
request path:

- provider ownership stays in `llm_dart_openai`
- the stable public entry remains `XAIGenerateTextOptions.search`
- the request encodes to xAI `search_parameters`
- citations continue to project through shared source models and events

This already gives `llm_dart` an honest provider-owned xAI contract without
widening the shared layer.

### What Should Stay Deferred

The repository should not treat the following as active migration debt yet:

- broader tool-based xAI search surfaces
- prompt-side replay or richer search-result replay contracts
- multimodal or compatibility-path expansion beyond the audited subset
- any xAI-specific UI/event model added only for symmetry

These are not one missing feature. They are multiple different provider
surfaces that should be evaluated independently.

### Architectural Consequence

If xAI reopens later, it should split into narrower candidates such as:

- the next audited `search_parameters` subset
- provider-native tool-based search
- richer provider-owned replay or rendering helpers

None of those should be forced back into the current
`XAIGenerateTextOptions` contract unless they truly share the same request
semantics.

## Relation To `repo-ref/ai`

The reference repository remains useful as a layering reference:

- provider-native growth can stay outside the shared model contract
- richer provider features can sit beside the core abstraction rather than
  inside it

But `llm_dart` should not copy every provider surface just because the
reference repository exposes a broader set of helpers.

For these two providers, the correct lesson is:

- borrow the layering discipline
- do not borrow speculative surface area

## Reopen Thresholds

OpenRouter should reopen only if:

- a broader search wire contract is proven and tested
- that contract is more than online-model shaping
- the resulting API can stay provider-owned and narrower than legacy builder
  material

xAI should reopen only if:

- a concrete next subset is identified
- that subset has a stable provider-owned contract
- the design can stay split from unrelated tool or replay surfaces

## Final Position

The current refactor round is complete enough on this front:

- OpenRouter keeps the audited online-model subset
- xAI keeps the audited live-search subset
- both remain future provider-owned policy questions instead of silent debt

That is the correct stopping point for this workstream.
