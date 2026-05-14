# Provider-Specific Features

This directory shows how provider-owned capabilities fit into the refactored
`llm_dart` architecture.

For new code, prefer:

- the default modern root import `package:llm_dart/llm_dart.dart`
- stable short provider factories such as `openai(...)`, `google(...)`, and
  `xai(...)` to create provider-owned models
- shared app-facing helpers from `package:llm_dart/core.dart`
- the shared `ChatMessageMapper` from `package:llm_dart/core.dart` for stable
  UI summaries
- provider-owned `mapComposed(...)` helpers when the UI needs both shared and
  provider-specific projections in one pass
- provider-owned typed settings and options from provider packages

Pick the entrypoint by the surface you need:

- root package short factories for stable first-party providers: OpenAI,
  OpenRouter, DeepSeek, Groq, xAI, Anthropic, and Google
- `llm_dart_ollama` short factory for Ollama shared chat/embeddings/catalog
- `llm_dart_elevenlabs` short factory for ElevenLabs shared speech/transcription/voice catalog
- provider package options for provider-owned controls such as OpenAI built-in
  tools, Anthropic extended thinking, Google image settings, and xAI live search
- compatibility appendices only when a provider-owned lifecycle or residual
  legacy surface is not yet modeled by the modern package boundary

## Examples

### [openai/](openai/)
Mixed status. The package already has stable chat, image, speech, and
transcription models, plus provider-owned modern image-editing helpers. The
Responses appendix is now narrowed to the provider-owned OpenAI compatibility
surface. Residual assistants and some other lifecycle examples still remain
compatibility oriented.

### [anthropic/](anthropic/)
Mixed status. Stable chat plus typed extended-thinking and MCP options already
exist, and the focused Anthropic files client now covers upload, listing,
metadata, download, and deletion. `file_handling.dart` now demonstrates that
focused files client together with shared file and image prompt parts.

### [groq/](groq/)
Stable OpenAI-family chat facade with Groq profile and low-latency streaming.

### [google/](google/)
Stable embedding, image, and speech model facades with typed Google provider
options, plus provider-owned image-editing and variation helpers. The Google
TTS example is now stable-first for one-shot speech and keeps only streaming
and discovery as provider-owned appendix material.

### [ollama/](ollama/)
Modern local runtime examples with provider-owned Ollama options and the
provider-owned local model catalog helper. Residual compatibility flows now
mainly cover `/api/generate` and broader legacy shell behavior.

### [elevenlabs/](elevenlabs/)
Stable shared-capability speech/transcription examples plus the provider-owned
voice catalog helper. Modern shared ElevenLabs surfaces live in
`packages/llm_dart_elevenlabs`, while this directory still covers streaming
helpers and realtime boundary residue.

### [xai/](xai/)
Stable xAI chat facade with typed live-search options.

### [others/](others/)
Stable OpenAI-family profile examples plus explicit custom-compatible endpoint
wiring when a provider does not yet justify its own root facade.

## Setup

```bash
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export DEEPSEEK_API_KEY="your-deepseek-key"
export GROQ_API_KEY="your-groq-key"
export GOOGLE_API_KEY="your-google-key"
export ELEVENLABS_API_KEY="your-elevenlabs-key"
export XAI_API_KEY="your-xai-key"
export OPENROUTER_API_KEY="your-openrouter-key"

dart run groq/fast_inference.dart
dart run anthropic/extended_thinking.dart
dart run google/image_generation.dart
dart run xai/live_search.dart
```

## Stable Usage Patterns

### OpenAI Image Generation

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

final imageModel = llm.openai(apiKey: 'your-key').imageModel('dall-e-3');

final result = await core.generateImage(
  model: imageModel,
  prompt: 'A futuristic cityscape at sunset',
  count: 1,
  size: '1024x1024',
  callOptions: const core.CallOptions(
    providerOptions: openai.OpenAIImageOptions(
      quality: openai.OpenAIImageQuality.high,
    ),
  ),
);

print(result.images.first.uri);
```

### Google Image Generation

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/llm_dart.dart' as llm;

final imageModel = llm.google(apiKey: 'your-key')
    .imageModel('gemini-2.5-flash-image');

final result = await core.generateImage(
  model: imageModel,
  prompt: 'A futuristic robot in a modern kitchen',
  callOptions: const core.CallOptions(
    providerOptions: google.GoogleImageOptions(
      aspectRatio: google.GoogleImageAspectRatio.landscape16x9,
    ),
  ),
);

print(result.images.first.bytes?.length);
```

### Anthropic Extended Thinking

```dart
import 'package:llm_dart/anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

final model =
    llm.anthropic(apiKey: 'your-key').chatModel('claude-sonnet-4-5');

final result = await core.generateTextCall(
  model: model,
  messages: [
    core.UserModelMessage.text('Solve this logic puzzle step by step.'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: anthropic.AnthropicGenerateTextOptions(
      extendedThinking: true,
      thinkingBudgetTokens: 2048,
    ),
  ),
);

print(result.reasoningText);
print(result.text);
```

### DeepSeek Reasoning Stream

```dart
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

final model =
    llm.deepSeek(apiKey: 'your-key').chatModel('deepseek-reasoner');

final stream = core.streamTextCall(
  model: model,
  messages: [
    core.UserModelMessage.text('Analyze this complex problem step by step.'),
  ],
);

await for (final event in stream) {
  switch (event) {
    case core.ReasoningDeltaEvent(:final delta):
      stderr.write(delta);
    case core.TextDeltaEvent(:final delta):
      stdout.write(delta);
    default:
      break;
  }
}
```

### xAI Live Search

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/xai.dart' as xai;

final model = llm.xai(apiKey: 'your-key').chatModel('grok-3');

final result = await core.generateTextCall(
  model: model,
  messages: [
    core.UserModelMessage.text('What are the latest AI developments this week?'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: xai.XAIGenerateTextOptions(
      search: xai.XAILiveSearchOptions.autoWeb(maxSearchResults: 5),
    ),
  ),
);

print(result.text);
```

## Boundary Notes

- Provider-specific features should remain provider owned. Do not move
  live-search, built-in tools, or extended-thinking controls into shared
  `GenerateTextOptions`.
- Provider-aware chat UI mapping should also remain layered: shared summaries
  stay on `ChatMessageMapper`, while provider metadata and custom-part
  inspection stay in provider packages through `mapComposed(...)` or provider
  custom-part helpers.
- If a provider README shows a provider-specific compatibility entrypoint such
  as `createOllamaProvider(...)`, `createElevenLabsProvider(...)`, or an older
  builder shell, treat it as compatibility material unless the README
  explicitly marks it as stable.
- Flutter apps should prefer stable `LanguageModel`, `ImageModel`,
  `SpeechModel`, and `TranscriptionModel` entrypoints because they compose
  cleanly with `ChatSession`, streamed events, and UI state management.

## Next Steps

- [Core Features](../02_core_features/) - Essential cross-provider patterns
- [Advanced Features](../03_advanced_features/) - Shared higher-level workflows
- [Use Cases](../05_use_cases/) - Complete apps and Flutter integration
- [Getting Started](../01_getting_started/) - Stable setup and configuration
- [Ollama Provider Package Guide](../../packages/llm_dart_ollama/README.md) - Direct Ollama package-owned surfaces
- [ElevenLabs Provider Package Guide](../../packages/llm_dart_elevenlabs/README.md) - Direct ElevenLabs package-owned surfaces
