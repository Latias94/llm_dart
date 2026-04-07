# Getting Started

Basic examples to get you up and running with LLM Dart.

The default modern entry path for new code is
`package:llm_dart/llm_dart.dart` plus the stable
`AI.*(...).chatModel(...)` facade and the shared helpers in
`package:llm_dart/core.dart`.

`package:llm_dart/ai.dart` remains available as an equivalent explicit alias
when you want a named AI-focused import style.

Some examples in this directory still use `package:llm_dart/legacy.dart` for
compatibility-oriented error types while the migration is in progress. Prefer
`quick_start.dart` when you want the current recommended shape.

## Examples

### [quick_start.dart](quick_start.dart)
Basic usage with multiple providers. Start here for your first AI conversation.

### [provider_comparison.dart](provider_comparison.dart)
Compare different AI providers to choose the right one for your needs.

### [basic_configuration.dart](basic_configuration.dart)
Essential configuration options and error handling patterns.

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
