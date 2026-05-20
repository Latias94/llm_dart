import 'anthropic_api.dart';

final class AnthropicFilesRouteSupport {
  final String baseUrl;

  const AnthropicFilesRouteSupport({
    required this.baseUrl,
  });

  Uri get filesUri => resolveAnthropicUri(baseUrl, 'files');

  Uri fileListUri({
    String? beforeId,
    String? afterId,
    int? limit,
  }) {
    return _uriWithQuery(
      filesUri,
      _buildListQueryParameters(
        beforeId: beforeId,
        afterId: afterId,
        limit: limit,
      ),
    );
  }

  Uri fileUri(String fileId) {
    return resolveAnthropicUri(
      baseUrl,
      'files/${requireFileId(fileId, parameterName: 'fileId')}',
    );
  }

  Uri fileContentUri(String fileId) {
    return resolveAnthropicUri(
      baseUrl,
      'files/${requireFileId(fileId, parameterName: 'fileId')}/content',
    );
  }

  String requireFileId(
    String fileId, {
    required String parameterName,
  }) {
    final normalized = fileId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        fileId,
        parameterName,
        'Expected a non-empty file ID.',
      );
    }

    return normalized;
  }
}

Map<String, String> _buildListQueryParameters({
  String? beforeId,
  String? afterId,
  int? limit,
}) {
  if (limit != null && limit < 1) {
    throw ArgumentError.value(
      limit,
      'limit',
      'Anthropic file list limit must be >= 1.',
    );
  }

  return {
    if (beforeId != null && beforeId.isNotEmpty) 'before_id': beforeId,
    if (afterId != null && afterId.isNotEmpty) 'after_id': afterId,
    if (limit != null) 'limit': '$limit',
  };
}

Uri _uriWithQuery(Uri uri, Map<String, String> queryParameters) {
  if (queryParameters.isEmpty) {
    return uri;
  }
  return uri.replace(queryParameters: queryParameters);
}
