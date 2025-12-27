# Provider-Specific Features

Unique capabilities and specialized features for each AI provider.

## Examples

### [openai/](openai/)
DALL-E image generation and Whisper audio processing.

### [anthropic/](anthropic/)
Extended thinking capabilities and advanced file processing.

### [deepseek/](deepseek/)
Reasoning models with transparent thinking process.

### [groq/](groq/)
Ultra-fast inference optimization.

### [ollama/](ollama/)
Local model deployment and configuration.

### [elevenlabs/](elevenlabs/)
Professional voice synthesis and audio processing.

### [xai/](xai/)
Live search and real-time information access.

### [others/](others/)
OpenAI-compatible provider integrations.

## Setup

```bash
# Set up environment variables for specific providers
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export DEEPSEEK_API_KEY="your-deepseek-key"
export GROQ_API_KEY="your-groq-key"
export ELEVENLABS_API_KEY="your-elevenlabs-key"
export XAI_API_KEY="your-xai-key"

# Run provider-specific examples
dart run openai/image_generation.dart
dart run anthropic/extended_thinking.dart
dart run xai/live_search.dart
```

## Provider-Specific Features

### OpenAI Unique Capabilities
- **DALL-E**: Advanced image generation and editing
- **Whisper**: Professional audio transcription
- **GPT-4 Vision**: Image analysis and understanding
- **Responses API**: Provider-native tools (web search, file search, computer use)

### Anthropic Unique Capabilities
- **Extended Thinking**: Access to Claude's reasoning process
- **File Processing**: Advanced document analysis
- **Safety Features**: Built-in content filtering

### DeepSeek Unique Capabilities
- **Reasoning Models**: Transparent thinking process
- **Cost Efficiency**: High performance at low cost

### Groq Unique Capabilities
- **Ultra-Fast Inference**: Optimized hardware acceleration
- **Low Latency**: Real-time response streaming

### Ollama Unique Capabilities
- **Local Deployment**: Privacy-focused local models
- **Custom Models**: Fine-tuned model support

### ElevenLabs Unique Capabilities
- **Voice Cloning**: Custom voice generation
- **Real-time Audio**: Streaming voice synthesis

### XAI Unique Capabilities
- **Live Search**: Real-time web information access
- **Current Events**: Up-to-date news and data

## Usage Examples

### OpenAI Image Generation
```dart
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

registerOpenAI();

final imageProvider = await LLMBuilder()
    .provider(openaiProviderId)
    .apiKey('your-key')
    .model('dall-e-3')
    .buildImageGeneration();

final images = await imageProvider.generateImage(
  prompt: 'A futuristic cityscape at sunset',
  imageSize: '1024x1024',
);
```

### Anthropic Extended Thinking
```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';

registerAnthropic();

final provider = await LLMBuilder()
    .provider(anthropicProviderId)
    .apiKey('your-key')
    .model('claude-sonnet-4-20250514')
    .option('reasoning', true)
    .build();

final result = await generateText(
  model: provider,
  messages: [ChatMessage.user('Solve this logic puzzle step by step')],
);

// Access Claude's thinking process
if (result.thinking != null) {
  print('Claude\'s reasoning: ${result.thinking}');
}
```

### DeepSeek Reasoning
```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';

registerDeepSeek();

final provider = await LLMBuilder()
    .provider(deepseekProviderId)
    .apiKey('your-key')
    .model('deepseek-reasoner')
    .build();

final result = await generateText(
  model: provider,
  messages: [ChatMessage.user('Analyze this complex problem')],
);

// View transparent thinking process
print('AI thinking: ${result.thinking}');
```

### XAI Live Search
```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';

registerXAI();

final provider = await LLMBuilder()
    .provider(xaiProviderId)
    .apiKey('your-key')
    .model('grok-beta')
    .option('liveSearch', true)
    .build();

final result = await generateText(
  model: provider,
  messages: [ChatMessage.user('What are the latest AI developments this week?')],
);

print(result.text);
print(result.providerMetadata);
```

## Best Practices

### Feature Selection
- Use provider-specific features for optimal results
- Combine multiple providers for comprehensive solutions
- Consider cost and performance trade-offs
- Test unique capabilities with your use cases

### Implementation
- Use specialized build methods for type safety
- Handle provider-specific errors appropriately
- Cache expensive operations (image generation, audio processing)
- Monitor usage and costs for premium features

## Next Steps

- [Core Features](../02_core_features/) - Essential functionality for all providers
- [Advanced Features](../03_advanced_features/) - Cross-provider advanced capabilities
- [Use Cases](../05_use_cases/) - Complete applications and Flutter integration
- [Getting Started](../01_getting_started/) - Environment setup and configuration
