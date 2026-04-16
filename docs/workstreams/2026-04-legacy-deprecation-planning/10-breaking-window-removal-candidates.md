# Breaking-Window Removal Candidates

## Goal

Turn the deprecation-planning work into a concrete proposal for the next
explicit breaking window.

This document answers:

- what should be removed first
- what should explicitly stay
- what should be reviewed only in a later window

## Default Rule

The first breaking window should still be conservative.

It should remove only leaves whose replacement path is already:

- documented
- honest
- narrow enough not to strand users

It should not weaken the main compatibility trunks by accident.

## Current Branch Status

The wave-1 removal set described in this document is now already landed on
`refactor/architecture-foundation`.

That means this document is no longer only hypothetical planning material for
that branch. It is also the rationale record for the removals now present in
code.

## Wave 1 Removals

### 1. Deprecated Preset Helper Aliases

Remove the already-deprecated preset helper aliases grouped in
`06-deprecated-preset-helper-aliases.md`.

This includes families such as:

- OpenAI-family compatibility aliases in `lib/providers/openai/openai.dart`
- Google preset aliases
- Anthropic preset aliases
- Groq preset aliases
- DeepSeek preset aliases
- Ollama preset aliases
- xAI preset aliases
- Phind preset aliases
- ElevenLabs preset aliases

Why they belong in wave 1:

- they are leaf ergonomics, not migration trunks
- each family now has an explicit migration note
- docs/examples no longer need them as the default copy-paste path

Removal posture:

- remove the preset helpers
- keep the non-deprecated root provider constructors
- keep provider-owned modern entrypoints and typed options

### 2. Deprecated Builder Web-Search Helpers

Remove the deprecated root builder web-search helpers:

- `enableWebSearch()`
- `webSearch(...)`
- `quickWebSearch(...)`
- `newsSearch(...)`
- `searchLocation(...)`
- `advancedWebSearch(...)`

Also remove the deprecated OpenRouter builder search ergonomics:

- `OpenRouterBuilder.webSearch(...)`
- `searchPrompt(...)`
- `useOnlineShortcut(...)`
- `maxSearchResults(...)`
- `forAcademicResearch()`
- `forNewsAndEvents()`
- `forTechnicalQueries()`
- `forGeneralSearch()`
- `forQuickSearch()`

Why they belong in wave 1:

- search replacement paths are now documented in
  `07-builder-web-search-replacements.md`
- the repository has a stable provider-owned search example
- these helpers encode fake cross-provider abstraction pressure

Removal posture:

- keep provider-owned search APIs
- keep `onlineSearch()` as the remaining compatibility OpenRouter helper
  because it still maps cleanly to a real audited online intent

### 3. `createProvider(..., extensions: ...)` Raw Escape Hatch

Treat the raw `extensions` parameter as the removable leaf, not the whole
`createProvider(...)` function.

Wave 1 proposal:

- remove the public `extensions` parameter from `createProvider(...)`
- keep `createProvider(...)` itself as a frozen generic compatibility helper

Why it belongs in wave 1:

- it is already explicitly deprecated
- it preserves exactly the kind of string-key coupling the refactor is trying
  to shrink
- provider-owned typed options are now the documented long-term path

Important constraint:

- this is a signature-level breaking change
- the migration note must show what to do instead when callers still need
  provider-specific behavior

### 4. Root Cancellation Alias

Remove the deprecated root cancellation alias:

- `CancelToken`

Replacement:

- `TransportCancellation`

Why it belongs in wave 1:

- the alias is already deprecated
- the replacement is one-to-one and simple
- this is exactly the kind of low-value legacy alias that should leave before
  any trunk discussion begins

## Explicit Wave 1 Non-Removals

The following should explicitly stay in the first breaking window.

### 1. `legacy.dart`

Keep it.

Reason:

- it is still the explicit compatibility landing zone
- removing it before the builder/root migration story is fully done would
  collapse the repository boundary work

### 2. `LLMBuilder`

Keep it.

Reason:

- it is still the real compatibility builder trunk
- the repository has only just soft-deprecated `ai()`
- trunk removal before one explicit alias-migration cycle would be premature

### 3. `createProvider(...)`

Keep the function.

Reason:

- dynamic provider selection still lacks an equally short stable public
  replacement
- only the raw `extensions` escape hatch is ready to go first

### 4. Root Provider Constructors

Keep non-deprecated root provider constructors such as:

- `createOpenAIProvider(...)`
- `createGoogleProvider(...)`
- `createAnthropicProvider(...)`
- `createOllamaProvider(...)`
- `createElevenLabsProvider(...)`

Reason:

- they are still the simplest bridge for old root-package callers
- the first breaking window should remove leaves before these broader rails

### 5. `ai()`

Do not remove it in wave 1 even though it is now soft-deprecated.

Reason:

- it needs at least one explicit migration cycle after deprecation
- the replacement is clear, but immediate removal would be unnecessarily sharp

### 6. Frozen Provider-Owned Compatibility Convenience APIs

Keep migration-specific helpers such as:

- `buildOpenAIResponses()`
- builder capability methods such as `buildAudio()` and `buildModelListing()`
- provider-owned compatibility shells that still cover real residual behavior

Reason:

- these are not yet backed by one equally short replacement story
- some still carry real compatibility value beyond leaf alias ergonomics

## Later-Wave Review Candidates

These should be revisited only after wave 1 lands cleanly.

### 1. `ai()` Actual Removal

Possible later action:

- remove the alias after one explicit deprecation cycle

Preconditions:

- first-party code stays off `ai()`
- release notes and migration note are already in place
- no further compatibility examples need the alias

### 2. `LLMBuilder`

Possible later action:

- soft-deprecate or slim only after more evidence accumulates

Preconditions:

- common builder jobs are all well covered by short stable recipes
- the builder trunk costs more than it helps

### 3. `legacy.dart`

Possible later action:

- slim first, remove last if ever

Preconditions:

- root compatibility import no longer carries meaningful migration weight

### 4. Root Provider Constructors

Possible later action:

- review only after the repository no longer needs them as a direct root
  bridge

## Practical Release Order

Recommended order:

1. keep current soft deprecations in a non-breaking release
2. ship explicit migration notes and release-note templates
3. execute wave 1 removals in the next deliberate breaking window
4. observe downstream churn
5. revisit `ai()` and larger trunks only after that

## Bottom Line

The first breaking window should remove:

- deprecated preset helper aliases
- deprecated builder web-search helpers
- `createProvider(..., extensions: ...)`
- `CancelToken`

It should explicitly not remove:

- `legacy.dart`
- `LLMBuilder`
- `createProvider(...)`
- root provider constructors
- `ai()` itself
