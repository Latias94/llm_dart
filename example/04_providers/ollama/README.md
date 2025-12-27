# Ollama Unique Features

Local AI model deployment for privacy and offline capabilities.

## Examples

### [advanced_features.dart](advanced_features.dart)
Local model deployment, performance optimization, and custom configurations.

### [thinking_example.dart](thinking_example.dart)
Reasoning and thinking capabilities with local models.

## Setup

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Download a model
ollama pull llama3.2

# Start Ollama server
ollama serve

# Run Ollama example
dart run advanced_features.dart
dart run thinking_example.dart
```

## Unique Capabilities

### Local Deployment
- **Complete Privacy**: No data sent to external servers
- **Offline Operation**: Works without internet connection
- **Cost-Free**: No API charges after initial setup

### Performance Control
- **Hardware Optimization**: GPU acceleration and CPU tuning
- **Custom Models**: Import and fine-tune your own models
- **Resource Management**: Control memory and processing allocation

### Reasoning Models
- **Local Thinking**: Run reasoning models completely offline
- **Privacy-First**: No thinking process sent to external servers
- **Cost-Free Reasoning**: No API charges for complex reasoning tasks

## Usage Examples

### Local Model Configuration
```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';

registerOllama();

final provider = await LLMBuilder()
    .provider(ollamaProviderId)
    .baseUrl('http://localhost:11434')
    .model('llama3.2')
    .providerOption('ollama', 'numGpu', 1) // GPU acceleration
    .providerOption('ollama', 'numThread', 8) // CPU threads
    .build();

final result = await generateText(
  model: provider,
  messages: [ChatMessage.user('Explain quantum computing')],
);

// All processing happens locally
print('Local response: ${result.text}');
```

### Privacy-Focused Setup
```dart
// Completely offline operation
final provider = await LLMBuilder()
    .provider(ollamaProviderId)
    .baseUrl('http://localhost:11434')
    .model('phi3') // Lightweight model
    .build();

// No data leaves your machine
final result = await generateText(
  model: provider,
  messages: [ChatMessage.user('Analyze this sensitive document')],
);

print(result.text);
```

### Reasoning Models
```dart
// Local reasoning with thinking process
final provider = await LLMBuilder()
    .provider(ollamaProviderId)
    .baseUrl('http://localhost:11434')
    .model('gpt-oss:latest') // Reasoning model
    .reasoning(true) // Enable reasoning process
    .build();

final result = await generateText(
  model: provider,
  messages: [
    ChatMessage.user('Solve this step by step: What is 15 * 23 + 7 * 11?'),
  ],
);

print('Thinking: ${result.thinking}');
print('Answer: ${result.text}');
```

## Next Steps

- [Core Features](../../02_core_features/) - Basic chat and streaming
- [Advanced Features](../../03_advanced_features/) - Custom provider setup
