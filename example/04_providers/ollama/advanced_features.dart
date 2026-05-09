// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama_pkg;

/// Modern Ollama local-runtime tuning on the shared Ollama package surface.
///
/// These examples stay honest about provider-specific controls by keeping local
/// runtime knobs in `ollama_pkg.OllamaGenerateTextOptions`, while chat,
/// streaming, tools, and structured output stay on shared contracts.
Future<void> main() async {
  final baseUrl = Platform.environment['OLLAMA_BASE_URL'] ??
      ollama_pkg.Ollama.defaultBaseUrl;

  print('Ollama Advanced Features - Performance And Optimization\n');

  await demonstratePerformanceOptimization(baseUrl);
  await demonstrateContextManagement(baseUrl);
  await demonstrateStructuredOutput(baseUrl);
  await demonstrateModelMemoryManagement(baseUrl);
  await demonstrateToolCalling(baseUrl);

  print('Ollama advanced features completed.');
}

Future<void> demonstratePerformanceOptimization(String baseUrl) async {
  print('=== Performance Optimization ===\n');

  try {
    print('High-performance configuration:');
    final highPerfResult = await _generateTextPrompt(
      model: _model(baseUrl, 'llama3.2'),
      prompt: [
        core.UserPromptMessage.text(
            'Explain quantum computing in 3 sentences.'),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.7,
        maxOutputTokens: 160,
      ),
      providerOptions: const ollama_pkg.OllamaGenerateTextOptions(
        numCtx: 4096,
        numGpu: 1,
        numThread: 8,
        numa: false,
        numBatch: 512,
        keepAlive: '10m',
      ),
    );
    print('  ${highPerfResult.text}\n');

    print('Memory-efficient configuration:');
    final memoryEfficientResult = await _generateTextPrompt(
      model: _model(baseUrl, 'llama3.2'),
      prompt: [
        core.UserPromptMessage.text('What is machine learning?'),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.7,
        maxOutputTokens: 120,
      ),
      providerOptions: const ollama_pkg.OllamaGenerateTextOptions(
        numCtx: 2048,
        numGpu: 0,
        numThread: 4,
        numBatch: 128,
        keepAlive: '2m',
      ),
    );
    print('  ${memoryEfficientResult.text}\n');

    print('Performance optimization demonstration completed.\n');
  } catch (error) {
    print('Performance optimization failed: $error\n');
  }
}

Future<void> demonstrateContextManagement(String baseUrl) async {
  print('=== Context Management ===\n');

  try {
    final model = _model(baseUrl, 'llama3.2');
    final longContextOptions = const ollama_pkg.OllamaGenerateTextOptions(
      numCtx: 8192,
      keepAlive: '10m',
    );

    final conversation = <core.PromptMessage>[
      core.SystemPromptMessage.text(
        'You are a helpful assistant with excellent memory.',
      ),
      core.UserPromptMessage.text(
        'I am planning a trip to Japan. What should I know?',
      ),
    ];

    var result = await _generateTextPrompt(
      model: model,
      prompt: conversation,
      providerOptions: longContextOptions,
    );
    conversation.add(core.AssistantPromptMessage.text(result.text));
    print('Assistant: ${_truncate(result.text, maxLength: 120)}\n');

    conversation.add(
      core.UserPromptMessage.text('What about the best time to visit?'),
    );
    result = await _generateTextPrompt(
      model: model,
      prompt: conversation,
      providerOptions: longContextOptions,
    );
    conversation.add(core.AssistantPromptMessage.text(result.text));
    print('Assistant: ${_truncate(result.text, maxLength: 120)}\n');

    conversation.add(
      core.UserPromptMessage.text('And what about food recommendations?'),
    );
    result = await _generateTextPrompt(
      model: model,
      prompt: conversation,
      providerOptions: longContextOptions,
    );
    print('Assistant: ${_truncate(result.text, maxLength: 120)}\n');

    print('Context tips:');
    print('  - larger numCtx uses more memory but preserves more history');
    print('  - keepAlive helps avoid repeated model reloads');
    print('  - conversation state stays in app-owned prompt history');
    print('Context management demonstration completed.\n');
  } catch (error) {
    print('Context management failed: $error\n');
  }
}

Future<void> demonstrateStructuredOutput(String baseUrl) async {
  print('=== Structured Output ===\n');

  try {
    final result = await core.generateTextCall<ProductReview>(
      model: _model(baseUrl, 'llama3.2'),
      prompt: [
        core.UserPromptMessage.text(
          'Review this product: "Wireless headphones with 30-hour battery '
          'life, noise cancellation, and comfortable fit. Price: \$150."',
        ),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.1,
      ),
      outputSpec: core.ObjectOutputSpec<ProductReview>(
        schema: core.JsonSchema.object(
          properties: const {
            'rating': {'type': 'integer', 'minimum': 1, 'maximum': 5},
            'summary': {'type': 'string'},
            'pros': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'cons': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'recommended': {'type': 'boolean'},
          },
          required: const ['rating', 'summary', 'pros', 'cons', 'recommended'],
          additionalProperties: false,
        ),
        decode: ProductReview.fromJson,
      ),
      callOptions: const core.CallOptions(
        providerOptions: ollama_pkg.OllamaGenerateTextOptions(
          numCtx: 4096,
          keepAlive: '5m',
        ),
      ),
    );

    print('Rating: ${result.output.rating}');
    print('Summary: ${result.output.summary}');
    print('Pros: ${result.output.pros.join(', ')}');
    print('Cons: ${result.output.cons.join(', ')}');
    print('Recommended: ${result.output.recommended}');
    print('Structured output demonstration completed.\n');
  } catch (error) {
    print('Structured output failed: $error\n');
  }
}

Future<void> demonstrateModelMemoryManagement(String baseUrl) async {
  print('=== Model Memory Management ===\n');

  try {
    await _generateTextPrompt(
      model: _model(baseUrl, 'llama3.2'),
      prompt: [
        core.UserPromptMessage.text('Say hello in one sentence.'),
      ],
      providerOptions: const ollama_pkg.OllamaGenerateTextOptions(
        keepAlive: '30s',
      ),
    );
    print('Short-lived model configured with keepAlive=30s');

    await _generateTextPrompt(
      model: _model(baseUrl, 'llama3.2'),
      prompt: [
        core.UserPromptMessage.text('Say hello in one sentence.'),
      ],
      providerOptions: const ollama_pkg.OllamaGenerateTextOptions(
        keepAlive: '30m',
      ),
    );
    print('Long-lived model configured with keepAlive=30m');

    print('Memory tips:');
    print('  - short keepAlive reduces idle memory usage');
    print('  - long keepAlive avoids repeated warm-up cost');
    print('  - tune this per workload, not as a global abstraction');
    print('Model memory management demonstration completed.\n');
  } catch (error) {
    print('Model memory management failed: $error\n');
  }
}

Future<void> demonstrateToolCalling(String baseUrl) async {
  print('=== Tool Calling ===\n');

  final weatherTool = core.FunctionToolDefinition(
    name: 'get_weather',
    description: 'Get current weather for a location',
    inputSchema: core.ToolJsonSchema.object(
      properties: const {
        'location': {
          'type': 'string',
          'description': 'City and country, for example "Tokyo, JP".',
        },
        'unit': {
          'type': 'string',
          'enum': ['celsius', 'fahrenheit'],
        },
      },
      required: const ['location'],
    ),
  );

  try {
    final result = await core.generateTextCall<void>(
      model: _model(baseUrl, 'llama3.2'),
      prompt: [
        core.UserPromptMessage.text('What is the weather like in Tokyo?'),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.1,
        maxOutputTokens: 300,
      ),
      tools: [weatherTool],
      callOptions: const core.CallOptions(
        providerOptions: ollama_pkg.OllamaGenerateTextOptions(
          numCtx: 4096,
          keepAlive: '5m',
        ),
      ),
    );

    final toolCalls =
        result.content.whereType<core.ToolCallContentPart>().toList();
    if (toolCalls.isNotEmpty) {
      print('Tool calls:');
      for (final toolCallPart in toolCalls) {
        final toolCall = toolCallPart.toolCall;
        print('  Tool: ${toolCall.toolName}');
        print('  Arguments: ${toolCall.input}');
      }
    } else {
      print('Text response: ${result.text}');
    }

    if (result.warnings.isNotEmpty) {
      print('Warnings:');
      for (final warning in result.warnings) {
        print('  ${warning.field}: ${warning.message}');
      }
    }

    print('Tool calling demonstration completed.\n');
  } catch (error) {
    print('Tool calling failed: $error\n');
  }
}

core.LanguageModel _model(String baseUrl, String modelId) {
  return ollama_pkg.Ollama(
    baseUrl: baseUrl,
  ).chatModel(modelId);
}

Future<core.GenerateTextCallResult<void>> _generateTextPrompt({
  required core.LanguageModel model,
  required List<core.PromptMessage> prompt,
  ollama_pkg.OllamaGenerateTextOptions providerOptions =
      const ollama_pkg.OllamaGenerateTextOptions(),
  core.GenerateTextOptions options = const core.GenerateTextOptions(),
}) {
  return core.generateTextCall<void>(
    model: model,
    prompt: prompt,
    options: options,
    callOptions: core.CallOptions(
      providerOptions: providerOptions,
    ),
  );
}

String _truncate(String text, {required int maxLength}) {
  if (text.length <= maxLength) {
    return text;
  }

  return '${text.substring(0, maxLength)}...';
}

final class ProductReview {
  final int rating;
  final String summary;
  final List<String> pros;
  final List<String> cons;
  final bool recommended;

  const ProductReview({
    required this.rating,
    required this.summary,
    required this.pros,
    required this.cons,
    required this.recommended,
  });

  factory ProductReview.fromJson(Map<String, Object?> json) {
    return ProductReview(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String? ?? '',
      pros: _readStringList(json['pros']),
      cons: _readStringList(json['cons']),
      recommended: json['recommended'] as bool? ?? false,
    );
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return List<String>.unmodifiable(
      value.whereType<String>(),
    );
  }
}
