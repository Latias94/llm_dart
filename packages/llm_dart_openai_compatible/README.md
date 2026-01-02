# llm_dart_openai_compatible

OpenAI-compatible provider configs and factories for `llm_dart`.

This package is a Tier 3 (opt-in) protocol layer: it is intended for advanced
users and provider authors.

This package exists to reuse a single “wire protocol” implementation across
multiple providers that speak an OpenAI-compatible API.

Most users should depend on a concrete provider package (e.g. `llm_dart_groq`,
`llm_dart_xai`, `llm_dart_deepseek`) rather than this package directly.

## Imports

The recommended entrypoint is:

```dart
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
```

Low-level transport utilities are intentionally opt-in and must be imported via
subpaths:

```dart
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/dio_strategy.dart';
```

