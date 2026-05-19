import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_json_support.dart';
import 'openai_chat_completions_stream_state.dart';
import 'openai_chat_completions_support.dart';

final class OpenAIChatCompletionsStreamMetadataAdapter {
  final OpenAIChatCompletionsSupport support;
  final OpenAIChatCompletionsStreamState state;
  final Map<String, Object?> chunk;

  const OpenAIChatCompletionsStreamMetadataAdapter({
    required this.support,
    required this.state,
    required this.chunk,
  });

  ProviderMetadata? response() => support.providerMetadata({
        'responseId': state.responseId,
      });

  ProviderMetadata? reasoning() => support.providerMetadata({
        'responseId': state.responseId,
      });

  ProviderMetadata? text(List<Object?>? logprobs) => support.providerMetadata({
        'responseId': state.responseId,
        'logprobs': logprobs,
      });

  ProviderMetadata? tool(int index) => support.providerMetadata({
        'responseId': state.responseId,
        'toolIndex': index,
      });

  ProviderMetadata? finish() => support.providerMetadata({
        'responseId': state.responseId,
        'systemFingerprint':
            openAIChatCompletionsAsString(chunk['system_fingerprint']),
        if (state.logprobs.isNotEmpty)
          'logprobs': List<Object?>.unmodifiable(state.logprobs),
      });
}
