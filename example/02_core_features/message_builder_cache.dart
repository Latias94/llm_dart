import 'package:llm_dart/anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;

/// Demonstrates Anthropic prompt caching on the modern model-first API.
///
/// Prompt caching is provider-owned behavior. The shared prompt model carries
/// provider metadata, while the Anthropic package owns the typed request option
/// for tool cache control.
void main() {
  print('=== Anthropic Prompt Cache Metadata Example ===\n');

  demonstrateCachedSystemPrompt();
  demonstrateMixedUserContext();
  demonstrateFileAndImageCacheMetadata();
  demonstrateToolCacheOptions();
  explainStrategy();
}

void demonstrateCachedSystemPrompt() {
  final systemPrompt = core.SystemPromptMessage(
    parts: [
      const core.TextPromptPart('You are a concise research assistant.'),
      core.TextPromptPart(
        'Large static reference: quantum computing uses qubits, gates, '
        'superposition, interference, and error correction.',
        providerMetadata: _anthropicCacheControl(ttl: '1h'),
      ),
    ],
  );

  print('1. System prompt with a cached static reference:');
  _printPrompt(systemPrompt);
}

void demonstrateMixedUserContext() {
  final userPrompt = core.UserPromptMessage(
    parts: [
      const core.TextPromptPart(
        'Based on the reusable context, answer the follow-up question.',
      ),
      core.TextPromptPart(
        'Session context: the user is a computer science student with basic '
        'linear algebra and probability knowledge.',
        providerMetadata: _anthropicCacheControl(ttl: '5m'),
      ),
      const core.TextPromptPart(
        'What are the practical advantages of quantum algorithms?',
      ),
    ],
  );

  print('2. User prompt with short-lived cached session context:');
  _printPrompt(userPrompt);
}

void demonstrateFileAndImageCacheMetadata() {
  final prompt = core.UserPromptMessage(
    parts: [
      const core.TextPromptPart('Compare the cached document and image.'),
      core.FilePromptPart(
        mediaType: 'text/plain',
        filename: 'cached-notes.txt',
        data: const core.FileTextData(
          'Reusable notes about a product launch plan.',
        ),
        providerMetadata: _anthropicCacheControl(ttl: '1h'),
      ),
      core.ImagePromptPart(
        mediaType: 'image/png',
        data: const core.FileBytesData.constBytes([137, 80, 78, 71]),
        providerMetadata: _anthropicCacheControl(ttl: '5m'),
      ),
    ],
  );

  print('3. File and image prompt parts with cache metadata:');
  _printPrompt(prompt);
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
  print('- Put cache metadata on the prompt part that should be cached.');
  print(
      '- Use 1h TTL for stable instructions, large documents, or tool lists.');
  print('- Use 5m TTL for session context that changes during a workflow.');
  print(
      '- Keep cache control provider-owned; shared GenerateTextOptions stays');
  print('  provider-neutral.');
  print('- Combine this prompt with anthropic(...).chatModel(...) and');
  print('  core.generateTextCall(...) when making a live request.');
}

core.ProviderMetadata _anthropicCacheControl({required String ttl}) {
  return core.ProviderMetadata({
    'anthropic': {
      'cacheControl': {
        'type': 'ephemeral',
        'ttl': ttl,
      },
    },
  });
}

void _printPrompt(core.PromptMessage message) {
  print('   role: ${message.role.name}');
  for (var index = 0; index < message.parts.length; index += 1) {
    final part = message.parts[index];
    final cache = part.providerMetadata?.namespace('anthropic')?['cacheControl']
        as Map<String, Object?>?;
    print('   part ${index + 1}: ${part.runtimeType}');
    if (cache != null) {
      print('      cacheControl: $cache');
    }
  }
  print('');
}
