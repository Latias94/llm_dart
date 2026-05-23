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
import 'serialization_media_support.dart';
import 'serialization_metadata_support.dart';
import 'serialization_tool_support.dart';

final class SerializationJsonSupport {
  const SerializationJsonSupport._();

  static JsonMap encodeProviderMetadata(ProviderMetadata metadata) =>
      SerializationMetadataSupport.encodeProviderMetadata(metadata);

  static ProviderMetadata? decodeProviderMetadata(
    Object? value, {
    required String path,
  }) =>
      SerializationMetadataSupport.decodeProviderMetadata(value, path: path);

  static bool decodeDynamicFlag(
    JsonMap map, {
    required String path,
  }) =>
      SerializationMetadataSupport.decodeDynamicFlag(map, path: path);

  static JsonMap encodeUsageStats(UsageStats stats) =>
      SerializationMetadataSupport.encodeUsageStats(stats);

  static UsageStats? decodeUsageStats(
    Object? value, {
    required String path,
  }) =>
      SerializationMetadataSupport.decodeUsageStats(value, path: path);

  static JsonMap encodeModelResponseMetadata(
    ModelResponseMetadata metadata,
  ) =>
      SerializationMetadataSupport.encodeModelResponseMetadata(metadata);

  static ModelResponseMetadata? decodeModelResponseMetadata(
    Object? value, {
    required String path,
  }) =>
      SerializationMetadataSupport.decodeModelResponseMetadata(
        value,
        path: path,
      );

  static ModelResponseMetadata? decodeModelResponseMetadataFields(
    JsonMap map, {
    required String path,
  }) =>
      SerializationMetadataSupport.decodeModelResponseMetadataFields(
        map,
        path: path,
      );

  static Map<String, String>? decodeStringMap(
    Object? value, {
    required String path,
  }) =>
      SerializationMetadataSupport.decodeStringMap(value, path: path);

  static JsonMap encodeModelWarning(ModelWarning warning) =>
      SerializationMetadataSupport.encodeModelWarning(warning);

  static ModelWarning decodeModelWarning(
    Object? value, {
    required String path,
  }) =>
      SerializationMetadataSupport.decodeModelWarning(value, path: path);

  static JsonMap encodeModelError(ModelError error) =>
      SerializationMetadataSupport.encodeModelError(error);

  static ModelError decodeModelError(
    Object? value, {
    required String path,
  }) =>
      SerializationMetadataSupport.decodeModelError(value, path: path);

  static JsonMap encodeSourceReference(SourceReference source) =>
      SerializationMediaSupport.encodeSourceReference(source);

  static SourceReference decodeSourceReference(
    Object? value, {
    required String path,
  }) =>
      SerializationMediaSupport.decodeSourceReference(value, path: path);

  static String encodeSourceReferenceKind(SourceReferenceKind kind) =>
      SerializationMediaSupport.encodeSourceReferenceKind(kind);

  static SourceReferenceKind decodeSourceReferenceKind(
    Object? value, {
    required String path,
    required Object? uri,
  }) =>
      SerializationMediaSupport.decodeSourceReferenceKind(
        value,
        path: path,
        uri: uri,
      );

  static JsonMap encodeGeneratedFile(GeneratedFile file) =>
      SerializationMediaSupport.encodeGeneratedFile(file);

  static GeneratedFile decodeGeneratedFile(
    Object? value, {
    required String path,
  }) =>
      SerializationMediaSupport.decodeGeneratedFile(value, path: path);

  static JsonMap encodeFileData(FileData data) {
    return SerializationMediaSupport.encodeFileData(data);
  }

  static FileData? decodeFileData(
    Object? value, {
    required String path,
  }) =>
      SerializationMediaSupport.decodeFileData(value, path: path);

  static JsonMap encodeToolOutput(
    ToolOutput output, {
    JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) =>
      SerializationToolSupport.encodeToolOutput(
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
      SerializationToolSupport.decodeToolOutput(
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
      SerializationToolSupport.encodeToolOutputContentPart(
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
      SerializationToolSupport.decodeToolOutputContentPart(
        value,
        path: path,
        decodeProviderOptions: decodeProviderOptions,
      );

  static JsonMap encodeToolCallContent(ToolCallContent toolCall) =>
      SerializationToolSupport.encodeToolCallContent(toolCall);

  static ToolCallContent decodeToolCallContent(
    Object? value, {
    required String path,
  }) =>
      SerializationToolSupport.decodeToolCallContent(value, path: path);

  static JsonMap encodeToolResultContent(ToolResultContent toolResult) =>
      SerializationToolSupport.encodeToolResultContent(toolResult);

  static ToolResultContent decodeToolResultContent(
    Object? value, {
    required String path,
  }) =>
      SerializationToolSupport.decodeToolResultContent(value, path: path);

  static JsonMap encodeBytes(List<int> bytes) {
    return SerializationMediaSupport.encodeBytes(bytes);
  }

  static List<int>? decodeBytes(
    Object? value, {
    required String path,
  }) =>
      SerializationMediaSupport.decodeBytes(value, path: path);

  static Uri? decodeUri(
    Object? value, {
    required String path,
  }) =>
      SerializationMediaSupport.decodeUri(value, path: path);
}
