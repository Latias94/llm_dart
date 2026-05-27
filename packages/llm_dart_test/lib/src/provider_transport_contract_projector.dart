import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart';

/// Test-only projection helpers for provider transport contract fixtures.
///
/// Provider packages still own request construction. This helper only owns the
/// repeated fixture policy for turning transport requests into deterministic
/// JSON values that can be compared with golden files.
final class ProviderTransportContractProjector {
  const ProviderTransportContractProjector();

  Map<String, Object?> requestJson(
    TransportRequest request, {
    Iterable<String>? headerNames,
  }) {
    return {
      'uri': request.uri.toString(),
      'method': request.method.name,
      'responseType': request.responseType.name,
      'headers': _headers(request, headerNames),
      'body': request.body,
    };
  }

  Map<String, Object?> multipartRequestJson(
    TransportRequest request, {
    Iterable<String>? headerNames,
  }) {
    return {
      'uri': request.uri.toString(),
      'method': request.method.name,
      'responseType': request.responseType.name,
      'headers': _headers(request, headerNames),
      'multipart': multipartFields(request),
    };
  }

  Map<String, Object?> multipartFields(TransportRequest request) {
    final contentType = request.headers['content-type'];
    if (contentType == null) {
      throw const ProviderTransportContractProjectionException(
        'multipart request is missing a content-type header.',
      );
    }

    final boundary = RegExp(r'boundary=([^;]+)').firstMatch(contentType)?[1];
    if (boundary == null || boundary.isEmpty) {
      throw ProviderTransportContractProjectionException(
        'multipart request content-type does not contain a boundary: '
        '$contentType',
      );
    }

    final body = request.body;
    if (body is! List<int>) {
      throw ProviderTransportContractProjectionException(
        'multipart request body must be List<int>, got ${body.runtimeType}.',
      );
    }

    final fields = <String, Object?>{};
    for (final rawPart in utf8.decode(body).split('--$boundary')) {
      final part = rawPart.trim();
      if (part.isEmpty || part == '--') {
        continue;
      }

      final sections = part.split('\r\n\r\n');
      if (sections.length != 2) {
        continue;
      }

      final headerLines = sections.first.split('\r\n');
      final content = sections.last.replaceFirst(RegExp(r'\r\n--$'), '');
      final disposition = headerLines.firstWhere(
        (line) => line.startsWith('Content-Disposition:'),
        orElse: () => throw ProviderTransportContractProjectionException(
          'multipart part is missing Content-Disposition: $part',
        ),
      );
      final name = RegExp(r'name="([^"]+)"').firstMatch(disposition)?[1];
      if (name == null || name.isEmpty) {
        throw ProviderTransportContractProjectionException(
          'multipart part is missing a field name: $disposition',
        );
      }

      final filename =
          RegExp(r'filename="([^"]+)"').firstMatch(disposition)?[1];
      if (filename == null) {
        fields[name] = content;
        continue;
      }

      final contentTypeLine = headerLines.firstWhere(
        (line) => line.startsWith('Content-Type:'),
        orElse: () => throw ProviderTransportContractProjectionException(
          'multipart file field "$name" is missing Content-Type.',
        ),
      );
      fields[name] = {
        'filename': filename,
        'contentType': contentTypeLine.substring('Content-Type:'.length).trim(),
        'text': content,
      };
    }
    return fields;
  }

  Map<String, Object?> _headers(
    TransportRequest request,
    Iterable<String>? headerNames,
  ) {
    if (headerNames == null) {
      return Map<String, Object?>.from(request.headers);
    }
    return {
      for (final name in headerNames) name: request.headers[name],
    };
  }
}

final class ProviderTransportContractProjectionException implements Exception {
  final String message;

  const ProviderTransportContractProjectionException(this.message);

  @override
  String toString() => message;
}
