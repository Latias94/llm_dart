import '../common/model_error.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/provider_options.dart';
import '../common/usage_stats.dart';
import '../content/content_part.dart';
import '../content/file_data.dart';
import '../model/model_response_metadata.dart';
import '../tool/tool_output.dart';
import '../common/json_codec_common.dart';
import 'serialization_file_json_codec.dart';
import 'serialization_tool_output_json_codec.dart';

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
      if (warning.feature != null) 'feature': warning.feature,
      if (warning.setting != null) 'setting': warning.setting,
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
      message: asNullableJsonString(map['message'], path: '$path.message') ??
          asNullableJsonString(map['details'], path: '$path.details') ??
          '',
      feature: asNullableJsonString(map['feature'], path: '$path.feature'),
      setting: asNullableJsonString(map['setting'], path: '$path.setting'),
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
  }) =>
      const SerializationFileJsonCodec().decodeGeneratedFile(
        value,
        path: path,
      );

  static JsonMap encodeFileData(FileData data) {
    return const SerializationFileJsonCodec().encodeFileData(data);
  }

  static FileData? decodeFileData(
    Object? value, {
    required String path,
  }) =>
      const SerializationFileJsonCodec().decodeFileData(value, path: path);

  static JsonMap encodeToolOutput(
    ToolOutput output, {
    JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) =>
      const SerializationToolOutputJsonCodec().encodeToolOutput(
        output,
        encodeProviderOptions: encodeProviderOptions,
      );

  static ToolOutput decodeToolOutput(
    Object? value, {
    required String path,
    ProviderPromptPartOptions? Function(
      Object? value, {
      required String path,
    })? decodeProviderOptions,
  }) =>
      const SerializationToolOutputJsonCodec().decodeToolOutput(
        value,
        path: path,
        decodeProviderOptions: decodeProviderOptions,
      );

  static JsonMap encodeToolOutputContentPart(
    ToolOutputContentPart part, {
    String path = r'$.toolOutput.parts[]',
    JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) =>
      const SerializationToolOutputJsonCodec().encodeToolOutputContentPart(
        part,
        path: path,
        encodeProviderOptions: encodeProviderOptions,
      );

  static ToolOutputContentPart decodeToolOutputContentPart(
    Object? value, {
    required String path,
    ProviderPromptPartOptions? Function(
      Object? value, {
      required String path,
    })? decodeProviderOptions,
  }) =>
      const SerializationToolOutputJsonCodec().decodeToolOutputContentPart(
        value,
        path: path,
        decodeProviderOptions: decodeProviderOptions,
      );

  static JsonMap encodeBytes(List<int> bytes) {
    return const SerializationFileJsonCodec().encodeBytes(bytes);
  }

  static List<int>? decodeBytes(
    Object? value, {
    required String path,
  }) =>
      const SerializationFileJsonCodec().decodeBytes(value, path: path);

  static Uri? decodeUri(
    Object? value, {
    required String path,
  }) =>
      const SerializationFileJsonCodec().decodeUri(value, path: path);
}
