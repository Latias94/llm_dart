# 185 Ollama URI-Backed Multimodal Inputs

## Why This Slice Exists

After the first modern `llm_dart_community` Ollama chat migration landed, one
of the remaining fidelity gaps was:

- URI-backed multimodal prompt inputs still required caller-owned byte loading

That gap was smaller than the original migration problem, but it still mattered
for Flutter and app integration because the shared prompt model already allows:

- `ImagePromptPart(uri: ...)`
- image-shaped `FilePromptPart(uri: ...)`

The modern Ollama chat path was still forcing callers to pre-convert those into
inline bytes before the provider-owned codec could use them.

## What Changed

The modern Ollama chat model now supports URI-backed user image inputs through a
provider-owned resolution path.

### 1. Data URIs now work directly

If a user image part carries a `data:` URI, the modern Ollama codec now decodes
it directly and inlines the resulting bytes into the native Ollama `images`
payload.

### 2. Other URIs can resolve through a provider-owned resolver

Ollama now exposes a provider-owned resolver contract:

- `OllamaBinaryResolver`

That resolver can be configured at either level:

- model defaults through `OllamaChatModelSettings.binaryResolver`
- per-call override through `OllamaGenerateTextOptions.binaryResolver`

Invocation-level resolver selection overrides model defaults.

### 3. Supported prompt shapes

The current modern Ollama path now supports:

- `ImagePromptPart(bytes: ...)`
- `ImagePromptPart(uri: data:...)`
- `ImagePromptPart(uri: ...)` with `OllamaBinaryResolver`
- image-shaped `FilePromptPart(uri: ...)` with `OllamaBinaryResolver`

The resolved bytes still map to Ollama's native `images` array, so the wire
contract remains truthful.

## Why This Is Better

### 1. It closes one real Flutter/app integration gap

Apps no longer have to eagerly rewrite every URI-backed image input into shared
prompt bytes before using the modern Ollama chat surface.

### 2. It stays Dart-first instead of pretending the package should own I/O

The package does **not** silently add filesystem or arbitrary URL fetching as a
hardcoded behavior.

Instead:

- `data:` URIs work locally with no extra I/O
- any other URI resolution remains app-owned but enters through a
  provider-owned hook

That is a much better fit for Dart, Flutter, and mixed platform targets.

### 3. It keeps the shared prompt model unchanged

No shared core prompt widening was needed.

The new behavior stays provider-owned and is specific to how the Ollama modern
chat codec needs to turn URI-backed images into native inline bytes.

## Non-Goals

This slice does **not**:

- add fake shared `toolChoice` forcing for Ollama
- invent a native replay-time tool error flag that Ollama's current chat wire
  contract does not expose
- add broad non-image file support to the current modern Ollama chat path
- add automatic filesystem or network fetching inside the package

## Remaining Ollama Gaps After This Slice

The remaining meaningful modern Ollama fidelity gaps are now narrower:

- explicit tool-selection or forcing still does not have a truthful native
  modern API contract
- replay-time tool error state still degrades because Ollama's current chat
  wire contract does not expose a dedicated tool-result error field

## Conclusion

The modern Ollama chat path is now closer to a practical Dart-first product
surface:

- URI-backed image inputs can participate in the modern model path
- the resolution contract stays provider-owned
- the shared core remains unchanged

This removes one real integration gap without inventing fake wire semantics for
the other remaining Ollama limitations.
