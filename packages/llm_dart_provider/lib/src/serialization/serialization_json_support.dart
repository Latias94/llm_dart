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
import 'serialization_metadata_json_codec.dart';
import 'serialization_source_reference_json_codec.dart';
import 'serialization_tool_output_json_codec.dart';

final class SerializationJsonSupport {
  const SerializationJsonSupport._();

  static JsonMap encodeProviderMetadata(ProviderMetadata metadata) =>
      const SerializationMetadataJsonCodec().encodeProviderMetadata(metadata);

  static ProviderMetadata? decodeProviderMetadata(
    Object? value, {
    required String path,
  }) =>
      const SerializationMetadataJsonCodec().decodeProviderMetadata(
        value,
        path: path,
      );

  static bool decodeDynamicFlag(
    JsonMap map, {
    required String path,
  }) =>
      const SerializationMetadataJsonCodec().decodeDynamicFlag(
        map,
        path: path,
      );

  static JsonMap encodeUsageStats(UsageStats stats) =>
      const SerializationMetadataJsonCodec().encodeUsageStats(stats);

  static UsageStats? decodeUsageStats(
    Object? value, {
    required String path,
  }) =>
      const SerializationMetadataJsonCodec().decodeUsageStats(
        value,
        path: path,
      );

  static JsonMap encodeModelResponseMetadata(
    ModelResponseMetadata metadata,
  ) =>
      const SerializationMetadataJsonCodec()
          .encodeModelResponseMetadata(metadata);

  static ModelResponseMetadata? decodeModelResponseMetadata(
    Object? value, {
    required String path,
  }) =>
      const SerializationMetadataJsonCodec().decodeModelResponseMetadata(
        value,
        path: path,
      );

  static ModelResponseMetadata? decodeModelResponseMetadataFields(
    JsonMap map, {
    required String path,
  }) =>
      const SerializationMetadataJsonCodec().decodeModelResponseMetadataFields(
        map,
        path: path,
      );

  static Map<String, String>? decodeStringMap(
    Object? value, {
    required String path,
  }) =>
      const SerializationMetadataJsonCodec().decodeStringMap(
        value,
        path: path,
      );

  static JsonMap encodeModelWarning(ModelWarning warning) =>
      const SerializationMetadataJsonCodec().encodeModelWarning(warning);

  static ModelWarning decodeModelWarning(
    Object? value, {
    required String path,
  }) =>
      const SerializationMetadataJsonCodec().decodeModelWarning(
        value,
        path: path,
      );

  static JsonMap encodeModelError(ModelError error) =>
      const SerializationMetadataJsonCodec().encodeModelError(error);

  static ModelError decodeModelError(
    Object? value, {
    required String path,
  }) =>
      const SerializationMetadataJsonCodec().decodeModelError(
        value,
        path: path,
      );

  static JsonMap encodeSourceReference(SourceReference source) =>
      const SerializationSourceReferenceJsonCodec()
          .encodeSourceReference(source);

  static SourceReference decodeSourceReference(
    Object? value, {
    required String path,
  }) =>
      const SerializationSourceReferenceJsonCodec().decodeSourceReference(
        value,
        path: path,
      );

  static String encodeSourceReferenceKind(SourceReferenceKind kind) =>
      const SerializationSourceReferenceJsonCodec()
          .encodeSourceReferenceKind(kind);

  static SourceReferenceKind decodeSourceReferenceKind(
    Object? value, {
    required String path,
    required Object? uri,
  }) =>
      const SerializationSourceReferenceJsonCodec()
          .decodeSourceReferenceKind(value, path: path, uri: uri);

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
