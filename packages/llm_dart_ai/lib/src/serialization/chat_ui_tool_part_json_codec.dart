import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../ui/chat_ui_message.dart';

final class ChatUiToolPartJsonCodec {
  const ChatUiToolPartJsonCodec();

  JsonMap encode(ToolUiPart part) {
    return {
      'type': 'tool',
      'toolCallId': part.toolCallId,
      'toolName': part.toolName,
      'state': part.state.name,
      'input': ensureJsonValue(part.input, path: r'$.tool.input'),
      if (part.inputText != null) 'inputText': part.inputText,
      if (_toolOutputForJson(
        state: part.state,
        output: part.output,
        toolOutput: part.toolOutput,
        errorText: part.errorText,
      )
          case final encodedToolOutput?)
        'toolOutput': SerializationJsonSupport.encodeToolOutput(
          encodedToolOutput,
        ),
      if (part.errorText != null) 'errorText': part.errorText,
      'providerExecuted': part.providerExecuted,
      'isDynamic': part.isDynamic,
      'preliminary': part.preliminary,
      if (part.title != null) 'title': part.title,
      if (part.approval != null)
        'approval': _encodeApprovalState(part.approval!),
      if (part.callProviderMetadata != null)
        'callProviderMetadata': SerializationJsonSupport.encodeProviderMetadata(
          part.callProviderMetadata!,
        ),
      if (part.resultProviderMetadata != null)
        'resultProviderMetadata':
            SerializationJsonSupport.encodeProviderMetadata(
          part.resultProviderMetadata!,
        ),
    };
  }

  ToolUiPart decode(
    JsonMap map, {
    required String path,
  }) {
    final state = ToolUiPartState.values.byName(
      asJsonString(map['state'], path: '$path.state'),
    );
    final errorText =
        asNullableJsonString(map['errorText'], path: '$path.errorText');

    return ToolUiPart(
      toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
      toolName: asJsonString(map['toolName'], path: '$path.toolName'),
      state: state,
      input: map['input'],
      inputText:
          asNullableJsonString(map['inputText'], path: '$path.inputText'),
      output: map['output'],
      toolOutput: _decodeToolOutputForUiPart(
        map,
        state: state,
        errorText: errorText,
        path: path,
      ),
      errorText: errorText,
      providerExecuted: asNullableJsonBool(
            map['providerExecuted'],
            path: '$path.providerExecuted',
          ) ??
          false,
      isDynamic: SerializationJsonSupport.decodeDynamicFlag(
        map,
        path: path,
      ),
      preliminary:
          asNullableJsonBool(map['preliminary'], path: '$path.preliminary') ??
              false,
      title: asNullableJsonString(map['title'], path: '$path.title'),
      approval: _decodeApprovalState(map['approval'], path: '$path.approval'),
      callProviderMetadata: SerializationJsonSupport.decodeProviderMetadata(
        map['callProviderMetadata'],
        path: '$path.callProviderMetadata',
      ),
      resultProviderMetadata: SerializationJsonSupport.decodeProviderMetadata(
        map['resultProviderMetadata'],
        path: '$path.resultProviderMetadata',
      ),
    );
  }

  JsonMap _encodeApprovalState(ToolApprovalUiState state) {
    return {
      'approvalId': state.approvalId,
      if (state.approved != null) 'approved': state.approved,
      if (state.reason != null) 'reason': state.reason,
    };
  }

  ToolApprovalUiState? _decodeApprovalState(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    return ToolApprovalUiState(
      approvalId: asJsonString(map['approvalId'], path: '$path.approvalId'),
      approved: asNullableJsonBool(map['approved'], path: '$path.approved'),
      reason: asNullableJsonString(map['reason'], path: '$path.reason'),
    );
  }
}

ToolOutput? _toolOutputForJson({
  required ToolUiPartState state,
  required Object? output,
  required ToolOutput? toolOutput,
  required String? errorText,
}) {
  if (toolOutput != null) {
    return toolOutput;
  }

  return switch (state) {
    ToolUiPartState.outputAvailable => ToolOutput.fromValue(output),
    ToolUiPartState.outputError => output != null
        ? ToolOutput.fromValue(output, isError: true)
        : errorText == null
            ? null
            : ToolOutput.fromValue(errorText, isError: true),
    ToolUiPartState.outputDenied => output is String
        ? ExecutionDeniedToolOutput(output)
        : const ExecutionDeniedToolOutput(),
    _ => output == null ? null : ToolOutput.fromValue(output),
  };
}

ToolOutput? _decodeToolOutputForUiPart(
  JsonMap map, {
  required ToolUiPartState state,
  required String? errorText,
  required String path,
}) {
  if (map.containsKey('toolOutput')) {
    return SerializationJsonSupport.decodeToolOutput(
      map['toolOutput'],
      path: '$path.toolOutput',
    );
  }

  if (!map.containsKey('output')) {
    return state == ToolUiPartState.outputDenied
        ? const ExecutionDeniedToolOutput()
        : null;
  }

  final output = map['output'];
  return switch (state) {
    ToolUiPartState.outputAvailable => ToolOutput.fromValue(output),
    ToolUiPartState.outputError => output != null
        ? ToolOutput.fromValue(output, isError: true)
        : errorText == null
            ? null
            : ToolOutput.fromValue(errorText, isError: true),
    ToolUiPartState.outputDenied => output is String
        ? ExecutionDeniedToolOutput(output)
        : const ExecutionDeniedToolOutput(),
    _ => output == null ? null : ToolOutput.fromValue(output),
  };
}
