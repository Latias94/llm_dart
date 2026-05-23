import '../common/json_codec_common.dart';
import '../common/model_error.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../model/model_response_metadata.dart';
import 'serialization_metadata_json_codec.dart';

final class SerializationMetadataSupport {
  const SerializationMetadataSupport._();

  static const _codec = SerializationMetadataJsonCodec();

  static JsonMap encodeProviderMetadata(ProviderMetadata metadata) =>
      _codec.encodeProviderMetadata(metadata);

  static ProviderMetadata? decodeProviderMetadata(
    Object? value, {
    required String path,
  }) =>
      _codec.decodeProviderMetadata(value, path: path);

  static bool decodeDynamicFlag(
    JsonMap map, {
    required String path,
  }) =>
      _codec.decodeDynamicFlag(map, path: path);

  static JsonMap encodeUsageStats(UsageStats stats) =>
      _codec.encodeUsageStats(stats);

  static UsageStats? decodeUsageStats(
    Object? value, {
    required String path,
  }) =>
      _codec.decodeUsageStats(value, path: path);

  static JsonMap encodeModelResponseMetadata(
    ModelResponseMetadata metadata,
  ) =>
      _codec.encodeModelResponseMetadata(metadata);

  static ModelResponseMetadata? decodeModelResponseMetadata(
    Object? value, {
    required String path,
  }) =>
      _codec.decodeModelResponseMetadata(value, path: path);

  static ModelResponseMetadata? decodeModelResponseMetadataFields(
    JsonMap map, {
    required String path,
  }) =>
      _codec.decodeModelResponseMetadataFields(map, path: path);

  static Map<String, String>? decodeStringMap(
    Object? value, {
    required String path,
  }) =>
      _codec.decodeStringMap(value, path: path);

  static JsonMap encodeModelWarning(ModelWarning warning) =>
      _codec.encodeModelWarning(warning);

  static ModelWarning decodeModelWarning(
    Object? value, {
    required String path,
  }) =>
      _codec.decodeModelWarning(value, path: path);

  static JsonMap encodeModelError(ModelError error) =>
      _codec.encodeModelError(error);

  static ModelError decodeModelError(
    Object? value, {
    required String path,
  }) =>
      _codec.decodeModelError(value, path: path);
}
