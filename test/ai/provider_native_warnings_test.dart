import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/google.dart';
import 'package:test/test.dart';

import '../utils/fakes/google_fake_client.dart';

class _FakeChatResponseWithWarnings
    implements ChatResponse, ChatResponseWithWarnings {
  @override
  final String? text;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final List<LLMWarning> warnings;

  const _FakeChatResponseWithWarnings({
    this.text,
    this.toolCalls,
    this.warnings = const <LLMWarning>[],
  });

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

class _FakeIdentityChatModel extends ChatCapability
    implements ModelIdentityCapability, ProviderCapabilities {
  @override
  final String providerId;

  @override
  final String modelId;

  List<ProviderTool>? lastProviderTools;
  ChatResponse response;

  _FakeIdentityChatModel({
    required this.providerId,
    required this.modelId,
    required this.response,
  });

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    lastProviderTools = providerTools;
    return response;
  }

  @override
  Set<LLMCapability> get supportedCapabilities => const {
        LLMCapability.chat,
      };

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

void main() {
  group('provider native warnings (AI SDK parity)', () {
    test('generateText merges provider warnings with normalization warnings',
        () async {
      final model = _FakeIdentityChatModel(
        providerId: 'groq',
        modelId: 'qwen/qwen3-32b',
        response: const _FakeChatResponseWithWarnings(
          text: 'ok',
          warnings: [LLMOtherWarning('provider-warning')],
        ),
      );

      final result = await generateText(
        model: model,
        messages: [ChatMessage.user('hi')],
        providerTools: const [
          ProviderTool(id: 'groq.browser_search', name: 'browser_search'),
        ],
      );

      expect(result.text, equals('ok'));
      expect(result.warnings, hasLength(2));
      expect(result.warnings.first, isA<LLMUnsupportedWarning>());
      expect(
        (result.warnings.first as LLMUnsupportedWarning).feature,
        equals('provider-defined tool groq.browser_search'),
      );
      expect(result.warnings.last, isA<LLMOtherWarning>());
      expect(
        (result.warnings.last as LLMOtherWarning).message,
        equals('provider-warning'),
      );
    });

    test('generateObject merges provider warnings with normalization warnings',
        () async {
      final model = _FakeIdentityChatModel(
        providerId: 'groq',
        modelId: 'qwen/qwen3-32b',
        response: _FakeChatResponseWithWarnings(
          toolCalls: [
            ToolCall(
              id: '1',
              callType: 'function',
              function: FunctionCall(
                name: 'return_object',
                arguments: '{"ok":"yes"}',
              ),
            ),
          ],
          warnings: const [LLMOtherWarning('provider-warning')],
        ),
      );

      final schema = ParametersSchema(
        schemaType: 'object',
        properties: const {
          'ok': ParameterProperty(propertyType: 'string', description: 'ok'),
        },
        required: ['ok'],
      );

      final result = await generateObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
        providerTools: const [
          ProviderTool(id: 'groq.browser_search', name: 'browser_search'),
        ],
      );

      expect(result.object['ok'], equals('yes'));
      expect(result.warnings, hasLength(2));
      expect(result.warnings.first, isA<LLMUnsupportedWarning>());
      expect(
        (result.warnings.first as LLMUnsupportedWarning).feature,
        equals('provider-defined tool groq.browser_search'),
      );
      expect(result.warnings.last, isA<LLMOtherWarning>());
    });

    test('GoogleProvider: generateText surfaces provider tool warnings',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        webSearchEnabled: true,
      );

      final endpoint = 'models/${config.model}:generateContent';
      final client = FakeGoogleClient(
        config,
        responsesByEndpoint: {
          endpoint: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'}
                  ],
                },
              },
            ],
          },
        },
      );
      final provider = GoogleProvider(config, client: client);

      final result = await generateText(
        model: provider,
        messages: [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      );

      expect(result.text, equals('ok'));
      expect(result.warnings, isNotEmpty);

      final anyUnsupportedMix = result.warnings.any(
        (w) =>
            w is LLMUnsupportedWarning &&
            w.feature == 'combination of function and provider-defined tools',
      );
      expect(anyUnsupportedMix, isTrue);
    });
  });
}
