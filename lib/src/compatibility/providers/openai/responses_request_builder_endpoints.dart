part of 'responses_request_builder.dart';

final class _OpenAIResponsesEndpointSupport {
  const _OpenAIResponsesEndpointSupport();

  String get responsesEndpoint => 'responses';

  String buildGetResponseEndpoint(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) {
    return _appendQueryParameters(
      '$responsesEndpoint/$responseId',
      {
        if (include != null && include.isNotEmpty) 'include': include.join(','),
        if (startingAfter != null) 'starting_after': startingAfter.toString(),
        if (stream) 'stream': stream.toString(),
      },
    );
  }

  String buildDeleteResponseEndpoint(String responseId) {
    return '$responsesEndpoint/$responseId';
  }

  String buildCancelResponseEndpoint(String responseId) {
    return '$responsesEndpoint/$responseId/cancel';
  }

  String buildListInputItemsEndpoint(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) {
    return _appendQueryParameters(
      '$responsesEndpoint/$responseId/input_items',
      {
        'limit': limit.toString(),
        'order': order,
        if (after != null) 'after': after,
        if (before != null) 'before': before,
        if (include != null && include.isNotEmpty) 'include': include.join(','),
      },
    );
  }

  String _appendQueryParameters(
    String endpoint,
    Map<String, String> queryParameters,
  ) {
    if (queryParameters.isEmpty) {
      return endpoint;
    }

    final queryString = queryParameters.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');

    return '$endpoint?$queryString';
  }
}
