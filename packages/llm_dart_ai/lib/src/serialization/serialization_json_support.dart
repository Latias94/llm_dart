import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

final class SerializationJsonSupport {
  const SerializationJsonSupport._();

  static JsonMap encodeProviderMetadata(ProviderMetadata metadata) {
    return metadata.toJsonMap();
  }

  static ProviderMetadata? decodeProviderMetadata(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    return ProviderMetadata(asJsonMap(value, path: path));
  }

  static bool decodeDynamicFlag(
    JsonMap map, {
    required String path,
  }) {
    return asNullableJsonBool(map['isDynamic'], path: '$path.isDynamic') ??
        asNullableJsonBool(map['dynamic'], path: '$path.dynamic') ??
        false;
  }

  static JsonMap encodeUsageStats(UsageStats stats) {
    return {
      'inputTokens': stats.inputTokens,
      'outputTokens': stats.outputTokens,
      'totalTokens': stats.totalTokens,
      'reasoningTokens': stats.reasoningTokens,
    };
  }

  static UsageStats? decodeUsageStats(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    return UsageStats(
      inputTokens:
          asNullableJsonInt(map['inputTokens'], path: '$path.inputTokens'),
      outputTokens:
          asNullableJsonInt(map['outputTokens'], path: '$path.outputTokens'),
      totalTokens:
          asNullableJsonInt(map['totalTokens'], path: '$path.totalTokens'),
      reasoningTokens: asNullableJsonInt(
        map['reasoningTokens'],
        path: '$path.reasoningTokens',
      ),
    );
  }

  static JsonMap encodeModelWarning(ModelWarning warning) {
    return {
      'type': warning.type.name,
      'message': warning.message,
      if (warning.field != null) 'field': warning.field,
    };
  }

  static ModelWarning decodeModelWarning(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    return ModelWarning(
      type: ModelWarningType.values.byName(
        asJsonString(map['type'], path: '$path.type'),
      ),
      message: asJsonString(map['message'], path: '$path.message'),
      field: asNullableJsonString(map['field'], path: '$path.field'),
    );
  }

  static JsonMap encodeModelError(ModelError error) {
    return error.toJsonMap();
  }

  static ModelError decodeModelError(
    Object? value, {
    required String path,
  }) {
    return ModelError.fromJson(value, path: path);
  }

  static JsonMap encodeSourceReference(SourceReference source) {
    return {
      'kind': encodeSourceReferenceKind(source.kind),
      'sourceId': source.sourceId,
      if (source.uri != null) 'uri': source.uri.toString(),
      if (source.title != null) 'title': source.title,
      if (source.filename != null) 'filename': source.filename,
      if (source.mediaType != null) 'mediaType': source.mediaType,
      if (source.providerMetadata != null)
        'providerMetadata': encodeProviderMetadata(source.providerMetadata!),
    };
  }

  static SourceReference decodeSourceReference(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    return SourceReference(
      kind: decodeSourceReferenceKind(
        map['kind'],
        path: '$path.kind',
        uri: map['uri'],
      ),
      sourceId: asJsonString(map['sourceId'], path: '$path.sourceId'),
      uri: decodeUri(map['uri'], path: '$path.uri'),
      title: asNullableJsonString(map['title'], path: '$path.title'),
      filename: asNullableJsonString(map['filename'], path: '$path.filename'),
      mediaType:
          asNullableJsonString(map['mediaType'], path: '$path.mediaType'),
      providerMetadata: decodeProviderMetadata(
        map['providerMetadata'],
        path: '$path.providerMetadata',
      ),
    );
  }

  static String encodeSourceReferenceKind(SourceReferenceKind kind) {
    switch (kind) {
      case SourceReferenceKind.url:
        return 'url';
      case SourceReferenceKind.document:
        return 'document';
      case SourceReferenceKind.other:
        return 'other';
    }
  }

  static SourceReferenceKind decodeSourceReferenceKind(
    Object? value, {
    required String path,
    required Object? uri,
  }) {
    final kind = asNullableJsonString(value, path: path);
    return switch (kind) {
      'url' => SourceReferenceKind.url,
      'document' => SourceReferenceKind.document,
      'other' => SourceReferenceKind.other,
      null =>
        uri == null ? SourceReferenceKind.document : SourceReferenceKind.url,
      _ => throw FormatException('Invalid source kind at $path: $kind'),
    };
  }

  static JsonMap encodeGeneratedFile(GeneratedFile file) {
    return {
      'mediaType': file.mediaType,
      if (file.filename != null) 'filename': file.filename,
      'data': encodeFileData(file.data),
    };
  }

  static GeneratedFile decodeGeneratedFile(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    final data = decodeFileData(map['data'], path: '$path.data') ??
        fileDataFromLegacy(
          uri: decodeUri(map['uri'], path: '$path.uri'),
          bytes: map.containsKey('data')
              ? null
              : decodeBytes(map['bytes'], path: '$path.bytes'),
        );

    if (data == null) {
      throw FormatException(
        'Expected file data, uri, or bytes at $path.',
      );
    }

    return GeneratedFile(
      mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
      filename: asNullableJsonString(map['filename'], path: '$path.filename'),
      data: data,
    );
  }

  static JsonMap encodeFileData(FileData data) {
    return switch (data) {
      FileBytesData(:final bytes) => {
          'type': 'bytes',
          'bytes': encodeBytes(bytes),
        },
      FileUrlData(:final uri) => {
          'type': 'url',
          'uri': uri.toString(),
        },
      FileTextData(:final text) => {
          'type': 'text',
          'text': text,
        },
      FileProviderReferenceData(:final providerReference) => {
          'type': 'provider-reference',
          'providerReference': providerReference.toJsonMap(),
        },
    };
  }

  static FileData? decodeFileData(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');

    return switch (type) {
      'bytes' => FileBytesData(
          decodeBytes(map['bytes'], path: '$path.bytes') ??
              (throw FormatException('Expected bytes at $path.bytes.')),
        ),
      'url' => FileUrlData(
          decodeUri(map['uri'], path: '$path.uri') ??
              (throw FormatException('Expected URI at $path.uri.')),
        ),
      'text' => FileTextData(
          asJsonString(map['text'], path: '$path.text'),
        ),
      'provider-reference' => FileProviderReferenceData(
          ProviderReference.fromJson(
            map['providerReference'],
            path: '$path.providerReference',
          ),
        ),
      _ =>
        throw FormatException('Unsupported file data type "$type" at $path.'),
    };
  }

  static JsonMap encodeToolOutput(ToolOutput output) {
    return switch (output) {
      TextToolOutput(:final value, :final providerMetadata) => {
          'type': 'text',
          'value': value,
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
      JsonToolOutput(:final value, :final providerMetadata) => {
          'type': 'json',
          'value': ensureJsonValue(value, path: r'$.toolOutput.value'),
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
      ErrorTextToolOutput(:final value, :final providerMetadata) => {
          'type': 'error-text',
          'value': value,
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
      ErrorJsonToolOutput(:final value, :final providerMetadata) => {
          'type': 'error-json',
          'value': ensureJsonValue(value, path: r'$.toolOutput.value'),
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
      ExecutionDeniedToolOutput(:final reason, :final providerMetadata) => {
          'type': 'execution-denied',
          if (reason != null) 'reason': reason,
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
      ContentToolOutput(:final parts, :final providerMetadata) => {
          'type': 'content',
          'parts': [
            for (final part in parts) encodeToolOutputContentPart(part),
          ],
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
    };
  }

  static ToolOutput decodeToolOutput(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');

    return switch (type) {
      'text' => TextToolOutput(
          asJsonString(map['value'], path: '$path.value'),
          providerMetadata: decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'json' => JsonToolOutput(
          map['value'],
          providerMetadata: decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'error-text' => ErrorTextToolOutput(
          asJsonString(map['value'], path: '$path.value'),
          providerMetadata: decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'error-json' => ErrorJsonToolOutput(
          map['value'],
          providerMetadata: decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'execution-denied' => ExecutionDeniedToolOutput.withMetadata(
          reason: asNullableJsonString(map['reason'], path: '$path.reason'),
          providerMetadata: decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'content' => ContentToolOutput(
          parts: [
            for (final entry in asJsonList(map['parts'], path: '$path.parts')
                .asMap()
                .entries)
              decodeToolOutputContentPart(
                entry.value,
                path: '$path.parts[${entry.key}]',
              ),
          ],
          providerMetadata: decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      _ =>
        throw FormatException('Unsupported tool output type "$type" at $path.'),
    };
  }

  static JsonMap encodeToolOutputContentPart(ToolOutputContentPart part) {
    return switch (part) {
      TextToolOutputContentPart(:final text, :final providerMetadata) => {
          'type': 'text',
          'text': text,
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
      JsonToolOutputContentPart(:final value, :final providerMetadata) => {
          'type': 'json',
          'value': ensureJsonValue(
            value,
            path: r'$.toolOutput.parts[].value',
          ),
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
      FileToolOutputContentPart(
        :final mediaType,
        :final filename,
        :final data,
        :final providerMetadata,
      ) =>
        {
          'type': 'file',
          'mediaType': mediaType,
          if (filename != null) 'filename': filename,
          'data': encodeFileData(data),
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
      CustomToolOutputContentPart(
        :final kind,
        :final data,
        :final providerMetadata,
      ) =>
        {
          'type': 'custom',
          'kind': kind,
          'data': ensureJsonValue(
            data,
            path: r'$.toolOutput.parts[].data',
          ),
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
    };
  }

  static ToolOutputContentPart decodeToolOutputContentPart(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');

    return switch (type) {
      'text' => TextToolOutputContentPart(
          asJsonString(map['text'], path: '$path.text'),
          providerMetadata: decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'json' => JsonToolOutputContentPart(
          map['value'],
          providerMetadata: decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'file' => FileToolOutputContentPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          filename:
              asNullableJsonString(map['filename'], path: '$path.filename'),
          data: _decodeRequiredToolOutputFileData(map, path: path),
          providerMetadata: decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'custom' => CustomToolOutputContentPart(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata: decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      _ => throw FormatException(
          'Unsupported tool output content part type "$type" at $path.',
        ),
    };
  }

  static FileData _decodeRequiredToolOutputFileData(
    JsonMap map, {
    required String path,
  }) {
    final data = decodeFileData(map['data'], path: '$path.data') ??
        fileDataFromLegacy(
          uri: decodeUri(map['uri'], path: '$path.uri'),
          bytes: map.containsKey('data')
              ? null
              : decodeBytes(map['bytes'], path: '$path.bytes'),
        );

    if (data == null) {
      throw FormatException('Expected file data, uri, or bytes at $path.');
    }

    return data;
  }

  static JsonMap encodeBytes(List<int> bytes) {
    return {
      'encoding': 'base64',
      'data': base64Encode(bytes),
    };
  }

  static List<int>? decodeBytes(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    final encoding = asJsonString(map['encoding'], path: '$path.encoding');
    if (encoding != 'base64') {
      throw FormatException('Unsupported byte encoding "$encoding" at $path.');
    }

    return base64Decode(asJsonString(map['data'], path: '$path.data'));
  }

  static Uri? decodeUri(
    Object? value, {
    required String path,
  }) {
    final stringValue = asNullableJsonString(value, path: path);
    return stringValue == null ? null : Uri.parse(stringValue);
  }
}
