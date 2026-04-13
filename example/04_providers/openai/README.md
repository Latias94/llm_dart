# OpenAI Provider Features

OpenAI is one of the providers with the broadest stable surface in the
refactored architecture.

For new code, prefer:

- `AI.openai(...).chatModel(...)`
- `AI.openai(...).imageModel(...)`
- `AI.openai(...).speechModel(...)`
- `AI.openai(...).transcriptionModel(...)`
- shared helpers from `package:llm_dart/core.dart`
- typed OpenAI-owned options from `package:llm_dart/openai.dart`

## Example Status

### Stable or Mostly Stable Source Files

- [advanced_features.dart](advanced_features.dart)
- [image_generation.dart](image_generation.dart)
- [image_and_file_messages.dart](image_and_file_messages.dart)
- [audio_capabilities.dart](audio_capabilities.dart)
- [gpt5_features.dart](gpt5_features.dart)

### Transitional or Compatibility-Oriented Source Files

- [responses_api.dart](responses_api.dart)
- [build_openai_responses_demo.dart](build_openai_responses_demo.dart)

These two files are intentionally boundary-oriented. They now explain when
stable `chatModel(...)` usage is sufficient and when raw OpenAI response
lifecycle APIs still require the provider-specific compatibility surface.

The stable model surfaces already exist even where some provider-specific
example files still document older builder flows.

## Setup

```bash
export OPENAI_API_KEY="your-openai-api-key"

dart run image_generation.dart
dart run image_and_file_messages.dart
dart run audio_capabilities.dart
dart run gpt5_features.dart
dart run advanced_features.dart
dart run responses_api.dart
dart run build_openai_responses_demo.dart
```

## Stable Usage Examples

### Chat With Built-In Tools

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

final model = llm.AI.openai(apiKey: 'your-key').chatModel('gpt-5-mini');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Search for recent AI developments.'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: openai.OpenAIGenerateTextOptions(
      builtInTools: [
        openai.OpenAIWebSearchTool(),
      ],
    ),
  ),
);

print(result.text);
```

### Image Generation

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

final imageModel = llm.AI.openai(apiKey: 'your-key').imageModel('dall-e-3');

final result = await core.generateImage(
  model: imageModel,
  prompt: 'A futuristic cityscape',
  count: 1,
  size: '1024x1024',
  callOptions: const core.CallOptions(
    providerOptions: openai.OpenAIImageOptions(
      quality: openai.OpenAIImageQuality.high,
      style: openai.OpenAIImageStyle.vivid,
    ),
  ),
);

print(result.images.first.uri);
```

### Speech Generation and Transcription

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

final speechModel = llm.AI.openai(apiKey: 'your-key').speechModel('gpt-4o-mini-tts');
final transcriptModel = llm.AI.openai(apiKey: 'your-key').transcriptionModel('whisper-1');

final speech = await core.generateSpeech(
  model: speechModel,
  text: 'Hello from llm_dart.',
  voice: 'alloy',
  callOptions: const core.CallOptions(
    providerOptions: openai.OpenAISpeechOptions(
      outputFormat: 'wav',
      speed: 1.0,
    ),
  ),
);

final transcript = await core.transcribe(
  model: transcriptModel,
  audioBytes: speech.audioBytes,
  mediaType: speech.mediaType,
  callOptions: const core.CallOptions(
    providerOptions: openai.OpenAITranscriptionOptions(
      responseFormat: openai.OpenAITranscriptionResponseFormat.text,
    ),
  ),
);

print(transcript.text);
```

### GPT-5 Verbosity and Reasoning Controls

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

final model = llm.AI.openai(apiKey: 'your-key').chatModel('gpt-5.1');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Explain how photosynthesis works.'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: openai.OpenAIGenerateTextOptions(
      verbosity: 'high',
      reasoningEffort: openai.OpenAIReasoningEffort.minimal,
    ),
  ),
);

print(result.text);
print(result.usage?.reasoningTokens);
```

### Stable Multimodal Prompt Parts

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

final model = llm.AI.openai(apiKey: 'your-key').chatModel('gpt-4o');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage(
      parts: [
        const core.TextPromptPart('Describe this image in one sentence.'),
        core.ImagePromptPart(
          mediaType: 'image/jpeg',
          uri: Uri.parse('https://example.com/cat.jpg'),
        ),
      ],
    ),
  ],
);

print(result.text);
```

## Capability Notes

### Stable Today

- provider-owned built-in tools through `OpenAIGenerateTextOptions`
- model-level defaults through `OpenAIChatModelSettings`
- image generation through `OpenAIImageOptions`
- speech generation through `OpenAISpeechOptions`
- transcription through `OpenAITranscriptionOptions`
- GPT-5 verbosity and reasoning-effort controls through
  `OpenAIGenerateTextOptions`
- multimodal prompt parts through shared `ImagePromptPart` and `FilePromptPart`

### Still Compatibility-Oriented

- `buildAssistant()` and the legacy assistants surface
- direct `buildOpenAIResponses()` convenience examples
- raw response lifecycle helpers that expose provider-specific response objects

Those compatibility paths still work, but they should not be treated as the
target architecture for new Flutter or app-facing integrations.

## Next Steps

- [Core Features](../../02_core_features/) - Stable text and streaming patterns
- [Advanced Features](../../03_advanced_features/) - Shared reasoning and tools
- [Use Cases](../../05_use_cases/) - Complete app integration examples
