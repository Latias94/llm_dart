import '../common/json_codec_common.dart';
import '../common/provider_options.dart';
import '../content/content_part.dart';
import '../tool/tool_output.dart';
import 'serialization_tool_content_json_codec.dart';
import 'serialization_tool_output_json_codec.dart';

final class SerializationToolSupport {
  const SerializationToolSupport._();

  static const _contentCodec = SerializationToolContentJsonCodec();
  static const _outputCodec = SerializationToolOutputJsonCodec();

  static JsonMap encodeToolOutput(
    ToolOutput output, {
    JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) =>
      _outputCodec.encodeToolOutput(
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
      _outputCodec.decodeToolOutput(
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
      _outputCodec.encodeToolOutputContentPart(
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
      _outputCodec.decodeToolOutputContentPart(
        value,
        path: path,
        decodeProviderOptions: decodeProviderOptions,
      );

  static JsonMap encodeToolCallContent(ToolCallContent toolCall) =>
      _contentCodec.encodeToolCallContent(toolCall);

  static ToolCallContent decodeToolCallContent(
    Object? value, {
    required String path,
  }) =>
      _contentCodec.decodeToolCallContent(value, path: path);

  static JsonMap encodeToolResultContent(ToolResultContent toolResult) =>
      _contentCodec.encodeToolResultContent(toolResult);

  static ToolResultContent decodeToolResultContent(
    Object? value, {
    required String path,
  }) =>
      _contentCodec.decodeToolResultContent(value, path: path);
}
