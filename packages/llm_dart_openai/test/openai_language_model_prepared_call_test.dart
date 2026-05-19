import 'package:llm_dart_openai/src/openai_chat_completions_codec.dart';
import 'package:llm_dart_openai/src/openai_family_profile.dart';
import 'package:llm_dart_openai/src/openai_language_model_prepared_call.dart';
import 'package:llm_dart_openai/src/openai_language_model_support.dart';
import 'package:llm_dart_openai/src/openai_options.dart';
import 'package:llm_dart_openai/src/openai_responses_codec.dart';
import 'package:llm_dart_openai/src/resolved_openai_chat_settings.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('prepareOpenAILanguageModelCall', () {
    test('prepares Responses request body, headers, call options, and warnings',
        () {
      final cancellation = TransportCancellation();

      final preparedCall = prepareOpenAILanguageModelCall(
        request: GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Say hello.'),
          ],
          options: const GenerateTextOptions(
            presencePenalty: 0.1,
          ),
          callOptions: CallOptions(
            headers: const {
              'x-extra': '1',
            },
            timeout: const Duration(seconds: 3),
            maxRetries: 4,
            cancellation: cancellation,
          ),
        ),
        modelId: 'gpt-4.1-mini',
        baseUrl: 'https://api.openai.test/v1',
        profile: const OpenAIProfile(),
        apiKey: 'test-key',
        settings: const ResolvedOpenAIChatModelSettings(
          common: OpenAIChatModelSettings(),
        ),
        stream: false,
        responsesCodec: const OpenAIResponsesCodec(),
        chatCompletionsCodec: const OpenAIChatCompletionsCodec(),
      );

      expect(preparedCall.call.route, OpenAIRequestRoute.responses);
      expect(preparedCall.transportRequest.uri.toString(),
          'https://api.openai.test/v1/responses');
      expect(preparedCall.transportRequest.method, TransportMethod.post);
      expect(
        preparedCall.transportRequest.headers,
        containsPair('authorization', 'Bearer test-key'),
      );
      expect(
        preparedCall.transportRequest.headers,
        containsPair('accept', 'application/json'),
      );
      expect(
          preparedCall.transportRequest.headers, containsPair('x-extra', '1'));
      expect(preparedCall.transportRequest.timeout, const Duration(seconds: 3));
      expect(preparedCall.transportRequest.maxRetries, 4);
      expect(
          identical(preparedCall.transportRequest.cancellation, cancellation),
          isTrue);

      final body = preparedCall.transportRequest.body as Map<String, Object?>;
      expect(body, containsPair('model', 'gpt-4.1-mini'));
      expect(body, containsPair('stream', false));
      expect(
        preparedCall.warnings.map((warning) => warning.field),
        contains('options.presencePenalty'),
      );
    });

    test('prepares Chat Completions request when Responses API is disabled',
        () {
      final preparedCall = prepareOpenAILanguageModelCall(
        request: GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Say hello.'),
          ],
        ),
        modelId: 'gpt-4.1-mini',
        baseUrl: 'https://api.openai.test/v1',
        profile: const OpenAIProfile(),
        apiKey: 'test-key',
        settings: const ResolvedOpenAIChatModelSettings(
          common: OpenAIChatModelSettings(
            useResponsesApi: false,
          ),
        ),
        stream: true,
        responsesCodec: const OpenAIResponsesCodec(),
        chatCompletionsCodec: const OpenAIChatCompletionsCodec(),
      );

      expect(preparedCall.call.route, OpenAIRequestRoute.chatCompletions);
      expect(preparedCall.transportRequest.uri.toString(),
          'https://api.openai.test/v1/chat/completions');
      expect(
        preparedCall.transportRequest.headers,
        containsPair('accept', 'text/event-stream'),
      );

      final body = preparedCall.transportRequest.body as Map<String, Object?>;
      expect(body, containsPair('model', 'gpt-4.1-mini'));
      expect(body, containsPair('stream', true));
      expect(body['messages'], isA<List<Object?>>());
    });
  });
}
