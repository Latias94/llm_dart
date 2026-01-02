# llm_dart

All-in-one “suite” package for the `llm_dart` monorepo.

If you prefer a smaller dependency graph, depend on individual subpackages in
`packages/llm_dart_*` instead.

## Quick start

```dart
import 'package:llm_dart/llm_dart.dart';
```

## API stability

- Recommended stable surface (Tier 1): task APIs from `llm_dart_ai` (re-exported by `llm_dart`).
- Provider packages are Tier 2: keep the main provider entrypoints stable where possible.
- Low-level transport and provider-native wrappers are Tier 3 opt-in and should be imported via explicit subpaths (see `docs/stability.md` in the repo).
