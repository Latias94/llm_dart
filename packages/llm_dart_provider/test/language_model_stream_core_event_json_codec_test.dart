import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider/src/serialization/language_model_stream_core_event_json_codec.dart';
import 'package:test/test.dart';

void main() {
  group('LanguageModelStreamCoreEventJsonCodec', () {
    test('round-trips start warnings', () {
      const codec = LanguageModelStreamCoreEventJsonCodec();

      final decoded = codec.decode(
        codec.encode(
          StartEvent(
            warnings: const [
              ModelWarning(
                type: ModelWarningType.unsupported,
                message: 'temperature is ignored',
                feature: 'temperature',
              ),
            ],
          ),
        ),
        type: 'start',
        path: r'$',
      ) as StartEvent;

      expect(decoded.warnings, hasLength(1));
      expect(decoded.warnings.single.type, ModelWarningType.unsupported);
      expect(decoded.warnings.single.message, 'temperature is ignored');
      expect(decoded.warnings.single.feature, 'temperature');
    });

    test('round-trips response metadata and provider metadata', () {
      const codec = LanguageModelStreamCoreEventJsonCodec();
      final timestamp = DateTime.utc(2026, 5, 20, 1, 30);

      final decoded = codec.decode(
        codec.encode(
          ResponseMetadataEvent(
            responseMetadata: ModelResponseMetadata(
              id: 'resp_1',
              timestamp: timestamp,
              modelId: 'gpt-test',
              headers: const {
                'x-request-id': 'req_1',
              },
            ),
            providerMetadata: ProviderMetadata.forNamespace('openai', {
              'itemId': 'msg_1',
            }),
          ),
        ),
        type: 'response-metadata',
        path: r'$',
      ) as ResponseMetadataEvent;

      expect(decoded.responseId, 'resp_1');
      expect(decoded.timestamp, timestamp);
      expect(decoded.modelId, 'gpt-test');
      expect(decoded.responseMetadata!.headers, {'x-request-id': 'req_1'});
      expect(decoded.providerMetadata!.namespace('openai'), {
        'itemId': 'msg_1',
      });
    });

    test('round-trips finish usage and provider metadata', () {
      const codec = LanguageModelStreamCoreEventJsonCodec();

      final decoded = codec.decode(
        codec.encode(
          FinishEvent(
            finishReason: FinishReason.toolCalls,
            rawFinishReason: 'tool_calls',
            usage: const UsageStats(
              inputTokens: 3,
              outputTokens: 5,
              totalTokens: 8,
              reasoningTokens: 2,
            ),
            providerMetadata: ProviderMetadata.forNamespace('openai', {
              'responseId': 'resp_1',
            }),
          ),
        ),
        type: 'finish',
        path: r'$',
      ) as FinishEvent;

      expect(decoded.finishReason, FinishReason.toolCalls);
      expect(decoded.rawFinishReason, 'tool_calls');
      expect(
        decoded.usage,
        const UsageStats(
          inputTokens: 3,
          outputTokens: 5,
          totalTokens: 8,
          reasoningTokens: 2,
        ),
      );
      expect(decoded.providerMetadata!.namespace('openai'), {
        'responseId': 'resp_1',
      });
    });

    test('owns runtime-only event rejection for provider streams', () {
      const codec = LanguageModelStreamCoreEventJsonCodec();

      expect(codec.canReject('tool-output-denied'), isTrue);
      expect(
        () => codec.decode(
          {
            'type': 'tool-output-denied',
            'toolCallId': 'tool-1',
          },
          type: 'tool-output-denied',
          path: r'$',
        ),
        throwsStateError,
      );
    });
  });
}
