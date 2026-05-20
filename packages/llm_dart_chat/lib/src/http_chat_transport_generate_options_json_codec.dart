import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';
import 'http_chat_transport_reasoning_options_json_codec.dart';

final class HttpChatTransportGenerateOptionsJsonCodec {
  final HttpChatTransportReasoningOptionsJsonCodec reasoningCodec;

  const HttpChatTransportGenerateOptionsJsonCodec({
    this.reasoningCodec = const HttpChatTransportReasoningOptionsJsonCodec(),
  });

  HttpChatTransportJsonMap encode(GenerateTextOptions options) {
    return {
      if (options.maxOutputTokens != null)
        'maxOutputTokens': options.maxOutputTokens,
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.stopSequences != null) 'stopSequences': options.stopSequences,
      if (options.topP != null) 'topP': options.topP,
      if (options.topK != null) 'topK': options.topK,
      if (options.presencePenalty != null)
        'presencePenalty': options.presencePenalty,
      if (options.frequencyPenalty != null)
        'frequencyPenalty': options.frequencyPenalty,
      if (options.seed != null) 'seed': options.seed,
      if (options.reasoning != null)
        'reasoning': reasoningCodec.encode(options.reasoning!),
      if (options.includeRawChunks) 'includeRawChunks': true,
    };
  }

  GenerateTextOptions decode(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return const GenerateTextOptions();
    }

    final map = HttpChatTransportJson.asMap(value, path: path);
    return GenerateTextOptions(
      maxOutputTokens: HttpChatTransportJson.asNullableInt(
        map['maxOutputTokens'],
        path: '$path.maxOutputTokens',
      ),
      temperature: HttpChatTransportJson.asNullableDouble(
        map['temperature'],
        path: '$path.temperature',
      ),
      stopSequences: map['stopSequences'] == null
          ? null
          : HttpChatTransportJson.asList(
              map['stopSequences'],
              path: '$path.stopSequences',
            )
              .asMap()
              .entries
              .map(
                (entry) => HttpChatTransportJson.asString(
                  entry.value,
                  path: '$path.stopSequences[${entry.key}]',
                ),
              )
              .toList(growable: false),
      topP: HttpChatTransportJson.asNullableDouble(
        map['topP'],
        path: '$path.topP',
      ),
      topK: HttpChatTransportJson.asNullableInt(
        map['topK'],
        path: '$path.topK',
      ),
      presencePenalty: HttpChatTransportJson.asNullableDouble(
        map['presencePenalty'],
        path: '$path.presencePenalty',
      ),
      frequencyPenalty: HttpChatTransportJson.asNullableDouble(
        map['frequencyPenalty'],
        path: '$path.frequencyPenalty',
      ),
      seed: HttpChatTransportJson.asNullableInt(
        map['seed'],
        path: '$path.seed',
      ),
      reasoning: map['reasoning'] == null
          ? null
          : reasoningCodec.decode(
              map['reasoning'],
              path: '$path.reasoning',
            ),
      includeRawChunks: HttpChatTransportJson.asNullableBool(
            map['includeRawChunks'],
            path: '$path.includeRawChunks',
          ) ??
          false,
    );
  }
}
