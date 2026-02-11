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
  print('\nstreamChatParts:');
  await for (final part in streamChatParts(
    model: provider,
    promptIr: Prompt(
      messages: [
        PromptMessage.user('Count from 1 to 5, one number per token.'),
      ],
    ),
  )) {
    switch (part) {
      case LLMTextDeltaPart(:final delta):
        print('delta: "$delta"');
        break;
      case LLMFinishPart(:final response, :final usage, :final finishReason):
        print('finalText: ${response.text}');
        print('usage: ${usage ?? response.usage}');
        print(
            'finishReason: ${finishReason ?? (response is ChatResponseWithFinishReason ? response.finishReason : null)}');
        print('providerMetadata: ${response.providerMetadata}');
        break;
      case LLMReasoningDeltaPart(:final delta):
        print('thinking: "$delta"');
        break;
      case LLMToolCallDeltaPart(:final toolCall):
        print('toolCall: $toolCall');
        break;
      case LLMToolCallStartPart(:final toolCall):
        print('toolCallStart: $toolCall');
        break;
      case LLMProviderToolCallPart(
          toolCallId: final toolCallId,
          toolName: final toolName,
        ):
        print('providerToolCall: $toolName ($toolCallId)');
        break;
      case LLMProviderToolDeltaPart(
          toolCallId: final toolCallId,
          toolName: final toolName,
          status: final status,
        ):
        print(
          'providerToolDelta: $toolName ($toolCallId) status=$status',
        );
        break;
      case LLMProviderToolApprovalRequestPart(
          approvalId: final approvalId,
          toolCallId: final toolCallId,
          toolName: final toolName,
        ):
        print(
          'providerToolApproval: $toolName ($toolCallId) approvalId=$approvalId',
        );
        break;
      case LLMProviderToolResultPart(
          toolCallId: final toolCallId,
          toolName: final toolName,
        ):
        print('providerToolResult: $toolName ($toolCallId)');
        break;
      case LLMSourceUrlPart(:final url):
        print('sourceUrl: $url');
        break;
      case LLMSourceDocumentPart(:final title, :final mediaType):
        print('sourceDocument: $title ($mediaType)');
        break;
      case LLMErrorPart(:final error):
        print('error: $error');
        break;
      default:
        break;
    }
  }
}
