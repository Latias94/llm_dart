import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';

final class HttpChatTransportReasoningOptionsJsonCodec {
  const HttpChatTransportReasoningOptionsJsonCodec();

  HttpChatTransportJsonMap encode(GenerateTextReasoningOptions options) {
    return {
      if (options.enabled != null) 'enabled': options.enabled,
      if (options.effort != null) 'effort': options.effort!.value,
      if (options.budgetTokens != null) 'budgetTokens': options.budgetTokens,
    };
  }

  GenerateTextReasoningOptions decode(
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
