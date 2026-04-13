# 186 Ollama Tool-Choice And Tool-Error Boundary

## Why This Decision Exists

After the modern `llm_dart_community` Ollama chat path gained:

- assistant tool-call replay
- tool-result replay through Ollama `tool_name`
- URI-backed image input resolution

two fidelity questions still remained open:

- should the modern Ollama path invent a stronger explicit `toolChoice`
  forcing surface
- should it invent a replay-time tool error flag above the current Ollama chat
  wire contract

These are the last meaningful Ollama gaps that still look tempting if we chase
surface symmetry too aggressively.

## What Was Reviewed

Current modern Ollama behavior already does the honest thing:

- shared `toolChoice: none` suppresses declared tools
- shared `RequiredToolChoice` and `SpecificToolChoice` warning-degrade to
  "declared tools are available, provider decides"
- replayed tool results with `isError: true` warning-degrade to plain tool
  content because the current Ollama chat wire shape has no dedicated tool
  error field

Relevant implementation points:

- `packages/llm_dart_community/lib/src/ollama_language_model.dart`
- `packages/llm_dart_community/test/ollama_language_model_test.dart`

## Frozen Decision

The modern Ollama path should **not** add a fake stronger abstraction for these
two areas.

### 1. No fake explicit tool forcing

The shared `ToolChoice` contract should stay honest:

- `NoneToolChoice` can still map truthfully by omitting tools
- stronger forcing semantics should **not** pretend to exist when the current
  Ollama chat path does not expose a truthful equivalent

So the current warning-based downgrade for:

- `RequiredToolChoice`
- `SpecificToolChoice`

is the correct modern behavior for now.

### 2. No fake replay-time tool error field

The current Ollama chat request shape can replay tool results as tool content,
but it does not expose a separate native field for:

- tool-result error state
- replay-time error classification

So `ToolResultPromptPart(isError: true)` should continue to:

- keep the shared prompt signal
- emit a compatibility warning
- replay the tool result as plain tool content

That is better than inventing a provider-owned pseudo-field that the current
wire contract cannot round-trip truthfully.

## Why This Is Better

### 1. It keeps the provider package honest

The refactor goal is not "make every provider look equally feature-rich."

The goal is:

- unify the truthful shared overlap
- keep provider-owned extras provider-owned
- avoid inventing semantics that the provider wire does not really support

This Ollama decision follows that rule exactly.

### 2. It avoids a second fake migration layer

If we invented:

- an Ollama-only forced tool-selection API without a stable wire mapping
- an Ollama-only replay-time tool error flag without a real request field

we would recreate the old compatibility-bus problem inside the modern package.

### 3. It preserves a clean future expansion path

If a future Ollama wire contract later adds:

- explicit tool forcing
- native tool-result error fields

then the provider package can add a provider-owned API at that time.

That future expansion should be driven by real wire semantics, not by today's
desire for symmetry.

## What Remains True Today

The intended modern Ollama contract is now:

- use shared function-tool declarations when provider-side automatic selection
  is acceptable
- use `NoneToolChoice` when tools must be disabled
- accept warning-based downgrade for stronger shared tool-choice semantics
- accept warning-based downgrade for replay-time tool error state

That is the truthful modern boundary.

## Non-Goals

This decision does **not**:

- remove current Ollama tool support
- remove the shared `ToolResultPromptPart.isError` signal
- rule out future provider-owned Ollama extras forever
- change root compatibility-only Ollama completion or model-listing policy

## Conclusion

The remaining modern Ollama fidelity work is now intentionally closed as:

- no fake explicit tool forcing
- no fake replay-time tool error flag
- keep warning-based downgrade until Ollama exposes a truthful native contract

That keeps the modern Ollama package smaller, more honest, and more aligned
with the overall refactor discipline.
