import 'package:llm_dart/anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;

/// Demonstrates Anthropic prompt caching on the modern model-first API.
///
/// Prompt caching is provider-owned behavior. App-facing model messages carry
/// typed provider options for request-side cache control, while provider
/// metadata remains output-side replay and observation data.
void main() {
  print('=== Anthropic Prompt Cache Options Example ===\n');

  demonstrateCachedSystemPrompt();
  demonstrateMixedUserContext();
  demonstrateFileAndImageCacheMetadata();
  demonstrateToolCacheOptions();
  explainStrategy();
}

void demonstrateCachedSystemPrompt() {
  final systemMessages = [
    const core.SystemModelMessage.text(
      'You are a concise research assistant.',
    ),
    core.SystemModelMessage.text(
      'Large static reference: quantum computing uses qubits, gates, '
      'superposition, interference, and error correction.',
      providerOptions: _anthropicCacheOptions(ttl: '1h'),
    ),
  ];

  print('1. System prompt with a cached static reference:');
  for (final message in systemMessages) {
    _printMessage(message);
  }
  print('');
}

void demonstrateMixedUserContext() {
  final userMessage = core.UserModelMessage(
    parts: [
      const core.TextModelPart(
        'Based on the reusable context, answer the follow-up question.',
      ),
      core.TextModelPart(
        'Session context: the user is a computer science student with basic '
        'linear algebra and probability knowledge.',
        providerOptions: _anthropicCacheOptions(ttl: '5m'),
      ),
      const core.TextModelPart(
        'What are the practical advantages of quantum algorithms?',
      ),
    ],
  );

  print('2. User prompt with short-lived cached session context:');
  _printMessage(userMessage);
  print('');
}

void demonstrateFileAndImageCacheMetadata() {
  final message = core.UserModelMessage(
    parts: [
      const core.TextModelPart('Compare the cached document and image.'),
      core.FileModelPart(
        mediaType: 'text/plain',
        filename: 'cached-notes.txt',
        data: const core.FileTextData(
          'Reusable notes about a product launch plan.',
        ),
        providerOptions: _anthropicCacheOptions(ttl: '1h'),
      ),
      core.ImageModelPart(
        mediaType: 'image/png',
        data: const core.FileBytesData.constBytes([137, 80, 78, 71]),
        providerOptions: _anthropicCacheOptions(ttl: '5m'),
      ),
    ],
  );

  print('3. File and image prompt parts with cache options:');
  _printMessage(message);
  print('');
}

void demonstrateToolCacheOptions() {
  final tools = [
    core.FunctionToolDefinition(
      name: 'search_documents',
      description: 'Search the product knowledge base.',
      inputSchema: core.ToolJsonSchema.object(
        properties: {
          'query': {'type': 'string'},
        },
        required: ['query'],
      ),
    ),
    core.FunctionToolDefinition(
      name: 'get_release_status',
      description: 'Get the current release status.',
      inputSchema: core.ToolJsonSchema.object(
        properties: {
          'releaseId': {'type': 'string'},
        },
        required: ['releaseId'],
      ),
    ),
  ];

  const providerOptions = anthropic.AnthropicGenerateTextOptions(
    toolsCacheControl: anthropic.AnthropicCacheControl.ephemeral(ttl: '1h'),
  );

  print('4. Tool cache control stays in AnthropicGenerateTextOptions:');
  print('   tools: ${tools.map((tool) => tool.name).join(', ')}');
  print(
    '   cacheControl: '
    '${providerOptions.toolsCacheControl?.toJson()}',
  );
  print('');
}

void explainStrategy() {
  print('=== Caching Strategy Tips ===');
  print('- Put cache options on the prompt part that should be cached.');
  print(
      '- Use 1h TTL for stable instructions, large documents, or tool lists.');
  print('- Use 5m TTL for session context that changes during a workflow.');
  print(
      '- Keep cache control provider-owned; shared GenerateTextOptions stays');
  print('  provider-neutral.');
  print('- Combine this prompt with anthropic(...).chatModel(...) and');
  print('  core.generateTextCall(...) when making a live request.');
}

anthropic.AnthropicPromptPartOptions _anthropicCacheOptions({
  required String ttl,
}) {
  return anthropic.AnthropicPromptPartOptions(
    cacheControl: anthropic.AnthropicCacheControl.ephemeral(ttl: ttl),
  );
}

void _printMessage(core.ModelMessage message) {
  print('   role: ${message.role.name}');
  final parts = switch (message) {
    core.SystemModelMessage(:final providerOptions) => [
        _PrintablePart('TextModelPart', providerOptions),
      ],
    core.UserModelMessage(:final parts) => [
        for (final part in parts)
          _PrintablePart(part.runtimeType.toString(), part.providerOptions),
      ],
    core.AssistantModelMessage(:final parts) => [
        for (final part in parts)
          _PrintablePart(part.runtimeType.toString(), part.providerOptions),
      ],
    core.ToolModelMessage(:final parts) => [
        for (final part in parts)
          _PrintablePart(part.runtimeType.toString(), part.providerOptions),
      ],
  };

  for (var index = 0; index < parts.length; index += 1) {
    final part = parts[index];
    final cache = part.cacheControlJson;
    print('   part ${index + 1}: ${part.typeName}');
    if (cache != null) {
      print('      cacheControl: $cache');
    }
  }
}

final class _PrintablePart {
  final String typeName;
  final core.ProviderPromptPartOptions? providerOptions;

  const _PrintablePart(this.typeName, this.providerOptions);

  Map<String, Object?>? get cacheControlJson {
    final options = providerOptions;
    return options is anthropic.AnthropicPromptPartOptions
        ? options.cacheControl?.toJson()
        : null;
  }

  @override
  String toString() => typeName;
}
