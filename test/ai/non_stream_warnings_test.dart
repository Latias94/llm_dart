import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final List<ToolCall>? toolCalls;

  const _FakeChatResponse({
    this.text,
    this.toolCalls,
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
  group('non-streaming warnings (AI SDK parity)', () {
    test('generateText surfaces provider tool normalization warnings', () async {
      final model = _FakeIdentityChatModel(
        providerId: 'groq',
        modelId: 'qwen/qwen3-32b',
        response: const _FakeChatResponse(text: 'ok'),
      );

      final result = await generateText(
        model: model,
        messages: [ChatMessage.user('hi')],
        providerTools: const [
          ProviderTool(id: 'groq.browser_search', name: 'browser_search'),
        ],
      );

      expect(result.text, equals('ok'));
      expect(result.warnings, isNotEmpty);
      expect(
        (result.warnings.first as LLMUnsupportedWarning).feature,
        equals('provider-defined tool groq.browser_search'),
      );

      expect(model.lastProviderTools, isNotNull);
      expect(model.lastProviderTools, isEmpty);
    });

    test('generateObject surfaces provider tool normalization warnings',
        () async {
      final model = _FakeIdentityChatModel(
        providerId: 'groq',
        modelId: 'qwen/qwen3-32b',
        response: _FakeChatResponse(
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
      expect(result.warnings, isNotEmpty);
      expect(
        (result.warnings.first as LLMUnsupportedWarning).feature,
        equals('provider-defined tool groq.browser_search'),
      );

      expect(model.lastProviderTools, isNotNull);
      expect(model.lastProviderTools, isEmpty);
    });
  });
}

