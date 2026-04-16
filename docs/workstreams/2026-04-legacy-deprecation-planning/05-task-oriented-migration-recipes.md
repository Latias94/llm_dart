# Task-Oriented Migration Recipes

## Goal

Translate the old builder-era jobs into short, honest migration recipes.

This document is intentionally task-oriented.

It does not try to force every old compatibility path into one shared
abstraction. When a stable replacement exists, it should be the default story.
When a stable replacement does not exist yet, the document should say so
plainly and keep the provider-owned compatibility boundary explicit.

## Quick Map

| Old builder job | Preferred direction now | Status |
| --- | --- | --- |
| `ai().<provider>().build()` for normal text generation | `AI.<provider>(...).chatModel(...)` + `generateTextCall(...)` or `streamTextCall(...)` | Stable |
| `chatWithTools(...)` plus hand-written tool follow-up | `FunctionToolDefinition` + `runTextGeneration(...)` / `streamTextRun(...)` | Stable |
| `buildEmbedding()` | `AI.<provider>(...).embeddingModel(...)` + `embed(...)` / `embedMany(...)` | Stable |
| `buildImageGeneration()` for prompt-based generation | `AI.<provider>(...).imageModel(...)` + `generateImage(...)` | Stable for prompt generation |
| `buildAudio()` for TTS / STT | `speechModel(...)` / `transcriptionModel(...)` + `generateSpeech(...)` / `transcribe(...)` | Stable |
| `buildModelListing()` for remote provider catalogs | Provider-owned compatibility provider or app-owned concrete-model profiles | Provider-owned boundary |
| `buildOpenAIResponses()` for raw response lifecycle | Stable `chatModel(...)` for normal app flows; provider-owned OpenAI compatibility surface for raw lifecycle APIs | Provider-owned boundary |
| Builder callback customization for provider-specific flags | Stable model + typed `CallOptions.providerOptions` where available | Mixed |

## 1. Text Generation And Streaming Chat

### Old pattern

```dart
final provider = await ai()
    .openai()
    .apiKey(apiKey)
    .model('gpt-4')
    .temperature(0.7)
    .build();

final response = await provider.chat([
  ChatMessage.user('Explain quantum computing.'),
]);
```

### Preferred pattern

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Explain quantum computing.'),
  ],
  options: const core.GenerateTextOptions(
    temperature: 0.7,
    maxOutputTokens: 200,
  ),
);
```

For streaming:

```dart
final stream = core.streamTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Explain quantum computing.'),
  ],
);
```

### Why this is the default

- the app-facing unit is now a concrete model, not a broad provider object
- shared request controls live in `GenerateTextOptions`
- transport concerns live in `CallOptions`
- provider-native settings stay provider-owned instead of leaking into a root
  builder shell

Reference examples:

- `example/01_getting_started/quick_start.dart`
- `example/02_core_features/chat_basics.dart`
- `example/02_core_features/streaming_chat.dart`

## 2. Tool Calling And Multi-Step Tool Continuation

### Old pattern

- call `chatWithTools(...)`
- inspect `toolCalls`
- execute tools manually
- build `ChatMessage.toolUse(...)` and `ChatMessage.toolResult(...)`
- send a second chat request

### Preferred pattern

For single-step manual replay, use shared prompt parts:

```dart
final firstTurn = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('What is the weather in Hong Kong?'),
  ],
  tools: tools,
  toolChoice: const core.RequiredToolChoice(),
);
```

For automatic continuation, use the runner:

```dart
final run = await core.runTextGeneration(
  model: model,
  prompt: prompt,
  tools: tools,
  functionToolExecutor: executeTool,
);
```

For streaming tool runs:

```dart
final stream = core.streamTextRun(
  model: model,
  prompt: prompt,
  tools: tools,
  functionToolExecutor: executeTool,
);
```

### Why this is the default

- the runner owns assistant/tool replay instead of each app reimplementing it
- the shared tool contract is explicit:
  `FunctionToolDefinition` + `GenerateTextFunctionToolExecutor`
- streaming now has a stable event model:
  `ToolInputStartEvent`, `ToolCallEvent`, `FinishEvent`, and friends

Reference examples:

- `example/02_core_features/tool_calling.dart`
- `example/02_core_features/enhanced_tool_calling.dart`
- `example/06_mcp_integration/http_examples/simple_stream_client.dart`
- `example/06_mcp_integration/shared/mcp_tool_bridge.dart`

## 3. Embeddings

### Old pattern

```dart
final embeddingProvider = await ai()
    .openai()
    .apiKey(apiKey)
    .model('text-embedding-3-small')
    .buildEmbedding();

final vectors = await embeddingProvider.embed(['hello world']);
```

### Preferred pattern

```dart
final model = AI.openai(apiKey: apiKey)
    .embeddingModel('text-embedding-3-small');

final single = await core.embed(
  model: model,
  value: 'hello world',
);

final batch = await core.embedMany(
  model: model,
  values: ['doc a', 'doc b'],
);
```

### Why this is the default

- embeddings are already a stable shared model contract
- batch helpers live in `core`
- community providers can join the same surface without pretending their
  runtime knobs are identical

Reference examples:

- `example/02_core_features/embeddings.dart`
- `example/04_providers/google/embeddings.dart`

## 4. Image Generation

### Old pattern

```dart
final imageProvider = await ai()
    .openai()
    .apiKey(apiKey)
    .model('dall-e-3')
    .buildImageGeneration();
```

### Preferred pattern

```dart
final imageModel = AI.openai(apiKey: apiKey).imageModel('dall-e-3');

final result = await core.generateImage(
  model: imageModel,
  prompt: 'A serene mountain lake at sunrise',
  count: 1,
  size: '1024x1024',
);
```

### Boundary note

Prompt-based generation is stable.

Image editing and variation flows are not yet frozen as a shared stable
contract. Keep those on provider-owned compatibility surfaces until their input
shape is redesigned deliberately.

Reference example:

- `example/04_providers/openai/image_generation.dart`

## 5. Audio Generation And Transcription

### Old pattern

```dart
final audioProvider = await ai().openai().apiKey(apiKey).buildAudio();
```

### Preferred pattern

```dart
final speechModel =
    AI.openai(apiKey: apiKey).speechModel('gpt-4o-mini-tts');
final transcriptionModel =
    AI.openai(apiKey: apiKey).transcriptionModel('whisper-1');

final speech = await core.generateSpeech(
  model: speechModel,
  text: 'Hello from llm_dart.',
  voice: 'alloy',
);

final transcript = await core.transcribe(
  model: transcriptionModel,
  audioBytes: audioBytes,
  mediaType: 'audio/mpeg',
);
```

### Community-provider case

This same stable surface also works for community packages such as
ElevenLabs:

```dart
final speechModel = community.ElevenLabs(
  apiKey: apiKey,
).speechModel('eleven_multilingual_v2');
```

### Boundary note

Separate audio translation, realtime sessions, and other provider-native media
workflows still need honest provider-owned appendix APIs.

Reference examples:

- `example/02_core_features/audio_processing.dart`
- `example/04_providers/openai/audio_capabilities.dart`
- `example/04_providers/elevenlabs/audio_capabilities.dart`

## 6. Model Discovery And Listing

This is where the migration story is intentionally not fake.

There are two different jobs:

1. concrete-model inspection for app UI gating
2. remote provider catalog listing

### Concrete-model inspection

This is stable:

```dart
final model = AI.openai(apiKey: 'demo-key').chatModel('gpt-4.1-mini');
final profile = (model as core.CapabilityDescribedModel).capabilityProfile;
```

Use this when your app already knows which models it wants to expose.

### Remote provider catalogs

This is still provider-owned compatibility surface:

```dart
final provider = openaiCompat.createOpenAIProvider(
  apiKey: apiKey,
  model: 'gpt-4o',
);

final models = await provider.models();
```

### Why there is no fake shared replacement

Provider catalogs differ in:

- metadata richness
- filtering rules
- pagination
- availability semantics

That makes remote model listing a provider-owned boundary, not a stable shared
core abstraction.

Reference example:

- `example/02_core_features/model_listing.dart`

## 7. Raw OpenAI Responses Lifecycle

### Normal app-facing generation

Stay on the stable chat model:

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
```

### Raw lifecycle work

If you actually need response fetching, continuation, or deletion, keep using
the provider-owned OpenAI compatibility surface.

This should be documented as an appendix, not sold as the new default.

Reference examples:

- `example/04_providers/openai/responses_api.dart`
- `example/04_providers/openai/build_openai_responses_demo.dart`

## 8. Provider-Specific Builder Customization

### Old pattern

```dart
final provider = await ai()
    .openai((openai) => openai.parallelToolCalls(true))
    .apiKey(apiKey)
    .model('gpt-4')
    .build();
```

### Preferred direction

Split the job into:

1. stable model selection
2. typed provider-owned call options

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Plan a rainy Osaka evening.'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: openai.OpenAIGenerateTextOptions(
      parallelToolCalls: true,
      maxToolCalls: 2,
    ),
  ),
);
```

### Boundary note

If a provider-specific builder recipe still configures a surface that has no
stable typed replacement yet, that builder path should remain an explicit
compatibility appendix instead of being silently deleted.

Reference examples:

- `example/02_core_features/enhanced_tool_calling.dart`
- `example/02_core_features/provider_specific_builders.dart`

## Migration Posture

The practical rule is:

- use stable shared model contracts when they already exist
- use provider-owned typed options for provider-native behavior
- keep the remaining builder-era jobs only where there is still no honest
  stable replacement

That means `ai()` and `build*()` should now be treated as compatibility rails,
not as the default architecture for new code.
