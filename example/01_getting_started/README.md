# Getting Started

Basic examples to get you up and running with LLM Dart.

The default modern entry path for new code is
`package:llm_dart/llm_dart.dart` plus the stable
short provider factories such as `openai(...).chatModel(...)` and the shared
helpers in `package:llm_dart/core.dart`.

Concrete provider factories now come from direct provider packages such as
`package:llm_dart_openai/llm_dart_openai.dart`; the root package stays
provider-neutral.

If the provider choice is data-driven, build a `ProviderRegistry` from the root
modern entrypoint instead of falling back to the legacy builder or the
low-level factory-map `ModelRegistry`.

This directory stays on the modern model-first path. If you need older
compatibility builders or broad provider shells, jump to the explicit appendix
material under `../02_core_features/` or `../04_providers/` instead of
starting here.

When you later add chat UI rendering, keep the shared message projection in
`package:llm_dart/core.dart`; the chat runtime packages own session/controller
abstractions, not the conceptual ownership of `ChatMessageMapper`.

## Examples

### [quick_start.dart](quick_start.dart)
Basic usage with multiple providers. Start here for your first AI conversation.

### [provider_comparison.dart](provider_comparison.dart)
Compare provider-owned stable model facades to choose the right fit.

### [basic_configuration.dart](basic_configuration.dart)
Essential configuration options and stable `ModelError` handling patterns.

## Setup

Set API keys:

```bash
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"
export GROQ_API_KEY="your-key"
```

Run examples:

```bash
dart run quick_start.dart
dart run provider_comparison.dart
dart run basic_configuration.dart
```

## Next Steps

- [Core Features](../02_core_features/) - Essential functionality
- [Use Cases](../05_use_cases/) - Complete applications
- [Provider Examples](../04_providers/) - Provider-specific features
