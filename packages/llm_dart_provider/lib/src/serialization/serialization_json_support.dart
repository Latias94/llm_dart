import 'dart:convert';

import '../common/model_error.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/provider_options.dart';
import '../common/provider_reference.dart';
import '../common/usage_stats.dart';
import '../content/content_part.dart';
import '../content/file_data.dart';
import '../model/model_response_metadata.dart';
import '../tool/tool_output.dart';
import '../common/json_codec_common.dart';

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

  static JsonMap encodeModelResponseMetadata(
    ModelResponseMetadata metadata,
  ) {
    return {
      if (metadata.id != null) 'responseId': metadata.id,
      if (metadata.timestamp != null)
        'timestamp': metadata.timestamp!.toIso8601String(),
      if (metadata.modelId != null) 'modelId': metadata.modelId,
      if (metadata.headers.isNotEmpty) 'headers': metadata.headers,
    };
  }

  static ModelResponseMetadata? decodeModelResponseMetadata(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    return decodeModelResponseMetadataFields(
      map,
      path: path,
    );
  }

  static ModelResponseMetadata? decodeModelResponseMetadataFields(
    JsonMap map, {
    required String path,
  }) {
    final id = asNullableJsonString(
      map['responseId'],
      path: '$path.responseId',
    );
    final timestampString = asNullableJsonString(
      map['timestamp'],
      path: '$path.timestamp',
    );
    final modelId = asNullableJsonString(
      map['modelId'],
      path: '$path.modelId',
    );
    final headers = decodeStringMap(map['headers'], path: '$path.headers');

    return modelResponseMetadataFrom(
      id: id,
      timestamp:
          timestampString == null ? null : DateTime.parse(timestampString),
      modelId: modelId,
      headers: headers,
    );
  }

  static Map<String, String>? decodeStringMap(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    return Map.unmodifiable(
      map.map(
        (key, nested) => MapEntry(
          key,
          asJsonString(nested, path: '$path.$key'),
        ),
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

  static JsonMap encodeToolOutput(
    ToolOutput output, {
    JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) {
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
            for (final entry in parts.asMap().entries)
              encodeToolOutputContentPart(
                entry.value,
                path: '\$.toolOutput.parts[${entry.key}]',
                encodeProviderOptions: encodeProviderOptions,
              ),
          ],
          if (providerMetadata != null)
            'providerMetadata': encodeProviderMetadata(providerMetadata),
        },
    };
  }

  static ToolOutput decodeToolOutput(
    Object? value, {
    required String path,
    ProviderPromptPartOptions? Function(
      Object? value, {
      required String path,
    })? decodeProviderOptions,
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
                decodeProviderOptions: decodeProviderOptions,
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

  static JsonMap encodeToolOutputContentPart(
    ToolOutputContentPart part, {
    String path = r'$.toolOutput.parts[]',
    JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) {
    final JsonMap encoded = switch (part) {
      TextToolOutputContentPart(:final text) => {
          'type': 'text',
          'text': text,
        },
      JsonToolOutputContentPart(:final value) => {
          'type': 'json',
          'value': ensureJsonValue(
            value,
            path: r'$.toolOutput.parts[].value',
          ),
        },
      FileToolOutputContentPart(
        :final mediaType,
        :final filename,
        :final data,
      ) =>
        {
          'type': 'file',
          'mediaType': mediaType,
          if (filename != null) 'filename': filename,
          'data': encodeFileData(data),
        },
      CustomToolOutputContentPart(:final kind, :final data) => {
          'type': 'custom',
          'kind': kind,
          'data': ensureJsonValue(
            data,
            path: r'$.toolOutput.parts[].data',
          ),
        },
    };

    if (part.providerOptions case final providerOptions?) {
      encoded['providerOptions'] = _encodeProviderOptions(
        providerOptions,
        path: '$path.providerOptions',
        encodeProviderOptions: encodeProviderOptions,
      );
    }

    return encoded;
  }

  static ToolOutputContentPart decodeToolOutputContentPart(
    Object? value, {
    required String path,
    ProviderPromptPartOptions? Function(
      Object? value, {
      required String path,
    })? decodeProviderOptions,
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');
    final providerOptions = _decodeProviderOptions(
      map['providerOptions'],
      path: '$path.providerOptions',
      decodeProviderOptions: decodeProviderOptions,
    );
    if (map.containsKey('providerMetadata')) {
      throw FormatException(
        'Legacy prompt replay metadata is no longer supported at $path.providerMetadata. '
        'Use ProviderReplayPromptPartOptions instead.',
      );
    }

    return switch (type) {
      'text' => TextToolOutputContentPart(
          asJsonString(map['text'], path: '$path.text'),
          providerOptions: providerOptions,
        ),
      'json' => JsonToolOutputContentPart(
          map['value'],
          providerOptions: providerOptions,
        ),
      'file' => FileToolOutputContentPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          filename:
              asNullableJsonString(map['filename'], path: '$path.filename'),
          data: _decodeRequiredToolOutputFileData(map, path: path),
          providerOptions: providerOptions,
        ),
      'custom' => CustomToolOutputContentPart(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerOptions: providerOptions,
        ),
      _ => throw FormatException(
          'Unsupported tool output content part type "$type" at $path.',
        ),
    };
  }

  static JsonMap _encodeProviderOptions(
    ProviderPromptPartOptions options, {
    required String path,
    required JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) {
    if (encodeProviderOptions == null) {
      throw UnsupportedError(
        'Cannot serialize providerOptions at $path without a '
        'provider prompt part options encoder.',
      );
    }

    return encodeProviderOptions(options, path: path);
  }

  static ProviderPromptPartOptions? _decodeProviderOptions(
    Object? value, {
    required String path,
    required ProviderPromptPartOptions? Function(
      Object? value, {
      required String path,
    })? decodeProviderOptions,
  }) {
    if (value == null) {
      return null;
    }

    if (decodeProviderOptions == null) {
      throw FormatException(
        'Cannot decode providerOptions at $path without a provider prompt '
        'part options decoder.',
      );
    }

    return decodeProviderOptions(value, path: path);
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
