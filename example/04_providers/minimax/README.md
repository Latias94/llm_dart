# MiniMax (Anthropic-compatible) examples

MiniMax exposes an Anthropic-compatible Messages API.

References:

- MiniMax compatible Anthropic API: https://platform.minimax.io/docs/api-reference/text-anthropic-api
- Vercel AI SDK (design inspiration): https://sdk.vercel.ai/

## Examples

- `m2_tool_use_interleaved_thinking_stream.dart`
  - Prompt IR + streaming tool loop (`LLMStreamPart`)
  - Demonstrates interleaved thinking (best-effort)
- `anthropic_compatible_tool_approval.dart`
  - Tool approval interrupt + manual resume
- `local_web_search_tool_loop.dart`
  - Local web search tool (DuckDuckGo Instant Answer) + tool loop

## Run

```bash
export MINIMAX_API_KEY="..."
export MINIMAX_BASE_URL="https://api.minimax.io/anthropic" # optional

dart run example/04_providers/minimax/m2_tool_use_interleaved_thinking_stream.dart
```

