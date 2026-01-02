# llm_dart_anthropic_compatible

Anthropic Messages API compatible implementation for `llm_dart` providers.

This package is a Tier 3 (opt-in) protocol layer: it is intended for advanced
users and provider authors.

This package enables protocol reuse for providers that follow Anthropic’s
Messages API wire format (e.g. MiniMax via Anthropic-compatible endpoints).

Most users should depend on a concrete provider package (e.g. `llm_dart_anthropic`,
`llm_dart_minimax`) rather than this package directly.

If you are building your own Anthropic-compatible provider wrapper, prefer
delegating to `AnthropicCompatibleChatProvider` (mirrors the OpenAI-compatible
layer) instead of re-implementing chat/stream parsing.

## Imports

The recommended entrypoint is:

```dart
import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
```

Low-level transport utilities are intentionally opt-in and must be imported via
subpaths:

```dart
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_anthropic_compatible/dio_strategy.dart';
```
