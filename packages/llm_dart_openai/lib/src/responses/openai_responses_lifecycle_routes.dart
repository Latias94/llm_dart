final class OpenAIResponsesLifecycleRoutes {
  final String baseUrl;

  const OpenAIResponsesLifecycleRoutes({
    required this.baseUrl,
  });

  Uri get responsesUri => Uri.parse('$baseUrl/responses');

  Uri responseUri(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) {
    return openAIResponsesUriWithQuery(
      '$baseUrl/responses/${Uri.encodeComponent(requireResponseId(
        responseId,
        parameterName: 'responseId',
      ))}',
      {
        if (include != null && include.isNotEmpty) 'include': include.join(','),
        if (startingAfter != null) 'starting_after': '$startingAfter',
        if (stream) 'stream': '$stream',
      },
    );
  }

  Uri cancelResponseUri(String responseId) {
    return Uri.parse(
      '$baseUrl/responses/${Uri.encodeComponent(requireResponseId(
        responseId,
        parameterName: 'responseId',
      ))}/cancel',
    );
  }

  Uri inputItemsUri(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) {
    if (limit < 1) {
      throw ArgumentError.value(
        limit,
        'limit',
        'OpenAI response input item list limit must be >= 1.',
      );
    }

    return openAIResponsesUriWithQuery(
      '$baseUrl/responses/${Uri.encodeComponent(requireResponseId(
        responseId,
        parameterName: 'responseId',
      ))}/input_items',
      {
        'limit': '$limit',
        if (order.isNotEmpty) 'order': order,
        if (after != null && after.isNotEmpty) 'after': after,
        if (before != null && before.isNotEmpty) 'before': before,
        if (include != null && include.isNotEmpty) 'include': include.join(','),
      },
    );
  }

  String requireResponseId(
    String value, {
    required String parameterName,
  }) {
    return requireOpenAIResponseId(value, parameterName: parameterName);
  }
}

String requireOpenAIResponseId(
  String value, {
  required String parameterName,
}) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      parameterName,
      'Expected a non-empty OpenAI response ID.',
    );
  }
  return normalized;
}

Uri openAIResponsesUriWithQuery(
  String uri,
  Map<String, String> queryParameters,
) {
  final parsed = Uri.parse(uri);
  if (queryParameters.isEmpty) {
    return parsed;
  }
  return parsed.replace(queryParameters: queryParameters);
}
