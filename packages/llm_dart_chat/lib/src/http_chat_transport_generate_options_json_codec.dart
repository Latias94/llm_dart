import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';

final class HttpChatTransportGenerateOptionsJsonCodec {
  const HttpChatTransportGenerateOptionsJsonCodec();

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
        'reasoning': _encodeReasoningOptions(options.reasoning!),
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
          : _decodeReasoningOptions(
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

  HttpChatTransportJsonMap _encodeReasoningOptions(
    GenerateTextReasoningOptions options,
  ) {
    return {
      if (options.enabled != null) 'enabled': options.enabled,
      if (options.effort != null) 'effort': options.effort!.value,
      if (options.budgetTokens != null) 'budgetTokens': options.budgetTokens,
    };
  }

  GenerateTextReasoningOptions _decodeReasoningOptions(
    Object? value, {
    required String path,
  }) {
    final map = HttpChatTransportJson.asMap(value, path: path);
    return GenerateTextReasoningOptions(
      enabled: HttpChatTransportJson.asNullableBool(
        map['enabled'],
        path: '$path.enabled',
      ),
      effort: _decodeReasoningEffort(map['effort'], path: '$path.effort'),
      budgetTokens: HttpChatTransportJson.asNullableInt(
        map['budgetTokens'],
        path: '$path.budgetTokens',
      ),
    );
  }

  ReasoningEffort? _decodeReasoningEffort(
    Object? value, {
    required String path,
  }) {
    final stringValue = HttpChatTransportJson.asNullableString(
      value,
      path: path,
    );
    if (stringValue == null) {
      return null;
    }

    for (final effort in ReasoningEffort.values) {
      if (effort.value == stringValue) {
        return effort;
      }
    }

    throw FormatException(
      'Unsupported reasoning effort "$stringValue" at $path.',
    );
  }
}
