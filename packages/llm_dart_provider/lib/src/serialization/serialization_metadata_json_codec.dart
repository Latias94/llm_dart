import '../common/json_codec_common.dart';
import '../common/model_error.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../model/model_response_metadata.dart';

final class SerializationMetadataJsonCodec {
  const SerializationMetadataJsonCodec();

  JsonMap encodeProviderMetadata(ProviderMetadata metadata) {
    return metadata.toJsonMap();
  }

  ProviderMetadata? decodeProviderMetadata(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    return ProviderMetadata(asJsonMap(value, path: path));
  }

  bool decodeDynamicFlag(
    JsonMap map, {
    required String path,
  }) {
    return asNullableJsonBool(map['isDynamic'], path: '$path.isDynamic') ??
        asNullableJsonBool(map['dynamic'], path: '$path.dynamic') ??
        false;
  }

  JsonMap encodeUsageStats(UsageStats stats) {
    return {
      'inputTokens': stats.inputTokens,
      'outputTokens': stats.outputTokens,
      'totalTokens': stats.totalTokens,
      'reasoningTokens': stats.reasoningTokens,
    };
  }

  UsageStats? decodeUsageStats(
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

  JsonMap encodeModelResponseMetadata(
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

  ModelResponseMetadata? decodeModelResponseMetadata(
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

  ModelResponseMetadata? decodeModelResponseMetadataFields(
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

  Map<String, String>? decodeStringMap(
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

  JsonMap encodeModelWarning(ModelWarning warning) {
    return {
      'type': warning.type.name,
      'message': warning.message,
      if (warning.feature != null) 'feature': warning.feature,
      if (warning.setting != null) 'setting': warning.setting,
      if (warning.field != null) 'field': warning.field,
    };
  }

  ModelWarning decodeModelWarning(
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

  JsonMap encodeModelError(ModelError error) {
    return error.toJsonMap();
  }

  ModelError decodeModelError(
    Object? value, {
    required String path,
  }) {
    return ModelError.fromJson(value, path: path);
  }
}
