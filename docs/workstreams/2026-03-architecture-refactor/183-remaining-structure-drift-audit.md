# 183 Remaining Structure Drift Audit

## Goal

After the recent OpenAI, Google, Anthropic, runner, and chat-runtime slices,
the next question is no longer "what is still different from `repo-ref/ai`?"
in the abstract.

The useful question is:

- which remaining differences are still real structural debt
- which differences are now deliberate Dart-first choices
- which next cut is most valuable before starting another broad provider-local
  helper extraction round

## Reference Inputs Reviewed

The review uses the mature layering signals from:

- `repo-ref/ai/packages/provider`
- `repo-ref/ai/packages/openai/src`
- `repo-ref/ai/packages/ai/src/generate-text`
- `repo-ref/ai/packages/ai/src/ui`

These paths are useful because they show where the reference repository keeps:

- provider wire ownership
- shared text/runtime ownership
- UI transport ownership
- provider-specific feature boundaries

## Current Alignment Status

The repository is now already aligned with the important reference lessons in
the places that mattered most.

### 1. The package graph is already in the right direction

`llm_dart` now already has:

- shared model and orchestration contracts in `llm_dart_core`
- transport mechanics in `llm_dart_transport`
- provider-owned modern packages such as `llm_dart_openai`,
  `llm_dart_anthropic`, and `llm_dart_google`
- a separate chat runtime in `llm_dart_chat`
- a thin Flutter layer in `llm_dart_flutter`

This is the main structural lesson from the reference repository, even though
our package count intentionally remains smaller.

### 2. Provider-native features now stay provider-owned

The recent work already froze the correct direction for:

- OpenAI hosted/native tool declarations and replay-heavy persistence policy
- Google mixed-tool circulation and provider-owned replay/UI helpers
- Anthropic execution, tool-search, and tool-selection boundaries

That means the current repository is no longer blocked by the old "everything
lives in one compatibility bus" problem.

### 3. Shared events and chat runtime boundaries are no longer the main gap

The repository now already has:

- a stable `TextStreamEvent` boundary
- a separate `ChatUiStreamChunk` layer above raw stream events
- a framework-neutral chat runtime
- additive shared runner layers above raw provider calls

So the remaining maturity gap versus `repo-ref/ai` is not "missing event
families everywhere." It is mostly about where the last implementation weight
still lives.

## Remaining Structural Drift That Still Matters

Only a small subset of the remaining differences still looks like real
architecture debt.

### 1. Community-provider ownership is still the biggest real gap

This is now the highest-value remaining structure gap.

What is already true:

- `llm_dart_community` is a real package
- modern Ollama chat and embeddings already live there
- modern ElevenLabs speech and direct-audio transcription already live there
- root providers already delegate part of the shared-capability mainline into
  the package-owned models

What is still not true:

- the root Ollama and ElevenLabs shells are still too thick
- compatibility bridge helpers and config/factory shaping still sit on the
  critical path
- residual provider-shaped APIs still live in root provider directories

Compared with `repo-ref/ai`, this is now the clearest remaining ownership gap:
the modern package exists, but the root compatibility layer still owns too much
real implementation gravity.

This is also the remaining gap most likely to cause future drift, because new
fixes can still land in the root shells instead of the package-owned modern
path.

### 2. OpenAI is no longer a major structure blocker

The broad OpenAI migration umbrella remains open in `TODO.md`, but its
remaining weight is now much narrower than before.

The meaningful remaining OpenAI items are mostly:

- whether to keep advanced hosted-tool families deferred
- whether any later OpenAI-native replay/helper surface is justified by a real
  product need

That is a policy and product-surface question, not a sign that another generic
support layer is missing.

In other words:

- OpenAI still has open TODO items
- but OpenAI is no longer the main structural blocker versus `repo-ref/ai`

### 3. Shared runner and UI helper open questions are maturity gates, not debt

The remaining shared runner and chat helper questions are now mostly about:

- whether a constrained pre-step hook is ever needed
- whether streamed lifecycle metadata should become richer
- whether `readChatUiStream(...)` ever needs a callback or final-summary facade

These are not phase-1 architecture holes.

They should stay use-case-driven, because the current repository already has a
truthful layered architecture for:

- raw provider streams
- stitched multi-step shared orchestration
- UI/session chunk projection

That is already aligned with the reference on the important boundary.

### 4. Google native-tool selection is intentionally deferred, not missing

The remaining Google open item is:

- whether to expose a public native-tool selection or forcing API

This should still stay deferred.

The current Gemini 3 mixed-tool contract is now implemented enough to prove the
provider-owned declaration and circulation path, but not yet stable enough to
freeze a public forcing policy surface.

So this is not a missing abstraction to rush into parity.

### 5. Anthropic helper symmetry is now mostly a false target

Recent Anthropic audits already froze that:

- shared `SpecificToolChoice` must stay limited to declared common function
  tools
- tool-search does not need another custom helper layer
- codec-local support extraction should stay demand-driven instead of symmetry-
  driven

That means Anthropic is no longer a good place to keep mining for "just one
more helper file" work.

## Recommended Next Priority Order

### 1. Finish the community-provider ownership move

The next most valuable refactor slice should focus on:

- further thinning the root Ollama and ElevenLabs shells
- pushing more shared-capability implementation ownership into
  `llm_dart_community`
- keeping residual provider-shaped APIs explicitly residual instead of letting
  them keep shadowing the modern path

This is the remaining step most aligned with the reference repository's
ownership discipline.

### 2. Narrow the OpenAI migration umbrella instead of expanding it again

After the community slice, the next OpenAI step should probably be a closure
audit, not another broad implementation wave.

The likely goal should be:

- restate that the remaining OpenAI hosted-tool families are intentionally
  deferred unless a concrete product need appears
- keep chat-completions replay conservative
- avoid reopening shared-core or generic-helper design pressure

That would make the OpenAI TODO surface more honest and smaller.

### 3. Revisit shared runner or UI facades only after real usage pressure

Only after more real usage should the repository decide whether it needs:

- a constrained pre-step hook
- richer streamed lifecycle metadata
- a callback/final-summary facade above `readChatUiStream(...)`

These should not be the next large refactor target.

## What Should Not Be Done Next

The next phase should still avoid these moves:

- do not split the workspace as finely as `repo-ref/ai`
- do not add a generic provider-utils or support-bus package
- do not widen shared `ToolChoice` for provider-native selection
- do not widen shared stream events to copy UI transport vocabulary
- do not invent a Google native-tool forcing API before the provider wire
  policy is stable
- do not keep extracting provider-local helper files only for symmetry

## Conclusion

The remaining structure drift is now much smaller than the old workstream
backlog may suggest.

The current conclusion is:

- the repository is already largely aligned with `repo-ref/ai` on the
  high-value architectural boundaries
- the biggest remaining real ownership gap is community-provider migration,
  not OpenAI/Google/Anthropic helper symmetry
- the next best refactor slice should therefore move more real implementation
  gravity into `llm_dart_community`, then re-audit any residual OpenAI closure
  items afterwards
