// ignore_for_file: avoid_print
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

/// OpenAI-compatible custom providers (gateway / local server).
///
/// This example mirrors Vercel AI SDK's `createOpenAICompatible({ name, baseURL, ... })`
/// concept: instead of relying on shipped presets, you can register your own
/// OpenAI-compatible provider id and point it at a base URL.
///
/// Typical targets:
/// - LM Studio local server (usually `http://localhost:1234/v1/`)
/// - LiteLLM gateway (your own `https://.../v1/`)
/// - Other OpenAI-compatible proxies
///
/// Notes:
/// - API keys are optional for OpenAI-compatible endpoints. If your gateway
///   needs auth, prefer providerOptions `headers` (or set `apiKey`).
/// - For streaming usage metrics, set providerOptions `includeUsage=true`.
void main() async {
  print('OpenAI-compatible custom providers demo\n');

  // Register a custom provider id.
  //
  // Choose a stable providerId; this becomes your `LLMBuilder().provider(id)`.
  registerCustomOpenAICompatibleProvider(
    const OpenAICompatibleProviderConfig(
      providerId: 'lmstudio',
      displayName: 'LM Studio (local, OpenAI-compatible)',
      description: 'Local LM Studio server via OpenAI-compatible API.',
      defaultBaseUrl: 'http://localhost:1234/v1/',
      defaultModel: 'local-model',
      supportedCapabilities: {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.embedding,
      },
    ),
    replace: true,
  );

  // Build a provider.
  //
  // If your endpoint needs auth, either:
  // - set `.apiKey('...')` (Authorization: Bearer <apiKey>), or
  // - set providerOptions `headers` for custom auth schemes.
  final provider = await LLMBuilder()
      .provider('lmstudio')
      .baseUrl('http://localhost:1234/v1/')
      .model('local-model')
      .providerOptions('lmstudio', const {
    // Extra request headers:
    // 'headers': {'Authorization': 'Bearer ...'},

    // Extra URL query parameters:
    // 'queryParams': {'api-version': '2024-10-21'},

    // Include usage in streaming responses (if supported by your server):
    'includeUsage': true,
  }).build();

  // Non-streaming call.
  final result = await generateText(
    model: provider,
    promptIr: Prompt(
      messages: [
        PromptMessage.user('Reply with exactly the single word: pong')
      ],
    ),
  );
  print('generateText: ${result.text}');

  // Streaming call (parts).
  print('\nstreamText:');
  await for (final part in streamText(
    model: provider,
    promptIr: Prompt(
      messages: [
        PromptMessage.user('Count from 1 to 5, one number per token.'),
      ],
    ),
  )) {
    switch (part) {
      case TextDeltaPart():
        print('delta: "${part.delta}"');
        break;
      case FinishPart():
        print('finalText: ${part.result.text}');
        print('usage: ${part.result.usage}');
        print('providerMetadata: ${part.result.providerMetadata}');
        break;
      case ThinkingDeltaPart():
        print('thinking: "${part.delta}"');
        break;
      case ToolCallDeltaPart():
        print('toolCall: ${part.toolCall}');
        break;
      case ErrorPart():
        print('error: ${part.error}');
        break;
    }
  }
}
