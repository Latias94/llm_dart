import '../common/json_codec_common.dart';
import '../content/content_part.dart';
import 'serialization_metadata_json_codec.dart';
import 'serialization_tool_output_json_codec.dart';

final class SerializationToolContentJsonCodec {
  const SerializationToolContentJsonCodec();

  JsonMap encodeToolCallContent(ToolCallContent toolCall) {
    return {
      'toolCallId': toolCall.toolCallId,
      'toolName': toolCall.toolName,
      'input': ensureJsonValue(
        toolCall.input,
        path: r'$.toolCall.input',
      ),
      'providerExecuted': toolCall.providerExecuted,
      'isDynamic': toolCall.isDynamic,
      if (toolCall.title != null) 'title': toolCall.title,
    };
  }

  ToolCallContent decodeToolCallContent(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    return ToolCallContent(
      toolCallId: asJsonString(
        map['toolCallId'],
        path: '$path.toolCallId',
      ),
      toolName: asJsonString(
        map['toolName'],
        path: '$path.toolName',
      ),
      input: map['input'],
      providerExecuted: asNullableJsonBool(
            map['providerExecuted'],
            path: '$path.providerExecuted',
          ) ??
          false,
      isDynamic: const SerializationMetadataJsonCodec().decodeDynamicFlag(
        map,
        path: path,
      ),
      title: asNullableJsonString(
        map['title'],
        path: '$path.title',
      ),
    );
  }

  JsonMap encodeToolResultContent(ToolResultContent toolResult) {
    return {
      'toolCallId': toolResult.toolCallId,
      'toolName': toolResult.toolName,
      'toolOutput': const SerializationToolOutputJsonCodec().encodeToolOutput(
        toolResult.toolOutput,
      ),
      'preliminary': toolResult.preliminary,
      'isDynamic': toolResult.isDynamic,
    };
  }

  ToolResultContent decodeToolResultContent(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    return ToolResultContent(
      toolCallId: asJsonString(
        map['toolCallId'],
        path: '$path.toolCallId',
      ),
      toolName: asJsonString(
        map['toolName'],
        path: '$path.toolName',
      ),
      toolOutput: map.containsKey('toolOutput')
          ? const SerializationToolOutputJsonCodec().decodeToolOutput(
              map['toolOutput'],
              path: '$path.toolOutput',
            )
          : null,
      output: map.containsKey('toolOutput') ? null : map['output'],
      isError: map.containsKey('toolOutput')
          ? false
          : asNullableJsonBool(
                map['isError'],
                path: '$path.isError',
              ) ??
              false,
      preliminary: asNullableJsonBool(
            map['preliminary'],
            path: '$path.preliminary',
          ) ??
          false,
      isDynamic: const SerializationMetadataJsonCodec().decodeDynamicFlag(
        map,
        path: path,
      ),
    );
  }
}
